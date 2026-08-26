import WorkOrder, {
  WORK_ORDER_PRIORITIES,
  WORK_ORDER_STATUSES,
} from './models/workOrder.model.js';
import User from '../../core/organization/models/user.model.js';
import {
  uploadWorkOrderAttachmentBuffer,
  uploadWorkOrderVoiceNoteBuffer,
} from './work-orders.upload.js';
import {
  displayUserName,
  mapFieldLocation,
  mapPhoto,
  mapProgressNote,
  mapTimelineEvent,
  parseFieldLocation,
  photoFieldForCategory,
  PHOTO_CATEGORIES,
  pushTimeline,
} from './work-orders.execution.js';
import PERMISSIONS from '../../../shared/constants/permissions.constants.js';
import AppError, {
  ConflictError,
  ForbiddenError,
  NotFoundError,
} from '../../../shared/errors/AppError.js';
import auditService from '../../core/audit/audit.service.js';
import {
  notifyWorkOrderAssigned,
  notifyWorkOrderStatusForManagers,
} from '../../notifications/notification.hooks.js';
import { getSocketIo } from '../../../shared/utils/socket.registry.js';

const TERMINAL_STATUSES = new Set(['COMPLETED', 'CANCELLED']);

/** Fields required by work-order list cards only. */
const WORK_ORDER_LIST_SELECT = [
  'companyId',
  'jobNumber',
  'jobTitle',
  'customerName',
  'assignedTechnicianId',
  'assignedTechnicianName',
  'assignedTechnicianIds',
  'assignedTechnicianNames',
  'priority',
  'status',
  'scheduledAt',
  'createdAt',
].join(' ');

const CANCELABLE_STATUSES = new Set([
  'PENDING',
  'ASSIGNED',
  'ACCEPTED',
  'REJECTED',
  'IN_PROGRESS',
]);

function escapeRegex(value) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function toId(value) {
  return value?.toString?.() ?? value ?? null;
}

/** Resolve assignee id list from multi- or single-assignee fields (backward compatible). */
function resolveAssigneeIds(record) {
  const multi = Array.isArray(record.assignedTechnicianIds)
    ? record.assignedTechnicianIds.map(toId).filter(Boolean)
    : [];
  if (multi.length) {
    return [...new Set(multi)];
  }
  const single = toId(record.assignedTechnicianId);
  return single ? [single] : [];
}

function isUserAssignee(user, record) {
  const userId = toId(user._id);
  return resolveAssigneeIds(record).includes(userId);
}

function parseTechnicianIdsFromBody(body) {
  if (!body || typeof body !== 'object') {
    return null;
  }

  if (body.assignedTechnicianIds !== undefined) {
    let raw = body.assignedTechnicianIds;
    if (typeof raw === 'string') {
      const trimmed = raw.trim();
      if (!trimmed || trimmed === 'null') {
        return [];
      }
      try {
        raw = JSON.parse(trimmed);
      } catch {
        raw = trimmed.split(',').map((part) => part.trim()).filter(Boolean);
      }
    }
    if (!Array.isArray(raw)) {
      return [];
    }
    return [...new Set(raw.map((id) => String(id || '').trim()).filter(Boolean))];
  }

  if (body.assignedTechnicianId !== undefined) {
    const single = body.assignedTechnicianId;
    if (single === '' || single === null || single === 'null') {
      return [];
    }
    return [String(single)];
  }

  return null;
}

function normalizeLocationUrl(value) {
  if (value === undefined) {
    return undefined;
  }
  if (value === null || value === '') {
    return null;
  }
  const trimmed = String(value).trim();
  if (!trimmed) {
    return null;
  }
  try {
    const parsed = new URL(trimmed);
    if (parsed.protocol !== 'http:' && parsed.protocol !== 'https:') {
      throw new AppError('INVALID_LOCATION_URL', 'locationUrl must be http(s)', 422);
    }
    return trimmed;
  } catch (error) {
    if (error instanceof AppError) {
      throw error;
    }
    throw new AppError('INVALID_LOCATION_URL', 'locationUrl must be a valid URL', 422);
  }
}

/** Soft cap for customer phone numbers on a single work order. */
export const MAX_CUSTOMER_PHONE_NUMBERS = 20;
const CUSTOMER_PHONE_MAX_LENGTH = 40;

/**
 * Parse optional customerPhoneNumbers from JSON body / multipart string.
 * Returns undefined when the field was not sent (leave existing value).
 * Returns [] for clear/empty. Preserves trimmed user input (no country rewrite).
 */
export function normalizeCustomerPhoneNumbers(raw) {
  if (raw === undefined) {
    return undefined;
  }
  if (raw === null || raw === '') {
    return [];
  }

  let list = raw;
  if (typeof raw === 'string') {
    const trimmed = raw.trim();
    if (!trimmed || trimmed === 'null') {
      return [];
    }
    try {
      list = JSON.parse(trimmed);
    } catch {
      list = trimmed.split(/[\n,;]+/).map((part) => part.trim());
    }
  }

  if (!Array.isArray(list)) {
    throw new AppError(
      'INVALID_CUSTOMER_PHONES',
      'customerPhoneNumbers must be an array of strings',
      422
    );
  }

  if (list.length > MAX_CUSTOMER_PHONE_NUMBERS) {
    throw new AppError(
      'TOO_MANY_CUSTOMER_PHONES',
      `customerPhoneNumbers allows at most ${MAX_CUSTOMER_PHONE_NUMBERS} numbers`,
      422
    );
  }

  const result = [];
  const seenDigits = new Set();

  for (const item of list) {
    if (item === null || item === undefined) {
      continue;
    }
    if (typeof item !== 'string' && typeof item !== 'number') {
      throw new AppError(
        'INVALID_CUSTOMER_PHONES',
        'Each customer phone number must be a string',
        422
      );
    }
    const trimmed = String(item).trim();
    if (!trimmed) {
      continue;
    }
    if (trimmed.length > CUSTOMER_PHONE_MAX_LENGTH) {
      throw new AppError(
        'INVALID_CUSTOMER_PHONES',
        `Each phone number must be at most ${CUSTOMER_PHONE_MAX_LENGTH} characters`,
        422
      );
    }
    // International-friendly: optional +, digits, spaces, dashes, parentheses, dots.
    if (!/^[+]?[\d\s().\-]+$/.test(trimmed)) {
      throw new AppError(
        'INVALID_CUSTOMER_PHONES',
        'Phone numbers may only contain digits and common phone punctuation',
        422
      );
    }
    const digits = trimmed.replace(/\D/g, '');
    if (digits.length < 7 || digits.length > 15) {
      throw new AppError(
        'INVALID_CUSTOMER_PHONES',
        'Each phone number must contain between 7 and 15 digits',
        422
      );
    }
    if (seenDigits.has(digits)) {
      continue;
    }
    seenDigits.add(digits);
    result.push(trimmed);
  }

  return result;
}

function mapVoiceNote(voiceNote) {
  if (!voiceNote?.url) {
    return null;
  }
  return {
    url: voiceNote.url,
    publicId: voiceNote.publicId || null,
    duration: voiceNote.duration ?? null,
    size: voiceNote.size ?? null,
    format: voiceNote.format || null,
    uploadedAt: voiceNote.uploadedAt?.toISOString?.() || voiceNote.uploadedAt || null,
  };
}

function parseOptionalDate(value) {
  if (value === undefined || value === null || value === '') {
    return null;
  }
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) {
    throw new AppError('INVALID_DATE', 'scheduledAt must be a valid ISO date', 422);
  }
  return date;
}

function parseCustomerAddress(raw) {
  if (raw === undefined || raw === null || raw === '') {
    return null;
  }

  let value = raw;
  if (typeof raw === 'string') {
    try {
      value = JSON.parse(raw);
    } catch {
      return {
        street: raw.trim() || null,
        city: null,
        governorate: null,
        lat: null,
        lng: null,
      };
    }
  }

  if (typeof value !== 'object') {
    return null;
  }

  return {
    street: value.street?.toString?.()?.trim?.() || null,
    city: value.city?.toString?.()?.trim?.() || null,
    governorate: value.governorate?.toString?.()?.trim?.() || null,
    lat: value.lat !== undefined && value.lat !== '' ? Number(value.lat) : null,
    lng: value.lng !== undefined && value.lng !== '' ? Number(value.lng) : null,
  };
}

function normalizePriority(priority) {
  if (!priority) {
    return 'MEDIUM';
  }
  const normalized = String(priority).toUpperCase();
  if (!WORK_ORDER_PRIORITIES.includes(normalized)) {
    throw new AppError('INVALID_PRIORITY', 'Invalid priority value', 422);
  }
  return normalized;
}

function normalizeStatusFilter(status) {
  if (!status || status === 'ALL') {
    return null;
  }
  const normalized = String(status).toUpperCase();
  if (!WORK_ORDER_STATUSES.includes(normalized)) {
    return null;
  }
  return normalized;
}

function buildOrgSnapshot(user) {
  return {
    companyId: user.companyId,
    branchId: user.branchId || null,
    regionId: user.regionId || null,
    cityId: user.cityId || null,
    departmentId: user.departmentId || null,
    teamId: user.teamId || null,
  };
}

function technicianDisplayName(user) {
  return displayUserName(user);
}

class WorkOrdersService {
  async list(user, auth, { page = 1, limit = 20, status, search } = {}) {
    this._assertCanListCompany(auth);

    const filter = {
      companyId: auth.companyId,
      deletedAt: null,
    };

    const statusFilter = normalizeStatusFilter(status);
    if (statusFilter) {
      filter.status = statusFilter;
    }

    if (search && String(search).trim()) {
      const term = escapeRegex(String(search).trim());
      filter.$or = [
        { jobNumber: { $regex: term, $options: 'i' } },
        { jobTitle: { $regex: term, $options: 'i' } },
        { customerName: { $regex: term, $options: 'i' } },
        { locationLabel: { $regex: term, $options: 'i' } },
        { locationUrl: { $regex: term, $options: 'i' } },
        { description: { $regex: term, $options: 'i' } },
        { assignedTechnicianName: { $regex: term, $options: 'i' } },
      ];
    }

    return this._paginate(filter, page, limit);
  }

  async listMyAssignments(user, { page = 1, limit = 20, status, search } = {}) {
    const filter = {
      companyId: user.companyId,
      deletedAt: null,
      $or: [
        { assignedTechnicianId: user._id },
        { assignedTechnicianIds: user._id },
      ],
    };

    const statusFilter = normalizeStatusFilter(status);
    if (statusFilter) {
      filter.status = statusFilter;
    }

    if (search && String(search).trim()) {
      const term = escapeRegex(String(search).trim());
      filter.$and = [
        {
          $or: [
            { jobNumber: { $regex: term, $options: 'i' } },
            { jobTitle: { $regex: term, $options: 'i' } },
            { customerName: { $regex: term, $options: 'i' } },
            { locationLabel: { $regex: term, $options: 'i' } },
            { locationUrl: { $regex: term, $options: 'i' } },
            { description: { $regex: term, $options: 'i' } },
          ],
        },
      ];
    }

    return this._paginate(filter, page, limit);
  }

  async getById(user, auth, id) {
    const record = await this._findActive(id, auth.companyId);
    this._assertCanView(user, auth, record);
    return this._map(record);
  }

  async create(user, auth, body, files = [], voiceNoteFile = null) {
    if (!auth.permissions.includes(PERMISSIONS.WORK_ORDERS_CREATE)) {
      throw new ForbiddenError('You do not have permission to create work orders');
    }

    const jobTitle = String(body.jobTitle || '').trim();
    if (!jobTitle) {
      throw new AppError('TITLE_REQUIRED', 'jobTitle is required', 422);
    }

    const priority = normalizePriority(body.priority);
    const scheduledAt = parseOptionalDate(body.scheduledAt);
    const customerAddress = parseCustomerAddress(body.customerAddress);
    const technicianIds = parseTechnicianIdsFromBody(body) || [];
    const assignees = await this._resolveTechnicians(auth.companyId, technicianIds);
    const locationUrl = normalizeLocationUrl(body.locationUrl ?? undefined);
    const locationLabelRaw = body.locationLabel?.toString?.()?.trim?.() || null;
    const locationLabel =
      locationLabelRaw ||
      (locationUrl !== undefined && locationUrl ? locationUrl : null);
    const customerPhoneNumbers =
      normalizeCustomerPhoneNumbers(body.customerPhoneNumbers) ?? [];

    const attachments = await this._uploadFiles(auth.companyId, files);
    const voiceNote = voiceNoteFile
      ? await this._uploadVoiceNote(auth.companyId, voiceNoteFile)
      : undefined;
    const jobNumber = await this._nextJobNumber(auth.companyId);
    const status = assignees.length ? 'ASSIGNED' : 'PENDING';
    const primary = assignees[0] || null;

    const record = await WorkOrder.create({
      companyId: auth.companyId,
      jobNumber,
      jobTitle,
      customerName: body.customerName?.toString?.()?.trim?.() || null,
      customerAddress,
      customerPhoneNumbers,
      locationLabel,
      locationUrl: locationUrl === undefined ? null : locationUrl,
      assignedTechnicianId: primary?._id || null,
      assignedTechnicianName: technicianDisplayName(primary),
      assignedTechnicianIds: assignees.map((tech) => tech._id),
      assignedTechnicianNames: assignees.map((tech) => technicianDisplayName(tech)),
      createdBy: user._id,
      organizationSnapshot: buildOrgSnapshot(user),
      priority,
      status,
      description: body.description?.toString?.()?.trim?.() || null,
      notes: body.notes?.toString?.()?.trim?.() || null,
      ...(voiceNote ? { voiceNote } : {}),
      scheduledAt,
      attachments,
      timeline: [
        {
          type: 'CREATED',
          at: new Date(),
          userId: user._id,
          userName: displayUserName(user),
          note: null,
        },
        ...(assignees.length
          ? [
              {
                type: 'ASSIGNED',
                at: new Date(),
                userId: user._id,
                userName: displayUserName(user),
                note: assignees.map((tech) => technicianDisplayName(tech)).join(', '),
              },
            ]
          : []),
      ],
      estimatedDurationMinutes:
        body.estimatedDurationMinutes !== undefined &&
        body.estimatedDurationMinutes !== ''
          ? Number(body.estimatedDurationMinutes)
          : null,
    });

    await auditService.log({
      companyId: auth.companyId,
      actorId: user._id,
      actorRole: user.roles[0],
      action: 'work_order.created',
      module: 'work_orders',
      resourceType: 'work_order',
      resourceId: record._id,
      metadata: { jobNumber, status },
    });

    if (assignees.length) {
      notifyWorkOrderAssigned({
        io: getSocketIo(),
        companyId: auth.companyId,
        workOrder: record,
        actor: user,
        newlyAssignedTechnicianIds: assignees.map((tech) => tech._id),
        event: 'created',
      });
    }

    return this._map(record);
  }

  async update(user, auth, id, body, files = [], voiceNoteFile = null) {
    if (!auth.permissions.includes(PERMISSIONS.WORK_ORDERS_UPDATE)) {
      throw new ForbiddenError('You do not have permission to update work orders');
    }

    const record = await this._findActive(id, auth.companyId);

    if (TERMINAL_STATUSES.has(record.status)) {
      throw new ConflictError('Completed or cancelled work orders cannot be edited.');
    }

    if (body.jobTitle !== undefined) {
      const jobTitle = String(body.jobTitle || '').trim();
      if (!jobTitle) {
        throw new AppError('TITLE_REQUIRED', 'jobTitle is required', 422);
      }
      record.jobTitle = jobTitle;
    }

    if (body.customerName !== undefined) {
      record.customerName = body.customerName?.toString?.()?.trim?.() || null;
    }

    if (body.customerPhoneNumbers !== undefined) {
      record.customerPhoneNumbers =
        normalizeCustomerPhoneNumbers(body.customerPhoneNumbers) ?? [];
    }

    if (body.customerAddress !== undefined) {
      record.customerAddress = parseCustomerAddress(body.customerAddress);
    }

    if (body.locationLabel !== undefined) {
      record.locationLabel = body.locationLabel?.toString?.()?.trim?.() || null;
    }

    if (body.locationUrl !== undefined) {
      const locationUrl = normalizeLocationUrl(body.locationUrl);
      record.locationUrl = locationUrl;
      if (locationUrl && (body.locationLabel === undefined || !body.locationLabel)) {
        record.locationLabel = locationUrl;
      }
      if (locationUrl === null && body.locationLabel === undefined) {
        // clearing URL only — keep legacy locationLabel unless also cleared
      }
    }

    if (body.description !== undefined) {
      record.description = body.description?.toString?.()?.trim?.() || null;
    }

    if (body.notes !== undefined) {
      record.notes = body.notes?.toString?.()?.trim?.() || null;
    }

    if (body.priority !== undefined) {
      record.priority = normalizePriority(body.priority);
    }

    if (body.scheduledAt !== undefined) {
      record.scheduledAt = parseOptionalDate(body.scheduledAt);
    }

    if (body.estimatedDurationMinutes !== undefined) {
      record.estimatedDurationMinutes =
        body.estimatedDurationMinutes === '' || body.estimatedDurationMinutes === null
          ? null
          : Number(body.estimatedDurationMinutes);
    }

    const technicianIds = parseTechnicianIdsFromBody(body);
    const previousAssigneeIds = resolveAssigneeIds(record);
    if (technicianIds !== null) {
      await this._applyAssignments(record, auth.companyId, technicianIds);
    }

    const uploaded = files?.length
      ? await this._uploadFiles(auth.companyId, files)
      : [];

    if (body.replaceAttachments === 'true' || body.replaceAttachments === true) {
      let kept = [];
      if (body.keepAttachmentUrls) {
        let urls = body.keepAttachmentUrls;
        if (typeof urls === 'string') {
          try {
            urls = JSON.parse(urls);
          } catch {
            urls = [urls];
          }
        }
        const keep = new Set(Array.isArray(urls) ? urls : []);
        kept = (record.attachments || []).filter((item) => keep.has(item.url));
      }
      record.attachments = [...kept, ...uploaded];
    } else if (uploaded.length) {
      record.attachments = [...(record.attachments || []), ...uploaded];
    }

    if (body.clearVoiceNote === 'true' || body.clearVoiceNote === true) {
      record.voiceNote = undefined;
    } else if (voiceNoteFile) {
      record.voiceNote = await this._uploadVoiceNote(auth.companyId, voiceNoteFile);
    }

    await record.save();

    await auditService.log({
      companyId: auth.companyId,
      actorId: user._id,
      actorRole: user.roles[0],
      action: 'work_order.updated',
      module: 'work_orders',
      resourceType: 'work_order',
      resourceId: record._id,
    });

    if (technicianIds !== null) {
      const nextIds = resolveAssigneeIds(record);
      const newlyAdded = nextIds.filter((id) => !previousAssigneeIds.includes(id));
      if (newlyAdded.length) {
        notifyWorkOrderAssigned({
          io: getSocketIo(),
          companyId: auth.companyId,
          workOrder: record,
          actor: user,
          newlyAssignedTechnicianIds: newlyAdded,
          event: 'updated_assign',
        });
      }
    }

    return this._map(record);
  }

  async softDelete(user, auth, id) {
    if (!auth.permissions.includes(PERMISSIONS.WORK_ORDERS_UPDATE)) {
      throw new ForbiddenError('You do not have permission to delete work orders');
    }

    const record = await this._findActive(id, auth.companyId);
    record.deletedAt = new Date();
    await record.save();

    await auditService.log({
      companyId: auth.companyId,
      actorId: user._id,
      actorRole: user.roles[0],
      action: 'work_order.deleted',
      module: 'work_orders',
      resourceType: 'work_order',
      resourceId: record._id,
    });

    return { id: record._id.toString(), deleted: true };
  }

  async assign(user, auth, id, body) {
    if (!auth.permissions.includes(PERMISSIONS.WORK_ORDERS_ASSIGN)) {
      throw new ForbiddenError('You do not have permission to assign work orders');
    }

    const record = await this._findActive(id, auth.companyId);
    const previousAssigneeIds = resolveAssigneeIds(record);

    if (TERMINAL_STATUSES.has(record.status)) {
      throw new ConflictError('Cannot assign a completed or cancelled work order.');
    }

    if (!['PENDING', 'ASSIGNED', 'REJECTED'].includes(record.status)) {
      throw new ConflictError(
        'Work order can only be assigned when Pending, Assigned, or Rejected.'
      );
    }

    const technicianIds = parseTechnicianIdsFromBody(body);
    if (technicianIds === null || !technicianIds.length) {
      throw new AppError(
        'TECHNICIAN_REQUIRED',
        'assignedTechnicianId or assignedTechnicianIds is required',
        422
      );
    }
    await this._applyAssignments(record, auth.companyId, technicianIds);

    if (body.priority !== undefined) {
      record.priority = normalizePriority(body.priority);
    }
    if (body.scheduledAt !== undefined) {
      record.scheduledAt = parseOptionalDate(body.scheduledAt);
    }

    pushTimeline(record, {
      type: 'ASSIGNED',
      user,
      note: (record.assignedTechnicianNames || []).join(', ') || record.assignedTechnicianName,
    });

    await record.save();

    await auditService.log({
      companyId: auth.companyId,
      actorId: user._id,
      actorRole: user.roles[0],
      action: 'work_order.assigned',
      module: 'work_orders',
      resourceType: 'work_order',
      resourceId: record._id,
      metadata: {
        assignedTechnicianId: toId(record.assignedTechnicianId),
      },
    });

    const nextIds = resolveAssigneeIds(record);
    const newlyAdded = nextIds.filter((id) => !previousAssigneeIds.includes(id));
    const notifyIds =
      newlyAdded.length > 0
        ? newlyAdded
        : previousAssigneeIds.length === 0
          ? nextIds
          : [];
    if (notifyIds.length) {
      notifyWorkOrderAssigned({
        io: getSocketIo(),
        companyId: auth.companyId,
        workOrder: record,
        actor: user,
        newlyAssignedTechnicianIds: notifyIds,
        event: 'assigned',
      });
    }

    return this._map(record);
  }

  async accept(user, auth, id) {
    const record = await this._findActive(id, auth.companyId);
    this._assertIsAssignee(user, auth, record);

    if (record.status !== 'ASSIGNED') {
      throw new ConflictError('Only assigned work orders can be accepted.');
    }

    record.status = 'ACCEPTED';
    record.acceptedAt = new Date();
    record.rejectedAt = null;
    record.rejectionReason = null;
    pushTimeline(record, { type: 'ACCEPTED', user });
    await record.save();

    await auditService.log({
      companyId: auth.companyId,
      actorId: user._id,
      actorRole: user.roles[0],
      action: 'work_order.accepted',
      module: 'work_orders',
      resourceType: 'work_order',
      resourceId: record._id,
    });

    notifyWorkOrderStatusForManagers({
      io: getSocketIo(),
      companyId: auth.companyId,
      workOrder: record,
      actor: user,
      event: 'accepted',
      titleAr: 'قبول أمر شغل',
      titleEn: 'Work Order Accepted',
      bodyAr: `قبل الفني أمر الشغل ${record.jobNumber || ''}`.trim(),
      bodyEn: `Technician accepted work order ${record.jobNumber || ''}`.trim(),
    });

    return this._map(record);
  }

  async reject(user, auth, id, { rejectionReason } = {}) {
    const record = await this._findActive(id, auth.companyId);
    this._assertIsAssignee(user, auth, record);

    if (record.status !== 'ASSIGNED') {
      throw new ConflictError('Only assigned work orders can be rejected.');
    }

    record.status = 'REJECTED';
    record.rejectedAt = new Date();
    record.rejectionReason = rejectionReason?.toString?.()?.trim?.() || null;
    record.acceptedAt = null;
    pushTimeline(record, {
      type: 'REJECTED',
      user,
      note: record.rejectionReason,
    });
    await record.save();

    await auditService.log({
      companyId: auth.companyId,
      actorId: user._id,
      actorRole: user.roles[0],
      action: 'work_order.rejected',
      module: 'work_orders',
      resourceType: 'work_order',
      resourceId: record._id,
      metadata: { rejectionReason: record.rejectionReason },
    });

    return this._map(record);
  }

  async start(user, auth, id, body = {}) {
    const record = await this._findActive(id, auth.companyId);
    this._assertIsAssignee(user, auth, record);

    if (record.status !== 'ACCEPTED') {
      throw new ConflictError('Only accepted work orders can be started.');
    }

    const location = parseFieldLocation(body, { required: true });
    const startedAt = location.recordedAt || new Date();

    record.status = 'IN_PROGRESS';
    record.startedAt = startedAt;
    record.startedLocation = location;
    pushTimeline(record, { type: 'STARTED', user, at: startedAt });
    await record.save();

    await auditService.log({
      companyId: auth.companyId,
      actorId: user._id,
      actorRole: user.roles[0],
      action: 'work_order.started',
      module: 'work_orders',
      resourceType: 'work_order',
      resourceId: record._id,
    });

    return this._map(record);
  }

  async complete(user, auth, id, body = {}) {
    if (!auth.permissions.includes(PERMISSIONS.WORK_ORDERS_COMPLETE)) {
      throw new ForbiddenError('You do not have permission to complete work orders');
    }

    const record = await this._findActive(id, auth.companyId);

    const isAssignee = isUserAssignee(user, record);
    const canManage =
      auth.permissions.includes(PERMISSIONS.WORK_ORDERS_VIEW_ALL) ||
      auth.permissions.includes(PERMISSIONS.WORK_ORDERS_VIEW_TEAM);

    if (!isAssignee && !canManage) {
      throw new ForbiddenError('You can only complete work orders assigned to you');
    }

    if (record.status !== 'IN_PROGRESS') {
      throw new ConflictError('Only in-progress work orders can be completed.');
    }

    if (!record.startedAt) {
      throw new ConflictError('Work order must be started before completion.');
    }

    if (!record.afterPhotos?.length) {
      throw new AppError(
        'AFTER_PHOTO_REQUIRED',
        'At least one after photo is required to complete the work order',
        422
      );
    }

    const location = parseFieldLocation(body, { required: true });
    const now = location.recordedAt || new Date();
    record.status = 'COMPLETED';
    record.completedAt = now;
    record.completedLocation = location;

    if (body.completionNotes !== undefined) {
      record.completionNotes =
        body.completionNotes?.toString?.()?.trim?.() || null;
    } else if (body.notes !== undefined) {
      // Backward-compatible: notes still accepted as completion notes
      record.completionNotes = body.notes?.toString?.()?.trim?.() || null;
    }

    if (record.startedAt) {
      record.actualDurationMinutes = Math.max(
        0,
        Math.round((now.getTime() - new Date(record.startedAt).getTime()) / 60000)
      );
    }

    pushTimeline(record, {
      type: 'COMPLETED',
      user,
      at: now,
      note: record.completionNotes,
    });
    await record.save();

    await auditService.log({
      companyId: auth.companyId,
      actorId: user._id,
      actorRole: user.roles[0],
      action: 'work_order.completed',
      module: 'work_orders',
      resourceType: 'work_order',
      resourceId: record._id,
    });

    notifyWorkOrderStatusForManagers({
      io: getSocketIo(),
      companyId: auth.companyId,
      workOrder: record,
      actor: user,
      event: 'completed',
      titleAr: 'إكمال أمر شغل',
      titleEn: 'Work Order Completed',
      bodyAr: `أكمل الفني أمر الشغل ${record.jobNumber || ''}`.trim(),
      bodyEn: `Technician completed work order ${record.jobNumber || ''}`.trim(),
    });

    return this._map(record);
  }

  async cancel(user, auth, id, { cancellationReason } = {}) {
    if (!auth.permissions.includes(PERMISSIONS.WORK_ORDERS_CANCEL)) {
      throw new ForbiddenError('You do not have permission to cancel work orders');
    }

    const record = await this._findActive(id, auth.companyId);

    if (!CANCELABLE_STATUSES.has(record.status)) {
      throw new ConflictError('This work order cannot be cancelled.');
    }

    record.status = 'CANCELLED';
    record.cancelledAt = new Date();
    record.cancelledBy = user._id;
    record.cancellationReason =
      cancellationReason?.toString?.()?.trim?.() || null;
    pushTimeline(record, {
      type: 'CANCELLED',
      user,
      note: record.cancellationReason,
    });
    await record.save();

    await auditService.log({
      companyId: auth.companyId,
      actorId: user._id,
      actorRole: user.roles[0],
      action: 'work_order.cancelled',
      module: 'work_orders',
      resourceType: 'work_order',
      resourceId: record._id,
      metadata: { cancellationReason: record.cancellationReason },
    });

    return this._map(record);
  }

  async countActive(companyId) {
    return WorkOrder.countDocuments({ companyId, deletedAt: null });
  }

  async saveBeforeWork(user, auth, id, body, files = []) {
    const record = await this._findActive(id, auth.companyId);
    this._assertIsAssignee(user, auth, record);

    if (!['ACCEPTED', 'IN_PROGRESS'].includes(record.status)) {
      throw new ConflictError(
        'Before-work updates are only allowed on accepted or in-progress work orders.'
      );
    }

    if (body.beforeNotes !== undefined) {
      record.beforeNotes = body.beforeNotes?.toString?.()?.trim?.() || null;
    }

    if (files?.length) {
      const uploaded = await this._uploadExecutionPhotos(
        auth.companyId,
        files,
        user._id
      );
      record.beforePhotos = [...(record.beforePhotos || []), ...uploaded];
    }

    await record.save();
    return this._map(record);
  }

  async addProgressNote(user, auth, id, { text } = {}) {
    const record = await this._findActive(id, auth.companyId);
    this._assertIsAssignee(user, auth, record);

    if (record.status !== 'IN_PROGRESS') {
      throw new ConflictError('Progress notes can only be added while work is in progress.');
    }

    const noteText = text?.toString?.()?.trim?.();
    if (!noteText) {
      throw new AppError('NOTE_REQUIRED', 'Progress note text is required', 422);
    }

    record.progressNotes.push({
      text: noteText,
      createdAt: new Date(),
      createdBy: user._id,
      createdByName: displayUserName(user),
    });
    await record.save();
    return this._map(record);
  }

  async addProgressPhotos(user, auth, id, files = []) {
    const record = await this._findActive(id, auth.companyId);
    this._assertIsAssignee(user, auth, record);

    if (record.status !== 'IN_PROGRESS') {
      throw new ConflictError('Progress photos can only be added while work is in progress.');
    }

    if (!files?.length) {
      throw new AppError('PHOTOS_REQUIRED', 'At least one photo is required', 422);
    }

    const uploaded = await this._uploadExecutionPhotos(
      auth.companyId,
      files,
      user._id
    );
    record.progressPhotos = [...(record.progressPhotos || []), ...uploaded];
    await record.save();
    return this._map(record);
  }

  async addAfterPhotos(user, auth, id, files = []) {
    const record = await this._findActive(id, auth.companyId);
    this._assertIsAssignee(user, auth, record);

    if (record.status !== 'IN_PROGRESS') {
      throw new ConflictError('After photos can only be added while work is in progress.');
    }

    if (!files?.length) {
      throw new AppError('PHOTOS_REQUIRED', 'At least one photo is required', 422);
    }

    const uploaded = await this._uploadExecutionPhotos(
      auth.companyId,
      files,
      user._id
    );
    record.afterPhotos = [...(record.afterPhotos || []), ...uploaded];
    await record.save();
    return this._map(record);
  }

  async removePhoto(user, auth, id, { category, url } = {}) {
    const record = await this._findActive(id, auth.companyId);
    this._assertIsAssignee(user, auth, record);

    if (TERMINAL_STATUSES.has(record.status)) {
      throw new ConflictError('Photos cannot be removed after completion or cancellation.');
    }

    if (!PHOTO_CATEGORIES.includes(category)) {
      throw new AppError('INVALID_CATEGORY', 'Invalid photo category', 422);
    }

    if (!url) {
      throw new AppError('URL_REQUIRED', 'Photo url is required', 422);
    }

    if (category === 'before' && !['ACCEPTED', 'IN_PROGRESS'].includes(record.status)) {
      throw new ConflictError('Before photos can only be removed before completion.');
    }
    if (
      (category === 'progress' || category === 'after') &&
      record.status !== 'IN_PROGRESS'
    ) {
      throw new ConflictError(
        'Progress/after photos can only be removed while work is in progress.'
      );
    }

    const field = photoFieldForCategory(category);
    const before = record[field] || [];
    const next = before.filter((item) => item.url !== url);
    if (next.length === before.length) {
      throw new NotFoundError('Photo');
    }
    record[field] = next;
    await record.save();
    return this._map(record);
  }

  async _uploadExecutionPhotos(companyId, files, userId) {
    const uploads = await this._uploadFiles(companyId, files);
    return uploads.map((item) => ({
      ...item,
      uploadedBy: userId,
    }));
  }

  async _paginate(filter, page, limit) {
    const pageNum = Math.max(1, Number(page) || 1);
    const limitNum = Math.min(100, Math.max(1, Number(limit) || 20));
    const skip = (pageNum - 1) * limitNum;

    const [items, total] = await Promise.all([
      WorkOrder.find(filter)
        .select(WORK_ORDER_LIST_SELECT)
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limitNum)
        .lean(),
      WorkOrder.countDocuments(filter),
    ]);

    return {
      items: items.map((item) => this._mapList(item)),
      pagination: {
        page: pageNum,
        limit: limitNum,
        total,
        totalPages: Math.max(1, Math.ceil(total / limitNum)),
      },
    };
  }

  async _findActive(id, companyId) {
    const record = await WorkOrder.findOne({
      _id: id,
      companyId,
      deletedAt: null,
    });
    if (!record) {
      throw new NotFoundError('Work order', 'WORK_ORDER_NOT_FOUND');
    }
    return record;
  }

  async _nextJobNumber(companyId) {
    const now = new Date();
    const y = now.getUTCFullYear();
    const m = String(now.getUTCMonth() + 1).padStart(2, '0');
    const d = String(now.getUTCDate()).padStart(2, '0');
    const prefix = `WO-${y}${m}${d}-`;

    const latest = await WorkOrder.findOne({
      companyId,
      jobNumber: { $regex: `^${prefix}` },
    })
      .sort({ jobNumber: -1 })
      .select('jobNumber');

    let seq = 1;
    if (latest?.jobNumber) {
      const parts = latest.jobNumber.split('-');
      const last = Number(parts[parts.length - 1]);
      if (!Number.isNaN(last)) {
        seq = last + 1;
      }
    }

    return `${prefix}${String(seq).padStart(4, '0')}`;
  }

  async _resolveTechnician(companyId, technicianId) {
    if (!technicianId) {
      return null;
    }

    const technician = await User.findOne({
      _id: technicianId,
      companyId,
      deletedAt: null,
      isActive: true,
    }).select('firstName lastName email roles');

    if (!technician) {
      throw new NotFoundError('Technician');
    }

    return technician;
  }

  async _resolveTechnicians(companyId, technicianIds = []) {
    const unique = [...new Set((technicianIds || []).map(String).filter(Boolean))];
    const technicians = [];
    for (const id of unique) {
      const technician = await this._resolveTechnician(companyId, id);
      if (technician) {
        technicians.push(technician);
      }
    }
    return technicians;
  }

  async _applyAssignment(record, companyId, technicianId) {
    await this._applyAssignments(
      record,
      companyId,
      technicianId ? [technicianId] : []
    );
  }

  async _applyAssignments(record, companyId, technicianIds = []) {
    const technicians = await this._resolveTechnicians(companyId, technicianIds);

    if (!technicians.length) {
      record.assignedTechnicianId = null;
      record.assignedTechnicianName = null;
      record.assignedTechnicianIds = [];
      record.assignedTechnicianNames = [];
      if (record.status === 'ASSIGNED' || record.status === 'REJECTED') {
        record.status = 'PENDING';
      }
      return;
    }

    record.assignedTechnicianIds = technicians.map((tech) => tech._id);
    record.assignedTechnicianNames = technicians.map((tech) =>
      technicianDisplayName(tech)
    );
    record.assignedTechnicianId = technicians[0]._id;
    record.assignedTechnicianName = technicianDisplayName(technicians[0]);
    record.status = 'ASSIGNED';
    record.acceptedAt = null;
    record.rejectedAt = null;
    record.rejectionReason = null;
    record.startedAt = null;
  }

  async _uploadFiles(companyId, files = []) {
    if (!files?.length) {
      return [];
    }

    const uploads = [];
    for (const file of files) {
      const uploaded = await uploadWorkOrderAttachmentBuffer(file.buffer, {
        companyId: companyId.toString(),
        fileName: file.originalname,
        mimeType: file.mimetype,
      });
      uploads.push(uploaded);
    }
    return uploads;
  }

  async _uploadVoiceNote(companyId, file) {
    if (!file?.buffer) {
      return null;
    }
    const format =
      file.originalname?.split?.('.')?.pop?.() ||
      (file.mimetype?.includes('mpeg') ? 'mp3' : 'm4a');
    return uploadWorkOrderVoiceNoteBuffer(file.buffer, {
      companyId: companyId.toString(),
      format,
    });
  }

  _assertCanListCompany(auth) {
    if (
      auth.permissions.includes(PERMISSIONS.WORK_ORDERS_VIEW_ALL) ||
      auth.permissions.includes(PERMISSIONS.WORK_ORDERS_VIEW_TEAM)
    ) {
      return;
    }
    throw new ForbiddenError('You do not have permission to list company work orders');
  }

  _assertCanView(user, auth, record) {
    if (
      auth.permissions.includes(PERMISSIONS.WORK_ORDERS_VIEW_ALL) ||
      auth.permissions.includes(PERMISSIONS.WORK_ORDERS_VIEW_TEAM)
    ) {
      return;
    }

    if (
      auth.permissions.includes(PERMISSIONS.WORK_ORDERS_VIEW_OWN) &&
      isUserAssignee(user, record)
    ) {
      return;
    }

    throw new ForbiddenError('You do not have permission to view this work order');
  }

  _assertIsAssignee(user, auth, record) {
    if (!auth.permissions.includes(PERMISSIONS.WORK_ORDERS_VIEW_OWN)) {
      throw new ForbiddenError('You do not have permission for this action');
    }

    if (!isUserAssignee(user, record)) {
      throw new ForbiddenError('Only the assigned technician can perform this action');
    }
  }

  _map(doc) {
    const assigneeIds = resolveAssigneeIds(doc);
    const assigneeNames = Array.isArray(doc.assignedTechnicianNames) &&
      doc.assignedTechnicianNames.length
      ? doc.assignedTechnicianNames
      : doc.assignedTechnicianName
        ? [doc.assignedTechnicianName]
        : [];

    return {
      id: doc._id.toString(),
      companyId: toId(doc.companyId),
      jobNumber: doc.jobNumber,
      jobTitle: doc.jobTitle,
      customerId: toId(doc.customerId),
      customerName: doc.customerName,
      customerPhoneNumbers: Array.isArray(doc.customerPhoneNumbers)
        ? doc.customerPhoneNumbers.filter((n) => typeof n === 'string' && n.trim())
        : [],
      customerAddress: doc.customerAddress
        ? {
            street: doc.customerAddress.street || null,
            city: doc.customerAddress.city || null,
            governorate: doc.customerAddress.governorate || null,
            lat: doc.customerAddress.lat ?? null,
            lng: doc.customerAddress.lng ?? null,
          }
        : null,
      locationLabel: doc.locationLabel,
      locationUrl: doc.locationUrl || null,
      assignedTechnicianId: toId(doc.assignedTechnicianId),
      assignedTechnicianName: doc.assignedTechnicianName,
      assignedTechnicianIds: assigneeIds,
      assignedTechnicianNames: assigneeNames,
      supervisorId: toId(doc.supervisorId),
      createdBy: toId(doc.createdBy),
      organizationSnapshot: doc.organizationSnapshot
        ? {
            companyId: toId(doc.organizationSnapshot.companyId),
            branchId: toId(doc.organizationSnapshot.branchId),
            regionId: toId(doc.organizationSnapshot.regionId),
            cityId: toId(doc.organizationSnapshot.cityId),
            departmentId: toId(doc.organizationSnapshot.departmentId),
            teamId: toId(doc.organizationSnapshot.teamId),
          }
        : null,
      priority: doc.priority,
      status: doc.status,
      description: doc.description,
      notes: doc.notes,
      voiceNote: mapVoiceNote(doc.voiceNote),
      scheduledAt: doc.scheduledAt?.toISOString?.() || null,
      attachments: (doc.attachments || []).map((item) => ({
        url: item.url,
        publicId: item.publicId,
        fileName: item.fileName,
        mimeType: item.mimeType,
        uploadedAt: item.uploadedAt?.toISOString?.() || null,
      })),
      beforePhotos: (doc.beforePhotos || []).map(mapPhoto),
      afterPhotos: (doc.afterPhotos || []).map(mapPhoto),
      progressPhotos: (doc.progressPhotos || []).map(mapPhoto),
      beforeNotes: doc.beforeNotes || null,
      progressNotes: (doc.progressNotes || []).map(mapProgressNote),
      completionNotes: doc.completionNotes || null,
      startedLocation: mapFieldLocation(doc.startedLocation),
      completedLocation: mapFieldLocation(doc.completedLocation),
      timeline: (doc.timeline || []).map(mapTimelineEvent),
      estimatedDurationMinutes: doc.estimatedDurationMinutes,
      actualDurationMinutes: doc.actualDurationMinutes,
      startedAt: doc.startedAt?.toISOString?.() || null,
      completedAt: doc.completedAt?.toISOString?.() || null,
      cancelledAt: doc.cancelledAt?.toISOString?.() || null,
      cancelledBy: toId(doc.cancelledBy),
      cancellationReason: doc.cancellationReason,
      rejectedAt: doc.rejectedAt?.toISOString?.() || null,
      rejectionReason: doc.rejectionReason,
      acceptedAt: doc.acceptedAt?.toISOString?.() || null,
      createdAt: doc.createdAt?.toISOString?.() || null,
      updatedAt: doc.updatedAt?.toISOString?.() || null,
    };
  }

  /**
   * Lightweight projection for work-order list cards.
   * Omits photos, attachments, timeline, GPS, notes, and org snapshot.
   * Detail remains on GET /:id via [_map].
   */
  _mapList(doc) {
    const assigneeIds = resolveAssigneeIds(doc);
    const assigneeNames = Array.isArray(doc.assignedTechnicianNames) &&
      doc.assignedTechnicianNames.length
      ? doc.assignedTechnicianNames
      : doc.assignedTechnicianName
        ? [doc.assignedTechnicianName]
        : [];

    return {
      id: doc._id.toString(),
      companyId: toId(doc.companyId),
      jobNumber: doc.jobNumber,
      jobTitle: doc.jobTitle,
      customerName: doc.customerName || null,
      assignedTechnicianId: toId(doc.assignedTechnicianId),
      assignedTechnicianName: doc.assignedTechnicianName || null,
      assignedTechnicianIds: assigneeIds,
      assignedTechnicianNames: assigneeNames,
      priority: doc.priority,
      status: doc.status,
      scheduledAt: doc.scheduledAt?.toISOString?.() || doc.scheduledAt || null,
      createdAt: doc.createdAt?.toISOString?.() || doc.createdAt || null,
    };
  }
}

export default new WorkOrdersService();
