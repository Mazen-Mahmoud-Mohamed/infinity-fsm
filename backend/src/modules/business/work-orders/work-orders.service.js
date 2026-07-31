import WorkOrder, {
  WORK_ORDER_PRIORITIES,
  WORK_ORDER_STATUSES,
} from './models/workOrder.model.js';
import User from '../../core/organization/models/user.model.js';
import { uploadWorkOrderAttachmentBuffer } from './work-orders.upload.js';
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

const TERMINAL_STATUSES = new Set(['COMPLETED', 'CANCELLED']);
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
        { description: { $regex: term, $options: 'i' } },
        { assignedTechnicianName: { $regex: term, $options: 'i' } },
      ];
    }

    return this._paginate(filter, page, limit);
  }

  async listMyAssignments(user, { page = 1, limit = 20, status, search } = {}) {
    const filter = {
      companyId: user.companyId,
      assignedTechnicianId: user._id,
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
        { description: { $regex: term, $options: 'i' } },
      ];
    }

    return this._paginate(filter, page, limit);
  }

  async getById(user, auth, id) {
    const record = await this._findActive(id, auth.companyId);
    this._assertCanView(user, auth, record);
    return this._map(record);
  }

  async create(user, auth, body, files = []) {
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
    const assignee = await this._resolveTechnician(
      auth.companyId,
      body.assignedTechnicianId
    );

    const attachments = await this._uploadFiles(auth.companyId, files);
    const jobNumber = await this._nextJobNumber(auth.companyId);
    const status = assignee ? 'ASSIGNED' : 'PENDING';

    const record = await WorkOrder.create({
      companyId: auth.companyId,
      jobNumber,
      jobTitle,
      customerName: body.customerName?.toString?.()?.trim?.() || null,
      customerAddress,
      locationLabel: body.locationLabel?.toString?.()?.trim?.() || null,
      assignedTechnicianId: assignee?._id || null,
      assignedTechnicianName: technicianDisplayName(assignee),
      createdBy: user._id,
      organizationSnapshot: buildOrgSnapshot(user),
      priority,
      status,
      description: body.description?.toString?.()?.trim?.() || null,
      notes: body.notes?.toString?.()?.trim?.() || null,
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
        ...(assignee
          ? [
              {
                type: 'ASSIGNED',
                at: new Date(),
                userId: user._id,
                userName: displayUserName(user),
                note: technicianDisplayName(assignee),
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

    return this._map(record);
  }

  async update(user, auth, id, body, files = []) {
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

    if (body.customerAddress !== undefined) {
      record.customerAddress = parseCustomerAddress(body.customerAddress);
    }

    if (body.locationLabel !== undefined) {
      record.locationLabel = body.locationLabel?.toString?.()?.trim?.() || null;
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

    if (body.assignedTechnicianId !== undefined) {
      const technicianId =
        body.assignedTechnicianId === '' ||
        body.assignedTechnicianId === null ||
        body.assignedTechnicianId === 'null'
          ? null
          : body.assignedTechnicianId;
      await this._applyAssignment(record, auth.companyId, technicianId);
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

    if (TERMINAL_STATUSES.has(record.status)) {
      throw new ConflictError('Cannot assign a completed or cancelled work order.');
    }

    if (!['PENDING', 'ASSIGNED', 'REJECTED'].includes(record.status)) {
      throw new ConflictError(
        'Work order can only be assigned when Pending, Assigned, or Rejected.'
      );
    }

    await this._applyAssignment(record, auth.companyId, body.assignedTechnicianId);

    if (body.priority !== undefined) {
      record.priority = normalizePriority(body.priority);
    }
    if (body.scheduledAt !== undefined) {
      record.scheduledAt = parseOptionalDate(body.scheduledAt);
    }

    pushTimeline(record, {
      type: 'ASSIGNED',
      user,
      note: record.assignedTechnicianName,
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

    const isAssignee =
      toId(record.assignedTechnicianId) === toId(user._id);
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
      WorkOrder.find(filter).sort({ createdAt: -1 }).skip(skip).limit(limitNum),
      WorkOrder.countDocuments(filter),
    ]);

    return {
      items: items.map((item) => this._map(item)),
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

  async _applyAssignment(record, companyId, technicianId) {
    if (!technicianId) {
      record.assignedTechnicianId = null;
      record.assignedTechnicianName = null;
      if (record.status === 'ASSIGNED' || record.status === 'REJECTED') {
        record.status = 'PENDING';
      }
      return;
    }

    const technician = await this._resolveTechnician(companyId, technicianId);
    record.assignedTechnicianId = technician._id;
    record.assignedTechnicianName = technicianDisplayName(technician);
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
      toId(record.assignedTechnicianId) === toId(user._id)
    ) {
      return;
    }

    throw new ForbiddenError('You do not have permission to view this work order');
  }

  _assertIsAssignee(user, auth, record) {
    if (!auth.permissions.includes(PERMISSIONS.WORK_ORDERS_VIEW_OWN)) {
      throw new ForbiddenError('You do not have permission for this action');
    }

    if (toId(record.assignedTechnicianId) !== toId(user._id)) {
      throw new ForbiddenError('Only the assigned technician can perform this action');
    }
  }

  _map(doc) {
    return {
      id: doc._id.toString(),
      companyId: toId(doc.companyId),
      jobNumber: doc.jobNumber,
      jobTitle: doc.jobTitle,
      customerId: toId(doc.customerId),
      customerName: doc.customerName,
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
      assignedTechnicianId: toId(doc.assignedTechnicianId),
      assignedTechnicianName: doc.assignedTechnicianName,
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
}

export default new WorkOrdersService();
