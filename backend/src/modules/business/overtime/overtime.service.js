import mongoose from 'mongoose';
import OvertimeRecord from './models/overtimeRecord.model.js';
import {
  uploadOvertimePhotoBuffer,
  uploadOvertimeVoiceNoteBuffer,
} from './overtime.upload.js';
import {
  assertReasonableSessionLength,
  calculateOvertimeDurations,
} from './overtime.calculation.js';
import config from '../../../config/index.js';
import PERMISSIONS from '../../../shared/constants/permissions.constants.js';
import AppError, {
  ConflictError,
  ForbiddenError,
  NotFoundError,
} from '../../../shared/errors/AppError.js';
import auditService from '../../core/audit/audit.service.js';
import { resolveSessionTimeline } from './overtime.timeline.js';
import {
  buildOvertimeExcelWorkbook,
  buildOvertimeExportFileName,
  EXPORT_MODE,
  MAX_EXPORT_ROWS,
} from './overtime.excel.export.js';
import User from '../../core/organization/models/user.model.js';
import Company from '../../core/organization/models/company.model.js';
import { createRequire } from 'module';

const require = createRequire(import.meta.url);
const pkg = require('../../../../package.json');

const WORKFLOW_V2 = 'v2';
const WORKFLOW_V1 = 'v1';

const CHECKPOINT_STAGES = Object.freeze({
  START_JOURNEY: 'startJourney',
  ARRIVED: 'arrivedAtWorkSite',
  FINISHED_WORK: 'finishedWork',
  END_JOURNEY: 'endJourney',
});

function buildGps(body) {
  const fullAddress =
    (body.fullAddress && String(body.fullAddress).trim()) ||
    (body.address && String(body.address).trim()) ||
    null;
  const hasStructured =
    fullAddress ||
    body.street ||
    body.area ||
    body.city ||
    body.country;

  return {
    latitude: Number(body.latitude),
    longitude: Number(body.longitude),
    accuracy: Number(body.accuracy),
    heading: body.heading !== undefined && body.heading !== '' ? Number(body.heading) : null,
    speed: body.speed !== undefined && body.speed !== '' ? Number(body.speed) : null,
    altitude:
      body.altitude !== undefined && body.altitude !== ''
        ? Number(body.altitude)
        : null,
    provider: body.provider || null,
    recordedAt: new Date(body.recordedAt),
    fullAddress,
    street: body.street ? String(body.street).trim() : null,
    area: body.area ? String(body.area).trim() : null,
    city: body.city ? String(body.city).trim() : null,
    country: body.country ? String(body.country).trim() : null,
    addressResolvedAt: body.addressResolvedAt
      ? new Date(body.addressResolvedAt)
      : hasStructured
        ? new Date()
        : null,
  };
}

function assertGpsAccuracy(gps) {
  if (
    !Number.isFinite(gps.latitude) ||
    !Number.isFinite(gps.longitude) ||
    !Number.isFinite(gps.accuracy)
  ) {
    throw new AppError('GPS_REQUIRED', 'Valid GPS coordinates are required', 422);
  }

  const threshold = config.overtime.gpsAccuracyThresholdMeters;
  if (gps.accuracy > threshold) {
    throw new AppError(
      'GPS_ACCURACY_TOO_LOW',
      `Location accuracy (${Math.round(gps.accuracy)}m) exceeds the allowed threshold (${threshold}m). Move to an open area and try again.`,
      422
    );
  }
}

function assertClockSkew(recordedAt, { allowHistorical = false } = {}) {
  if (!recordedAt) return;
  const skewSeconds = config.security.maxDeviceClockSkewSeconds;
  const recordedMs = new Date(recordedAt).getTime();
  if (!Number.isFinite(recordedMs)) {
    throw new AppError(
      'CLOCK_SKEW',
      'Device time appears to be incorrect',
      422
    );
  }
  const now = Date.now();
  if (allowHistorical) {
    // Offline replay: original GPS timestamps may be minutes/hours old.
    // Only reject clocks that are unreasonably ahead of the server.
    if (recordedMs - now > skewSeconds * 1000) {
      throw new AppError(
        'CLOCK_SKEW',
        'Device time appears to be incorrect',
        422
      );
    }
    return;
  }
  const deltaMs = Math.abs(now - recordedMs);
  if (deltaMs > skewSeconds * 1000) {
    throw new AppError(
      'CLOCK_SKEW',
      'Device time appears to be incorrect',
      422
    );
  }
}

function isOfflineTimelineReplay(body = {}) {
  // Flutter offline sync always resends the original client timeline fields.
  return Boolean(
    body.startedAt || body.endedAt || body.checkpointAt || body.durationSeconds
  );
}

function mapStatusFilter(status) {
  if (!status || status === 'ALL') {
    return null;
  }
  const normalized = String(status).toUpperCase();
  if (normalized === 'PENDING' || normalized === 'PENDING_REVIEW') {
    return 'PENDING_REVIEW';
  }
  if (['APPROVED', 'REJECTED', 'RUNNING', 'CANCELLED'].includes(normalized)) {
    return normalized;
  }
  return null;
}

function escapeRegex(value) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function isWorkflowV2(record) {
  return record?.workflowVersion === WORKFLOW_V2;
}

/** Max voice note length (seconds) — matches client recorder limit. */
const MAX_VOICE_NOTE_SECONDS = 120;

function voiceFormatFromMime(mimetype) {
  const mime = String(mimetype || '').toLowerCase();
  if (mime.includes('webm')) return 'webm';
  if (mime.includes('ogg')) return 'ogg';
  if (mime.includes('wav')) return 'wav';
  if (mime.includes('mpeg') || mime.includes('mp3')) return 'mp3';
  if (mime.includes('aac')) return 'aac';
  return 'm4a';
}

async function resolveOptionalVoiceNote(voiceFile, { userId, stageKey }) {
  if (!voiceFile?.buffer?.length) {
    return undefined;
  }
  const voiceNote = await uploadOvertimeVoiceNoteBuffer(voiceFile.buffer, {
    userId,
    stageKey,
    format: voiceFormatFromMime(voiceFile.mimetype),
  });
  if (
    typeof voiceNote.duration === 'number' &&
    Number.isFinite(voiceNote.duration) &&
    voiceNote.duration > MAX_VOICE_NOTE_SECONDS + 2
  ) {
    throw new AppError(
      'VOICE_NOTE_TOO_LONG',
      `Voice notes must be ${MAX_VOICE_NOTE_SECONDS} seconds or less`,
      422
    );
  }
  return voiceNote;
}

function buildCheckpoint({
  at,
  gps,
  photo,
  voiceNote,
  address,
  deviceId,
  notes,
  clientRequestId,
  batteryLevel,
  networkStatus,
}) {
  const battery =
    batteryLevel === undefined || batteryLevel === null || batteryLevel === ''
      ? null
      : Number(batteryLevel);
  return {
    at,
    gps,
    photo,
    ...(voiceNote ? { voiceNote } : {}),
    address: address || null,
    deviceId,
    clientRequestId: clientRequestId ? String(clientRequestId).trim() : null,
    batteryLevel:
      Number.isFinite(battery) && battery >= 0 && battery <= 100
        ? Math.round(battery)
        : null,
    networkStatus: networkStatus
      ? String(networkStatus).trim().slice(0, 40)
      : null,
    notes: notes ? String(notes).trim() : null,
  };
}

function checkpointClientRequestId(record, stageKey) {
  return record?.checkpoints?.[stageKey]?.clientRequestId || null;
}

function parseOptionalBattery(value) {
  if (value === undefined || value === null || value === '') {
    return null;
  }
  const n = Number(value);
  return Number.isFinite(n) ? n : null;
}

function nextCheckpointKey(record) {
  if (!isWorkflowV2(record)) {
    return null;
  }
  const cp = record.checkpoints || {};
  if (!cp.startJourney) return CHECKPOINT_STAGES.START_JOURNEY;
  if (!cp.arrivedAtWorkSite) return CHECKPOINT_STAGES.ARRIVED;
  if (!cp.finishedWork) return CHECKPOINT_STAGES.FINISHED_WORK;
  if (!cp.endJourney) return CHECKPOINT_STAGES.END_JOURNEY;
  return null;
}

class OvertimeService {
  async getRunning(user) {
    const record = await OvertimeRecord.findOne({
      companyId: user.companyId,
      userId: user._id,
      status: 'RUNNING',
    });

    return record ? this._map(record) : null;
  }

  async start(user, body, file, voiceFile) {
    const type = String(body.type || '').toUpperCase();
    if (type !== 'NORMAL' && type !== 'TRAVEL') {
      throw new AppError('INVALID_TYPE', 'Overtime type must be NORMAL or TRAVEL', 422);
    }

    if (!file) {
      throw new AppError('LIVE_PHOTO_REQUIRED', 'A start photo is required', 422);
    }

    if (!body.deviceId) {
      throw new AppError('DEVICE_REQUIRED', 'deviceId is required', 422);
    }

    if (!body.clientRequestId) {
      throw new AppError('CLIENT_REQUEST_REQUIRED', 'clientRequestId is required', 422);
    }

    const existingByClient = await OvertimeRecord.findOne({
      companyId: user.companyId,
      userId: user._id,
      clientRequestId: body.clientRequestId,
    });
    if (existingByClient) {
      await auditService.log({
        companyId: user.companyId,
        actorId: user._id,
        actorRole: user.roles[0],
        action: 'overtime.start_replay',
        module: 'overtime',
        resourceType: 'overtime_record',
        resourceId: existingByClient._id,
        metadata: { clientRequestId: body.clientRequestId },
      });
      return this._map(existingByClient);
    }

    const running = await OvertimeRecord.findOne({
      companyId: user.companyId,
      userId: user._id,
      status: 'RUNNING',
    });
    if (running) {
      throw new ConflictError('You already have a running overtime session.');
    }

    const gps = buildGps(body);
    assertClockSkew(gps.recordedAt, {
      allowHistorical: isOfflineTimelineReplay(body),
    });
    assertGpsAccuracy(gps);

    const photo = await uploadOvertimePhotoBuffer(file.buffer, {
      userId: user._id.toString(),
      photoType: 'start',
    });

    const voiceNote = await resolveOptionalVoiceNote(voiceFile, {
      userId: user._id.toString(),
      stageKey: CHECKPOINT_STAGES.START_JOURNEY,
    });

    const { startedAt: startAt } = resolveSessionTimeline({
      body,
      fallbackStartAt: new Date(),
    });

    const address = body.address || body.fullAddress || null;
    const startCheckpoint = buildCheckpoint({
      at: startAt,
      gps,
      photo,
      voiceNote,
      address,
      deviceId: body.deviceId,
      notes: body.notes,
      clientRequestId: body.clientRequestId,
      batteryLevel: parseOptionalBattery(body.batteryLevel),
      networkStatus: body.networkStatus,
    });

    // New sessions always use the 4-stage workflow (v2). Legacy records stay v1.
    const record = await OvertimeRecord.create({
      companyId: user.companyId,
      userId: user._id,
      branchId: user.branchId,
      departmentId: user.departmentId,
      type,
      status: 'RUNNING',
      workflowVersion: WORKFLOW_V2,
      checkpoints: {
        startJourney: startCheckpoint,
      },
      startAt,
      startGps: gps,
      startPhoto: photo,
      startAddress: address,
      startDeviceId: body.deviceId,
      clientRequestId: body.clientRequestId,
    });

    await auditService.log({
      companyId: user.companyId,
      actorId: user._id,
      actorRole: user.roles[0],
      action: 'overtime.started',
      module: 'overtime',
      resourceType: 'overtime_record',
      resourceId: record._id,
      metadata: { type, workflowVersion: WORKFLOW_V2, checkpoint: CHECKPOINT_STAGES.START_JOURNEY },
    });

    return this._map(record);
  }

  /**
   * Additive mid-journey checkpoints (v2 only).
   * stage: arrivedAtWorkSite | finishedWork
   * Idempotent via clientRequestId when the stage is already recorded.
   */
  async recordCheckpoint(user, id, stage, body, file, voiceFile) {
    const normalized = String(stage || '').trim();
    if (
      normalized !== CHECKPOINT_STAGES.ARRIVED &&
      normalized !== CHECKPOINT_STAGES.FINISHED_WORK
    ) {
      throw new AppError(
        'INVALID_CHECKPOINT',
        'Checkpoint must be arrivedAtWorkSite or finishedWork',
        422
      );
    }

    const record = await OvertimeRecord.findOne({
      _id: id,
      companyId: user.companyId,
    });

    if (!record) {
      throw new NotFoundError('Overtime session');
    }

    if (record.userId.toString() !== user._id.toString()) {
      throw new ForbiddenError('You can only update your own overtime session');
    }

    if (!body.clientRequestId) {
      throw new AppError(
        'CLIENT_REQUEST_REQUIRED',
        'clientRequestId is required',
        422
      );
    }

    const clientRequestId = String(body.clientRequestId).trim();
    const existingCp = record.checkpoints?.[normalized];
    if (existingCp) {
      const existingId = existingCp.clientRequestId;
      if (existingId && existingId === clientRequestId) {
        await auditService.log({
          companyId: user.companyId,
          actorId: user._id,
          actorRole: user.roles[0],
          action: 'overtime.checkpoint_replay',
          module: 'overtime',
          resourceType: 'overtime_record',
          resourceId: record._id,
          metadata: { checkpoint: normalized, clientRequestId },
        });
        // Idempotent replay (double-tap / retry / offline sync).
        return this._map(await this._loadWithTechnician(record._id, user.companyId));
      }
      throw new ConflictError(
        `Checkpoint ${normalized} is already completed and cannot be repeated`
      );
    }

    if (record.status !== 'RUNNING') {
      throw new ConflictError(
        `Cannot record a checkpoint on a session that is ${record.status.toLowerCase()}`
      );
    }

    if (!isWorkflowV2(record)) {
      throw new AppError(
        'LEGACY_WORKFLOW',
        'This session uses the legacy start/end workflow and does not support mid-journey checkpoints',
        422
      );
    }

    const expected = nextCheckpointKey(record);
    if (expected !== normalized) {
      throw new ConflictError(
        expected
          ? `Next required checkpoint is ${expected}`
          : 'All checkpoints are already completed'
      );
    }

    if (!file) {
      throw new AppError('LIVE_PHOTO_REQUIRED', 'A checkpoint photo is required', 422);
    }

    if (!body.deviceId) {
      throw new AppError('DEVICE_REQUIRED', 'deviceId is required', 422);
    }

    const gps = buildGps(body);
    assertClockSkew(gps.recordedAt, {
      allowHistorical: isOfflineTimelineReplay(body),
    });
    assertGpsAccuracy(gps);

    const { startedAt: checkpointAt } = resolveSessionTimeline({
      body: {
        startedAt: body.checkpointAt || body.startedAt || body.recordedAt,
      },
      fallbackStartAt: new Date(),
    });

    const photo = await uploadOvertimePhotoBuffer(file.buffer, {
      userId: user._id.toString(),
      photoType: normalized,
    });

    const voiceNote = await resolveOptionalVoiceNote(voiceFile, {
      userId: user._id.toString(),
      stageKey: normalized,
    });

    if (!record.checkpoints) {
      record.checkpoints = {};
    }

    record.checkpoints[normalized] = buildCheckpoint({
      at: checkpointAt,
      gps,
      photo,
      voiceNote,
      address: body.address || body.fullAddress || null,
      deviceId: body.deviceId,
      notes: body.notes,
      clientRequestId,
      batteryLevel: parseOptionalBattery(body.batteryLevel),
      networkStatus: body.networkStatus,
    });
    record.markModified('checkpoints');
    await record.save();

    await auditService.log({
      companyId: user.companyId,
      actorId: user._id,
      actorRole: user.roles[0],
      action: 'overtime.checkpoint',
      module: 'overtime',
      resourceType: 'overtime_record',
      resourceId: record._id,
      metadata: { checkpoint: normalized, clientRequestId },
    });

    return this._map(await this._loadWithTechnician(record._id, user.companyId));
  }

  async end(user, id, body, file, voiceFile) {
    const record = await OvertimeRecord.findOne({
      _id: id,
      companyId: user.companyId,
    });

    if (!record) {
      throw new NotFoundError('Overtime session');
    }

    if (record.userId.toString() !== user._id.toString()) {
      throw new ForbiddenError('You can only end your own overtime session');
    }

    const clientRequestId = body.clientRequestId
      ? String(body.clientRequestId).trim()
      : null;

    // Idempotent end replay: already finished with the same clientRequestId.
    if (record.status !== 'RUNNING') {
      const endClientId = checkpointClientRequestId(
        record,
        CHECKPOINT_STAGES.END_JOURNEY
      );
      if (
        clientRequestId &&
        endClientId &&
        endClientId === clientRequestId
      ) {
        return this._map(
          await this._loadWithTechnician(record._id, user.companyId)
        );
      }
      throw new ConflictError(
        `Cannot end a session that is already ${record.status.toLowerCase()}`
      );
    }

    // v2 sessions must complete mid-journey checkpoints before End Journey.
    if (isWorkflowV2(record)) {
      const expected = nextCheckpointKey(record);
      if (expected && expected !== CHECKPOINT_STAGES.END_JOURNEY) {
        throw new ConflictError(
          `Complete ${expected} before ending the journey`
        );
      }
      if (!clientRequestId) {
        throw new AppError(
          'CLIENT_REQUEST_REQUIRED',
          'clientRequestId is required',
          422
        );
      }
    }

    if (!file) {
      throw new AppError('LIVE_PHOTO_REQUIRED', 'An end photo is required', 422);
    }

    if (!body.deviceId) {
      throw new AppError('DEVICE_REQUIRED', 'deviceId is required', 422);
    }

    const gps = buildGps(body);
    assertClockSkew(gps.recordedAt, {
      allowHistorical: isOfflineTimelineReplay(body),
    });
    assertGpsAccuracy(gps);

    const {
      startedAt,
      endedAt,
      usedClientStart,
    } = resolveSessionTimeline({
      body,
      fallbackStartAt: record.startAt,
      fallbackEndAt: new Date(),
    });

    const softMaxHours = config.overtime.maxSessionHours;
    const absoluteMaxHours =
      config.overtime.absoluteMaxSessionHours || softMaxHours;

    // Hard ceiling — abnormal beyond absolute max.
    if (!assertReasonableSessionLength(startedAt, endedAt, absoluteMaxHours)) {
      throw new AppError(
        'SESSION_TOO_LONG',
        `Overtime session exceeds the absolute maximum of ${absoluteMaxHours} hours.`,
        422
      );
    }

    // Soft policy — allow end but force manual review.
    const exceedsSoftPolicy = !assertReasonableSessionLength(
      startedAt,
      endedAt,
      softMaxHours
    );

    const photo = await uploadOvertimePhotoBuffer(file.buffer, {
      userId: user._id.toString(),
      photoType: 'end',
    });

    const voiceNote = await resolveOptionalVoiceNote(voiceFile, {
      userId: user._id.toString(),
      stageKey: CHECKPOINT_STAGES.END_JOURNEY,
    });

    // Duration still uses Stage 1 (start) → Stage 4 (end) only.
    const calculated = calculateOvertimeDurations(startedAt, endedAt);

    record.status = 'PENDING_REVIEW';
    if (usedClientStart) {
      record.startAt = startedAt;
    }
    record.endAt = endedAt;
    record.endGps = gps;
    record.endPhoto = photo;
    record.endAddress = body.address || body.fullAddress || null;
    record.endDeviceId = body.deviceId;
    record.totalDurationMinutes = calculated.totalDurationMinutes;
    record.workingDurationMinutes = calculated.workingDurationMinutes;
    record.eligibleOvertimeMinutes = calculated.eligibleOvertimeMinutes;
    record.calculationVersion = calculated.calculationVersion;
    record.calculatedAt = calculated.calculatedAt;

    if (exceedsSoftPolicy) {
      record.requiresManualReview = true;
      record.reviewReason = `Session duration exceeded company policy of ${softMaxHours} hours`;
    }

    if (isWorkflowV2(record)) {
      if (!record.checkpoints) {
        record.checkpoints = {};
      }
      record.checkpoints.endJourney = buildCheckpoint({
        at: endedAt,
        gps,
        photo,
        voiceNote,
        address: body.address || body.fullAddress || null,
        deviceId: body.deviceId,
        notes: body.notes,
        clientRequestId,
        batteryLevel: parseOptionalBattery(body.batteryLevel),
        networkStatus: body.networkStatus,
      });
      // Keep startJourney synced if client corrected startAt.
      if (usedClientStart && record.checkpoints.startJourney) {
        record.checkpoints.startJourney.at = startedAt;
      }
      record.markModified('checkpoints');
    }

    await record.save();

    await auditService.log({
      companyId: user.companyId,
      actorId: user._id,
      actorRole: user.roles[0],
      action: 'overtime.ended',
      module: 'overtime',
      resourceType: 'overtime_record',
      resourceId: record._id,
      metadata: {
        totalDurationMinutes: calculated.totalDurationMinutes,
        eligibleOvertimeMinutes: calculated.eligibleOvertimeMinutes,
        workflowVersion: record.workflowVersion || WORKFLOW_V1,
        requiresManualReview: !!record.requiresManualReview,
        clientRequestId: clientRequestId || null,
      },
    });

    return this._map(await this._loadWithTechnician(record._id, user.companyId));
  }

  async listSessions(user, auth, {
    page = 1,
    limit = 20,
    status,
    search,
  } = {}) {
    this._assertCanViewAll(auth);

    const filter = { companyId: auth.companyId };
    const statusFilter = mapStatusFilter(status);
    if (statusFilter) {
      filter.status = statusFilter;
    }

    if (search && String(search).trim()) {
      const User = (await import('../../core/organization/models/user.model.js')).default;
      const term = escapeRegex(String(search).trim());
      const matchingUsers = await User.find({
        companyId: auth.companyId,
        $or: [
          { firstName: { $regex: term, $options: 'i' } },
          { lastName: { $regex: term, $options: 'i' } },
          { email: { $regex: term, $options: 'i' } },
        ],
      }).select('_id');
      filter.userId = { $in: matchingUsers.map((item) => item._id) };
    }

    const skip = (page - 1) * limit;
    const [items, total] = await Promise.all([
      OvertimeRecord.find(filter)
        .populate('userId', 'firstName lastName email roles')
        .populate('approvedBy', 'firstName lastName email')
        .populate('rejectedBy', 'firstName lastName email')
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit),
      OvertimeRecord.countDocuments(filter),
    ]);

    return {
      items: items.map((item) => this._map(item)),
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.max(1, Math.ceil(total / limit)),
      },
    };
  }

  /**
   * Admin/Supervisor Excel export — reporting only (does not alter overtime data).
   */
  async exportExcel(user, auth, query = {}) {
    this._assertCanExport(user, auth);

    const {
      status,
      search,
      type,
      userId,
      departmentId,
      branchId,
      startDate,
      endDate,
      mode: modeRaw,
    } = query;

    const exportMode =
      String(modeRaw || '').trim().toLowerCase() === EXPORT_MODE.SUMMARY
        ? EXPORT_MODE.SUMMARY
        : EXPORT_MODE.DETAILED;

    const filter = { companyId: auth.companyId };
    const statusFilter = mapStatusFilter(status);
    if (statusFilter) {
      filter.status = statusFilter;
    }

    const normalizedType = type ? String(type).trim().toUpperCase() : '';
    if (normalizedType === 'NORMAL' || normalizedType === 'TRAVEL') {
      filter.type = normalizedType;
    }

    if (branchId && mongoose.isValidObjectId(branchId)) {
      filter.branchId = branchId;
    }

    if (startDate || endDate) {
      filter.startAt = {};
      if (startDate) {
        const from = new Date(startDate);
        if (!Number.isNaN(from.getTime())) {
          filter.startAt.$gte = from;
        }
      }
      if (endDate) {
        const to = new Date(endDate);
        if (!Number.isNaN(to.getTime())) {
          // Inclusive end-of-day when date-only string.
          if (/^\d{4}-\d{2}-\d{2}$/.test(String(endDate).trim())) {
            to.setUTCHours(23, 59, 59, 999);
          }
          filter.startAt.$lte = to;
        }
      }
      if (Object.keys(filter.startAt).length === 0) {
        delete filter.startAt;
      }
    }

    let userIds = null;
    if (userId && mongoose.isValidObjectId(userId)) {
      userIds = [userId];
    }

    if (departmentId && mongoose.isValidObjectId(departmentId)) {
      const deptUsers = await User.find({
        companyId: auth.companyId,
        departmentId,
      }).select('_id');
      const deptIds = deptUsers.map((u) => u._id.toString());
      userIds = userIds
        ? userIds.filter((id) => deptIds.includes(String(id)))
        : deptIds;
    }

    if (search && String(search).trim()) {
      const term = escapeRegex(String(search).trim());
      const matchingUsers = await User.find({
        companyId: auth.companyId,
        $or: [
          { firstName: { $regex: term, $options: 'i' } },
          { lastName: { $regex: term, $options: 'i' } },
          { email: { $regex: term, $options: 'i' } },
          { employeeId: { $regex: term, $options: 'i' } },
        ],
      }).select('_id');
      const searchIds = matchingUsers.map((item) => item._id.toString());
      userIds = userIds
        ? userIds.filter((id) => searchIds.includes(String(id)))
        : searchIds;
    }

    if (userIds) {
      filter.userId = { $in: userIds };
    }

    const records = await OvertimeRecord.find(filter)
      .populate({
        path: 'userId',
        select:
          'firstName lastName email roles employeeId departmentId branchId jobTitle',
        populate: [
          { path: 'departmentId', select: 'name' },
          { path: 'branchId', select: 'name' },
        ],
      })
      .populate('branchId', 'name')
      .populate('approvedBy', 'firstName lastName email')
      .populate('rejectedBy', 'firstName lastName email')
      .sort({ createdAt: -1 })
      .limit(MAX_EXPORT_ROWS)
      .lean();

    const dateRange =
      startDate || endDate
        ? `${startDate || '…'} → ${endDate || '…'}`
        : 'All';

    const generatedBy = [user.firstName, user.lastName]
      .filter(Boolean)
      .join(' ')
      .trim() || user.email || user._id?.toString?.();

    const generatedAt = new Date();
    const [company, employeeForName] = await Promise.all([
      Company.findById(auth.companyId).select('name logoUrl').lean(),
      userId && mongoose.isValidObjectId(userId)
        ? User.findById(userId).select('firstName lastName').lean()
        : Promise.resolve(null),
    ]);

    const employeeName = employeeForName
      ? [employeeForName.firstName, employeeForName.lastName]
          .filter(Boolean)
          .join(' ')
          .trim()
      : '';

    const filterMeta = {
      dateRange,
      status: status || 'ALL',
      type: normalizedType || 'ALL',
      search: search || '',
      userId: userId || '',
      departmentId: departmentId || '',
      branchId: branchId || '',
      startDate: startDate || '',
      endDate: endDate || '',
      mode: exportMode,
    };

    const buffer = await buildOvertimeExcelWorkbook({
      records,
      generatedBy,
      generatedAt,
      companyName: company?.name || '',
      companyLogoUrl: company?.logoUrl || '',
      appVersion: pkg.version || '1.0.0',
      mode: exportMode,
      filters: filterMeta,
    });

    const fileName = buildOvertimeExportFileName({
      mode: exportMode,
      filters: filterMeta,
      generatedAt,
      employeeName,
    });

    await auditService.log({
      companyId: user.companyId,
      actorId: user._id,
      actorRole: user.roles?.[0],
      action: 'overtime.export_excel',
      module: 'overtime',
      resourceType: 'overtime_export',
      resourceId: null,
      metadata: {
        rowCount: records.length,
        mode: exportMode,
        fileName,
        filters: {
          status: status || 'ALL',
          type: normalizedType || 'ALL',
          search: search || null,
          userId: userId || null,
          departmentId: departmentId || null,
          branchId: branchId || null,
          startDate: startDate || null,
          endDate: endDate || null,
        },
      },
    });

    return {
      buffer,
      fileName,
      mimeType:
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      rowCount: records.length,
    };
  }

  async listMine(user, { page = 1, limit = 20, status } = {}) {
    const filter = {
      companyId: user.companyId,
      userId: user._id,
    };
    const statusFilter = mapStatusFilter(status);
    if (statusFilter) {
      filter.status = statusFilter;
    }

    const skip = (page - 1) * limit;
    const [items, total] = await Promise.all([
      OvertimeRecord.find(filter)
        .populate('userId', 'firstName lastName email roles')
        .populate('approvedBy', 'firstName lastName email')
        .populate('rejectedBy', 'firstName lastName email')
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit),
      OvertimeRecord.countDocuments(filter),
    ]);

    return {
      items: items.map((item) => this._map(item)),
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.max(1, Math.ceil(total / limit)),
      },
    };
  }

  async getById(user, auth, id) {
    const record = await this._loadWithTechnician(id, auth.companyId);
    if (!record) {
      throw new NotFoundError('Overtime session');
    }

    this._assertCanViewRecord(user, auth, record);
    return this._map(record);
  }

  async approve(user, auth, id, { reviewNotes } = {}) {
    this._assertCanApprove(auth);

    const record = await OvertimeRecord.findOne({
      _id: id,
      companyId: auth.companyId,
    });

    if (!record) {
      throw new NotFoundError('Overtime session');
    }

    if (record.status !== 'PENDING_REVIEW') {
      throw new ConflictError('Only pending overtime sessions can be approved.');
    }

    record.status = 'APPROVED';
    record.approvedBy = user._id;
    record.approvedAt = new Date();
    record.rejectedBy = null;
    record.rejectedAt = null;
    record.rejectionReason = null;
    if (reviewNotes !== undefined) {
      record.reviewNotes = reviewNotes?.trim() || null;
    }
    await record.save();

    await auditService.log({
      companyId: auth.companyId,
      actorId: user._id,
      actorRole: user.roles[0],
      action: 'overtime.approved',
      module: 'overtime',
      resourceType: 'overtime_record',
      resourceId: record._id,
      metadata: {
        requiresManualReview: !!record.requiresManualReview,
        reviewReason: record.reviewReason || null,
        reviewNotes: record.reviewNotes || null,
      },
    });

    return this._map(await this._loadWithTechnician(record._id, auth.companyId));
  }

  async reject(user, auth, id, { rejectionReason, reviewNotes } = {}) {
    this._assertCanReject(auth);

    const record = await OvertimeRecord.findOne({
      _id: id,
      companyId: auth.companyId,
    });

    if (!record) {
      throw new NotFoundError('Overtime session');
    }

    if (record.status !== 'PENDING_REVIEW') {
      throw new ConflictError('Only pending overtime sessions can be rejected.');
    }

    record.status = 'REJECTED';
    record.rejectedBy = user._id;
    record.rejectedAt = new Date();
    record.rejectionReason = rejectionReason?.trim() || null;
    if (reviewNotes !== undefined) {
      record.reviewNotes = reviewNotes?.trim() || null;
    } else if (rejectionReason?.trim()) {
      // Backward compatible: treat rejection reason as review notes when notes omitted.
      record.reviewNotes = record.reviewNotes || rejectionReason.trim();
    }
    record.approvedBy = null;
    record.approvedAt = null;
    await record.save();

    await auditService.log({
      companyId: auth.companyId,
      actorId: user._id,
      actorRole: user.roles[0],
      action: 'overtime.rejected',
      module: 'overtime',
      resourceType: 'overtime_record',
      resourceId: record._id,
      metadata: {
        rejectionReason: record.rejectionReason,
        reviewNotes: record.reviewNotes || null,
        requiresManualReview: !!record.requiresManualReview,
      },
    });

    return this._map(await this._loadWithTechnician(record._id, auth.companyId));
  }

  /**
   * Reusable aggregations for future dashboard widgets.
   * No UI consumes this yet.
   */
  async getDashboardStats(auth) {
    this._assertCanViewAll(auth);

    const companyId = new mongoose.Types.ObjectId(auth.companyId);
    const [counts, hours, byTechnician, byMonth] = await Promise.all([
      OvertimeRecord.aggregate([
        { $match: { companyId } },
        { $group: { _id: '$status', count: { $sum: 1 } } },
      ]),
      OvertimeRecord.aggregate([
        {
          $match: {
            companyId,
            status: { $in: ['APPROVED', 'PENDING_REVIEW', 'REJECTED'] },
          },
        },
        {
          $group: {
            _id: null,
            totalEligibleMinutes: { $sum: { $ifNull: ['$eligibleOvertimeMinutes', 0] } },
            totalDurationMinutes: { $sum: { $ifNull: ['$totalDurationMinutes', 0] } },
          },
        },
      ]),
      OvertimeRecord.aggregate([
        { $match: { companyId } },
        {
          $group: {
            _id: '$userId',
            sessions: { $sum: 1 },
            eligibleMinutes: { $sum: { $ifNull: ['$eligibleOvertimeMinutes', 0] } },
          },
        },
        { $sort: { eligibleMinutes: -1 } },
        { $limit: 50 },
        {
          $lookup: {
            from: 'users',
            localField: '_id',
            foreignField: '_id',
            as: 'technician',
          },
        },
        { $unwind: { path: '$technician', preserveNullAndEmptyArrays: true } },
        {
          $project: {
            userId: '$_id',
            sessions: 1,
            eligibleMinutes: 1,
            eligibleHours: { $divide: ['$eligibleMinutes', 60] },
            fullName: {
              $trim: {
                input: {
                  $concat: [
                    { $ifNull: ['$technician.firstName', ''] },
                    ' ',
                    { $ifNull: ['$technician.lastName', ''] },
                  ],
                },
              },
            },
            email: '$technician.email',
          },
        },
      ]),
      OvertimeRecord.aggregate([
        { $match: { companyId } },
        {
          $group: {
            _id: {
              year: { $year: '$createdAt' },
              month: { $month: '$createdAt' },
            },
            sessions: { $sum: 1 },
            eligibleMinutes: { $sum: { $ifNull: ['$eligibleOvertimeMinutes', 0] } },
          },
        },
        { $sort: { '_id.year': -1, '_id.month': -1 } },
        { $limit: 24 },
      ]),
    ]);

    const countMap = Object.fromEntries(counts.map((row) => [row._id, row.count]));
    const hourRow = hours[0] || { totalEligibleMinutes: 0, totalDurationMinutes: 0 };

    return {
      pendingCount: countMap.PENDING_REVIEW || 0,
      approvedCount: countMap.APPROVED || 0,
      rejectedCount: countMap.REJECTED || 0,
      runningCount: countMap.RUNNING || 0,
      cancelledCount: countMap.CANCELLED || 0,
      totalOvertimeHours: Number(((hourRow.totalEligibleMinutes || 0) / 60).toFixed(2)),
      totalDurationHours: Number(((hourRow.totalDurationMinutes || 0) / 60).toFixed(2)),
      byTechnician: byTechnician.map((row) => ({
        userId: row.userId?.toString?.() || String(row.userId),
        fullName: row.fullName || null,
        email: row.email || null,
        sessions: row.sessions,
        eligibleMinutes: row.eligibleMinutes,
        eligibleHours: Number((row.eligibleHours || 0).toFixed(2)),
      })),
      byMonth: byMonth.map((row) => ({
        year: row._id.year,
        month: row._id.month,
        sessions: row.sessions,
        eligibleMinutes: row.eligibleMinutes,
        eligibleHours: Number(((row.eligibleMinutes || 0) / 60).toFixed(2)),
      })),
    };
  }

  async _loadWithTechnician(id, companyId) {
    return OvertimeRecord.findOne({ _id: id, companyId })
      .populate('userId', 'firstName lastName email roles')
      .populate('approvedBy', 'firstName lastName email')
      .populate('rejectedBy', 'firstName lastName email');
  }

  _assertCanViewAll(auth) {
    if (!auth.permissions.includes(PERMISSIONS.OVERTIME_VIEW_ALL)) {
      throw new ForbiddenError('You do not have permission to view all overtime sessions');
    }
  }

  /** Excel export: Administrators and Supervisors only. */
  _assertCanExport(user, auth) {
    const roles = (user?.roles || []).map((role) => String(role).toUpperCase());
    const isAdminOrSupervisor =
      roles.includes('ADMIN') || roles.includes('SUPERVISOR');
    if (!isAdminOrSupervisor) {
      throw new ForbiddenError(
        'Only administrators and supervisors can export overtime reports'
      );
    }
    if (
      !auth.permissions.includes(PERMISSIONS.OVERTIME_VIEW_ALL) &&
      !auth.permissions.includes(PERMISSIONS.OVERTIME_APPROVE) &&
      !auth.permissions.includes(PERMISSIONS.OVERTIME_VIEW_TEAM)
    ) {
      throw new ForbiddenError(
        'You do not have permission to export overtime reports'
      );
    }
  }

  _assertCanApprove(auth) {
    if (!auth.permissions.includes(PERMISSIONS.OVERTIME_APPROVE)) {
      throw new ForbiddenError('You do not have permission to approve overtime');
    }
  }

  _assertCanReject(auth) {
    if (!auth.permissions.includes(PERMISSIONS.OVERTIME_REJECT)) {
      throw new ForbiddenError('You do not have permission to reject overtime');
    }
  }

  _assertCanViewRecord(user, auth, record) {
    if (auth.permissions.includes(PERMISSIONS.OVERTIME_VIEW_ALL)) {
      return;
    }

    const ownerId = record.userId?._id?.toString?.() || record.userId?.toString?.();
    if (
      auth.permissions.includes(PERMISSIONS.OVERTIME_VIEW_OWN) &&
      ownerId === user._id.toString()
    ) {
      return;
    }

    throw new ForbiddenError('You do not have permission to view this overtime session');
  }

  _mapUserSummary(userDoc) {
    if (!userDoc) {
      return null;
    }
    if (typeof userDoc === 'string' || userDoc._bsontype === 'ObjectId') {
      return { id: userDoc.toString() };
    }
    const firstName = userDoc.firstName || '';
    const lastName = userDoc.lastName || '';
    return {
      id: userDoc._id?.toString?.() || userDoc.id?.toString?.() || null,
      firstName,
      lastName,
      fullName: `${firstName} ${lastName}`.trim() || null,
      email: userDoc.email || null,
      roles: userDoc.roles || [],
    };
  }

  _mapGps(gps) {
    if (!gps) {
      return null;
    }
    return {
      latitude: gps.latitude,
      longitude: gps.longitude,
      accuracy: gps.accuracy,
      heading: gps.heading,
      speed: gps.speed,
      altitude: gps.altitude ?? null,
      provider: gps.provider,
      recordedAt: gps.recordedAt?.toISOString?.() || gps.recordedAt || null,
      fullAddress: gps.fullAddress || null,
      street: gps.street || null,
      area: gps.area || null,
      city: gps.city || null,
      country: gps.country || null,
      addressResolvedAt:
        gps.addressResolvedAt?.toISOString?.() || gps.addressResolvedAt || null,
    };
  }

  _mapVoiceNote(vn) {
    if (!vn?.url) return null;
    return {
      url: vn.url,
      publicId: vn.publicId || null,
      duration:
        typeof vn.duration === 'number' && Number.isFinite(vn.duration)
          ? vn.duration
          : null,
      size:
        typeof vn.size === 'number' && Number.isFinite(vn.size) ? vn.size : null,
      format: vn.format || null,
      uploadedAt: vn.uploadedAt?.toISOString?.() || vn.uploadedAt || null,
    };
  }

  _mapCheckpoint(cp) {
    if (!cp) return null;
    return {
      at: cp.at?.toISOString?.() || cp.at || null,
      gps: this._mapGps(cp.gps),
      photoUrl: cp.photo?.url || null,
      voiceNote: this._mapVoiceNote(cp.voiceNote),
      address: cp.address || null,
      deviceId: cp.deviceId || null,
      clientRequestId: cp.clientRequestId || null,
      accuracy: cp.gps?.accuracy ?? null,
      batteryLevel:
        cp.batteryLevel === undefined || cp.batteryLevel === null
          ? null
          : cp.batteryLevel,
      networkStatus: cp.networkStatus || null,
      notes: cp.notes || null,
    };
  }

  _mapCheckpoints(doc) {
    const cp = doc.checkpoints;
    if (!cp && !isWorkflowV2(doc)) {
      return null;
    }
    return {
      startJourney: this._mapCheckpoint(cp?.startJourney),
      arrivedAtWorkSite: this._mapCheckpoint(cp?.arrivedAtWorkSite),
      finishedWork: this._mapCheckpoint(cp?.finishedWork),
      endJourney: this._mapCheckpoint(cp?.endJourney),
    };
  }

  _map(doc) {
    const technician = this._mapUserSummary(doc.userId);
    const workflowVersion = doc.workflowVersion || WORKFLOW_V1;
    return {
      id: doc._id.toString(),
      companyId: doc.companyId.toString(),
      userId: technician?.id || doc.userId?.toString?.() || doc.userId?.toString(),
      technician,
      branchId: doc.branchId?.toString() || null,
      departmentId: doc.departmentId?.toString() || null,
      type: doc.type,
      status: doc.status,
      workflowVersion,
      checkpoints: this._mapCheckpoints(doc),
      nextCheckpoint: nextCheckpointKey(doc),
      requiresManualReview: !!doc.requiresManualReview,
      reviewReason: doc.reviewReason || null,
      reviewNotes: doc.reviewNotes || null,
      startAt: doc.startAt?.toISOString() || null,
      startGps: this._mapGps(doc.startGps),
      startPhotoUrl: doc.startPhoto?.url || null,
      startAddress: doc.startAddress,
      startDeviceId: doc.startDeviceId,
      endAt: doc.endAt?.toISOString() || null,
      endGps: this._mapGps(doc.endGps),
      endPhotoUrl: doc.endPhoto?.url || null,
      endAddress: doc.endAddress,
      endDeviceId: doc.endDeviceId,
      totalDurationMinutes: doc.totalDurationMinutes,
      workingDurationMinutes: doc.workingDurationMinutes,
      eligibleOvertimeMinutes: doc.eligibleOvertimeMinutes,
      calculationVersion: doc.calculationVersion,
      calculatedAt: doc.calculatedAt?.toISOString() || null,
      approvedBy: this._mapUserSummary(doc.approvedBy),
      approvedAt: doc.approvedAt?.toISOString() || null,
      rejectedBy: this._mapUserSummary(doc.rejectedBy),
      rejectedAt: doc.rejectedAt?.toISOString() || null,
      rejectionReason: doc.rejectionReason || null,
      createdAt: doc.createdAt?.toISOString() || null,
      updatedAt: doc.updatedAt?.toISOString() || null,
      liveElapsedSeconds:
        doc.status === 'RUNNING' && doc.startAt
          ? Math.max(0, Math.floor((Date.now() - new Date(doc.startAt).getTime()) / 1000))
          : null,
    };
  }

  /**
   * Fills reverse-geocoded address onto an existing overtime GPS snapshot.
   * point: start | end | startJourney | arrivedAtWorkSite | finishedWork | endJourney
   */
  async updateGpsAddress(user, id, body) {
    const record = await OvertimeRecord.findOne({
      _id: id,
      companyId: user.companyId,
      userId: user._id,
    });

    if (!record) {
      throw new NotFoundError('Overtime session');
    }

    const rawPoint = String(body.point || 'start').trim();
    const point = rawPoint.toLowerCase();

    const addressPatch = {
      fullAddress: body.fullAddress ? String(body.fullAddress).trim() : null,
      street: body.street ? String(body.street).trim() : null,
      area: body.area ? String(body.area).trim() : null,
      city: body.city ? String(body.city).trim() : null,
      country: body.country ? String(body.country).trim() : null,
      addressResolvedAt: body.addressResolvedAt
        ? new Date(body.addressResolvedAt)
        : new Date(),
    };

    if (!addressPatch.fullAddress && !addressPatch.city && !addressPatch.street) {
      throw new AppError('VALIDATION_ERROR', 'Resolved address fields are required', 422);
    }

    const applyToGps = (gps) => {
      if (!gps) {
        throw new AppError('VALIDATION_ERROR', 'GPS snapshot is missing', 422);
      }
      gps.fullAddress = addressPatch.fullAddress;
      gps.street = addressPatch.street;
      gps.area = addressPatch.area;
      gps.city = addressPatch.city;
      gps.country = addressPatch.country;
      gps.addressResolvedAt = addressPatch.addressResolvedAt;
    };

    const checkpointKeyMap = {
      startjourney: CHECKPOINT_STAGES.START_JOURNEY,
      arrivedatworksite: CHECKPOINT_STAGES.ARRIVED,
      finishedwork: CHECKPOINT_STAGES.FINISHED_WORK,
      endjourney: CHECKPOINT_STAGES.END_JOURNEY,
    };

    if (point === 'start' || point === 'startjourney') {
      applyToGps(record.startGps);
      record.startAddress = addressPatch.fullAddress;
      if (record.checkpoints?.startJourney) {
        applyToGps(record.checkpoints.startJourney.gps);
        record.checkpoints.startJourney.address = addressPatch.fullAddress;
        record.markModified('checkpoints');
      }
    } else if (point === 'end' || point === 'endjourney') {
      applyToGps(record.endGps);
      record.endAddress = addressPatch.fullAddress;
      if (record.checkpoints?.endJourney) {
        applyToGps(record.checkpoints.endJourney.gps);
        record.checkpoints.endJourney.address = addressPatch.fullAddress;
        record.markModified('checkpoints');
      }
    } else if (checkpointKeyMap[point.replace(/[_-]/g, '')]) {
      const key = checkpointKeyMap[point.replace(/[_-]/g, '')];
      if (!record.checkpoints?.[key]) {
        throw new AppError('VALIDATION_ERROR', `Checkpoint ${key} is missing`, 422);
      }
      applyToGps(record.checkpoints[key].gps);
      record.checkpoints[key].address = addressPatch.fullAddress;
      record.markModified('checkpoints');
    } else {
      throw new AppError(
        'VALIDATION_ERROR',
        'point must be start, end, or a checkpoint key',
        422
      );
    }

    await record.save();
    return this._map(record);
  }
}

export default new OvertimeService();
