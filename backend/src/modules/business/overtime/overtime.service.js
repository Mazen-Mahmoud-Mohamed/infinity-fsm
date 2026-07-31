import mongoose from 'mongoose';
import OvertimeRecord from './models/overtimeRecord.model.js';
import { uploadOvertimePhotoBuffer } from './overtime.upload.js';
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

function assertClockSkew(recordedAt) {
  if (!recordedAt) return;
  const skewSeconds = config.security.maxDeviceClockSkewSeconds;
  const deltaMs = Math.abs(Date.now() - new Date(recordedAt).getTime());
  if (deltaMs > skewSeconds * 1000) {
    throw new AppError(
      'CLOCK_SKEW',
      'Device time appears to be incorrect',
      422
    );
  }
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

class OvertimeService {
  async getRunning(user) {
    const record = await OvertimeRecord.findOne({
      companyId: user.companyId,
      userId: user._id,
      status: 'RUNNING',
    });

    return record ? this._map(record) : null;
  }

  async start(user, body, file) {
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
    assertClockSkew(gps.recordedAt);
    assertGpsAccuracy(gps);

    const photo = await uploadOvertimePhotoBuffer(file.buffer, {
      userId: user._id.toString(),
      photoType: 'start',
    });

    const { startedAt: startAt } = resolveSessionTimeline({
      body,
      fallbackStartAt: new Date(),
    });

    const record = await OvertimeRecord.create({
      companyId: user.companyId,
      userId: user._id,
      branchId: user.branchId,
      departmentId: user.departmentId,
      type,
      status: 'RUNNING',
      startAt,
      startGps: gps,
      startPhoto: photo,
      startAddress: body.address || body.fullAddress || null,
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
      metadata: { type },
    });

    return this._map(record);
  }

  async end(user, id, body, file) {
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

    if (record.status !== 'RUNNING') {
      throw new ConflictError(
        `Cannot end a session that is already ${record.status.toLowerCase()}`
      );
    }

    if (!file) {
      throw new AppError('LIVE_PHOTO_REQUIRED', 'An end photo is required', 422);
    }

    if (!body.deviceId) {
      throw new AppError('DEVICE_REQUIRED', 'deviceId is required', 422);
    }

    const gps = buildGps(body);
    assertClockSkew(gps.recordedAt);
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

    if (!assertReasonableSessionLength(startedAt, endedAt, config.overtime.maxSessionHours)) {
      throw new AppError(
        'SESSION_TOO_LONG',
        `Overtime session exceeds the maximum of ${config.overtime.maxSessionHours} hours.`,
        422
      );
    }

    const photo = await uploadOvertimePhotoBuffer(file.buffer, {
      userId: user._id.toString(),
      photoType: 'end',
    });

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

  async approve(user, auth, id) {
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
    await record.save();

    await auditService.log({
      companyId: auth.companyId,
      actorId: user._id,
      actorRole: user.roles[0],
      action: 'overtime.approved',
      module: 'overtime',
      resourceType: 'overtime_record',
      resourceId: record._id,
    });

    return this._map(await this._loadWithTechnician(record._id, auth.companyId));
  }

  async reject(user, auth, id, { rejectionReason } = {}) {
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
      metadata: { rejectionReason: record.rejectionReason },
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

  _map(doc) {
    const technician = this._mapUserSummary(doc.userId);
    return {
      id: doc._id.toString(),
      companyId: doc.companyId.toString(),
      userId: technician?.id || doc.userId?.toString?.() || doc.userId?.toString(),
      technician,
      branchId: doc.branchId?.toString() || null,
      departmentId: doc.departmentId?.toString() || null,
      type: doc.type,
      status: doc.status,
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
   * point: 'start' | 'end'
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

    const point = String(body.point || 'start').toLowerCase();
    if (point !== 'start' && point !== 'end') {
      throw new AppError('VALIDATION_ERROR', 'point must be start or end', 422);
    }

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

    if (point === 'start') {
      if (!record.startGps) {
        throw new AppError('VALIDATION_ERROR', 'Start GPS is missing', 422);
      }
      record.startGps.fullAddress = addressPatch.fullAddress;
      record.startGps.street = addressPatch.street;
      record.startGps.area = addressPatch.area;
      record.startGps.city = addressPatch.city;
      record.startGps.country = addressPatch.country;
      record.startGps.addressResolvedAt = addressPatch.addressResolvedAt;
      record.startAddress = addressPatch.fullAddress;
    } else {
      if (!record.endGps) {
        throw new AppError('VALIDATION_ERROR', 'End GPS is missing', 422);
      }
      record.endGps.fullAddress = addressPatch.fullAddress;
      record.endGps.street = addressPatch.street;
      record.endGps.area = addressPatch.area;
      record.endGps.city = addressPatch.city;
      record.endGps.country = addressPatch.country;
      record.endGps.addressResolvedAt = addressPatch.addressResolvedAt;
      record.endAddress = addressPatch.fullAddress;
    }

    await record.save();
    return this._map(record);
  }
}

export default new OvertimeService();
