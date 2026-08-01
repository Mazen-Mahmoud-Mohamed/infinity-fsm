import Attendance from './models/attendance.model.js';
import BreakSession from './models/breakSession.model.js';
import AttendanceEvent from './models/attendanceEvent.model.js';
import AttendanceSummary from './models/attendanceSummary.model.js';
import User from '../../core/organization/models/user.model.js';
import Team from '../../core/organization/models/team.model.js';
import { uploadSelfieBuffer } from './attendance.upload.js';
import config from '../../../config/index.js';
import AppError, {
  ConflictError,
  ForbiddenError,
  NotFoundError,
} from '../../../shared/errors/AppError.js';
import auditService from '../../core/audit/audit.service.js';
import PERMISSIONS from '../../../shared/constants/permissions.constants.js';
import mongoose from 'mongoose';

function escapeRegex(value) {
  return String(value).replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function todayDateKey(date = new Date()) {
  return date.toISOString().slice(0, 10);
}

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
    heading: body.heading !== undefined ? Number(body.heading) : null,
    speed: body.speed !== undefined ? Number(body.speed) : null,
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

  const threshold = config.attendance.gpsAccuracyThresholdMeters;
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

function diffMinutes(later, earlier) {
  return Math.max(0, Math.round((later.getTime() - earlier.getTime()) / 60000));
}

class AttendanceService {
  async clockIn(user, body, file) {
    const gps = buildGps(body);
    assertClockSkew(gps.recordedAt);
    assertGpsAccuracy(gps);

    const date = todayDateKey();

    const existingEvent = await AttendanceEvent.findOne({
      companyId: user.companyId,
      userId: user._id,
      clientEventId: body.clientEventId,
    });

    if (existingEvent) {
      const attendance = await Attendance.findById(existingEvent.attendanceId);
      return this._mapAttendance(attendance);
    }

    const existing = await Attendance.findOne({
      companyId: user.companyId,
      userId: user._id,
      date,
    });

    if (existing) {
      throw new ConflictError(
        'You have already clocked in today. Clock out before starting a new session.'
      );
    }

    if (!file) {
      throw new AppError('LIVE_PHOTO_REQUIRED', 'A selfie is required to clock in', 422);
    }

    const selfieUrl = await uploadSelfieBuffer(file.buffer, {
      userId: user._id.toString(),
      action: 'clock-in',
    });

    const at = new Date();

    const attendance = await Attendance.create({
      companyId: user.companyId,
      userId: user._id,
      branchId: user.branchId,
      departmentId: user.departmentId,
      date,
      status: 'CLOCKED_IN',
      clockIn: {
        at,
        gps,
        selfieUrl,
        deviceId: body.deviceId,
        clientEventId: body.clientEventId,
        clientRecordedAt: body.clientRecordedAt ? new Date(body.clientRecordedAt) : null,
        source: body.clientRecordedAt ? 'OFFLINE_SYNC' : 'ONLINE',
      },
    });

    await this._recordEvent(attendance, user, {
      type: 'CLOCK_IN',
      at,
      gps,
      selfieUrl,
      body,
    });

    await this._syncSummary(attendance);

    await auditService.log({
      companyId: user.companyId,
      actorId: user._id,
      actorRole: user.roles[0],
      action: 'attendance.clock_in',
      module: 'attendance',
      resourceType: 'attendance',
      resourceId: attendance._id,
      metadata: { date },
    });

    return this._mapAttendance(attendance);
  }

  async clockOut(user, body, file) {
    const gps = buildGps(body);
    assertClockSkew(gps.recordedAt);
    assertGpsAccuracy(gps);

    const date = todayDateKey();

    const attendance = await Attendance.findOne({
      companyId: user.companyId,
      userId: user._id,
      date,
    });

    if (!attendance) {
      throw new AppError(
        'NOT_CLOCKED_IN',
        'You must clock in before clocking out',
        409
      );
    }

    const existingEvent = await AttendanceEvent.findOne({
      companyId: user.companyId,
      userId: user._id,
      clientEventId: body.clientEventId,
    });

    if (existingEvent) {
      return this._mapAttendance(attendance);
    }

    if (attendance.status === 'CLOCKED_OUT') {
      throw new ConflictError('You have already clocked out today.');
    }

    if (attendance.status === 'ON_BREAK') {
      throw new AppError(
        'BREAK_ACTIVE',
        'End your current break before clocking out',
        409
      );
    }

    if (!file) {
      throw new AppError('LIVE_PHOTO_REQUIRED', 'A selfie is required to clock out', 422);
    }

    const selfieUrl = await uploadSelfieBuffer(file.buffer, {
      userId: user._id.toString(),
      action: 'clock-out',
    });

    const at = new Date();
    const workingMinutes =
      attendance.workingMinutes + diffMinutes(at, attendance.clockIn.at) - attendance.breakMinutes;

    attendance.clockOut = {
      at,
      gps,
      selfieUrl,
      deviceId: body.deviceId,
      clientEventId: body.clientEventId,
      clientRecordedAt: body.clientRecordedAt ? new Date(body.clientRecordedAt) : null,
      source: body.clientRecordedAt ? 'OFFLINE_SYNC' : 'ONLINE',
    };
    attendance.status = 'CLOCKED_OUT';
    attendance.workingMinutes = Math.max(0, workingMinutes);
    await attendance.save();

    await this._recordEvent(attendance, user, {
      type: 'CLOCK_OUT',
      at,
      gps,
      selfieUrl,
      body,
    });

    await this._syncSummary(attendance);

    await auditService.log({
      companyId: user.companyId,
      actorId: user._id,
      actorRole: user.roles[0],
      action: 'attendance.clock_out',
      module: 'attendance',
      resourceType: 'attendance',
      resourceId: attendance._id,
      metadata: { date, workingMinutes: attendance.workingMinutes },
    });

    return this._mapAttendance(attendance);
  }

  async breakStart(user, body) {
    const gps = buildGps(body);
    assertClockSkew(gps.recordedAt);
    assertGpsAccuracy(gps);

    const date = todayDateKey();

    const attendance = await Attendance.findOne({
      companyId: user.companyId,
      userId: user._id,
      date,
    });

    if (!attendance) {
      throw new AppError(
        'NOT_CLOCKED_IN',
        'You must clock in before starting a break',
        409
      );
    }

    const existingEvent = await AttendanceEvent.findOne({
      companyId: user.companyId,
      userId: user._id,
      clientEventId: body.clientEventId,
    });

    if (existingEvent) {
      return this._mapAttendance(attendance);
    }

    if (attendance.status === 'ON_BREAK') {
      throw new ConflictError('A break is already in progress.');
    }

    if (attendance.status === 'CLOCKED_OUT') {
      throw new AppError(
        'ALREADY_CLOCKED_OUT',
        'You have already clocked out today',
        409
      );
    }

    const at = new Date();

    const breakSession = await BreakSession.create({
      companyId: user.companyId,
      userId: user._id,
      attendanceId: attendance._id,
      status: 'ACTIVE',
      startAt: at,
      startGps: gps,
      startClientEventId: body.clientEventId,
    });

    attendance.status = 'ON_BREAK';
    attendance.activeBreakId = breakSession._id;
    attendance.activeBreakStartAt = at;
    attendance.breakCount += 1;
    await attendance.save();

    await this._recordEvent(attendance, user, {
      type: 'BREAK_START',
      at,
      gps,
      selfieUrl: null,
      body,
    });

    await this._syncSummary(attendance);

    return this._mapAttendance(attendance);
  }

  async breakEnd(user, body) {
    const gps = buildGps(body);
    assertClockSkew(gps.recordedAt);
    assertGpsAccuracy(gps);

    const date = todayDateKey();

    const attendance = await Attendance.findOne({
      companyId: user.companyId,
      userId: user._id,
      date,
    });

    if (!attendance) {
      throw new AppError(
        'NOT_CLOCKED_IN',
        'You must clock in before ending a break',
        409
      );
    }

    const existingEvent = await AttendanceEvent.findOne({
      companyId: user.companyId,
      userId: user._id,
      clientEventId: body.clientEventId,
    });

    if (existingEvent) {
      return this._mapAttendance(attendance);
    }

    if (attendance.status !== 'ON_BREAK' || !attendance.activeBreakId) {
      throw new AppError(
        'NO_ACTIVE_BREAK',
        'There is no active break to end',
        409
      );
    }

    const breakSession = await BreakSession.findById(attendance.activeBreakId);
    if (!breakSession) {
      throw new NotFoundError('BreakSession');
    }

    const at = new Date();
    const durationMinutes = diffMinutes(at, breakSession.startAt);

    breakSession.endAt = at;
    breakSession.endGps = gps;
    breakSession.endClientEventId = body.clientEventId;
    breakSession.durationMinutes = durationMinutes;
    breakSession.status = 'COMPLETED';
    await breakSession.save();

    attendance.status = 'CLOCKED_IN';
    attendance.activeBreakId = null;
    attendance.activeBreakStartAt = null;
    attendance.breakMinutes += durationMinutes;
    await attendance.save();

    await this._recordEvent(attendance, user, {
      type: 'BREAK_END',
      at,
      gps,
      selfieUrl: null,
      body,
    });

    await this._syncSummary(attendance);

    return this._mapAttendance(attendance);
  }

  async getStatus(user) {
    const date = todayDateKey();
    const attendance = await Attendance.findOne({
      companyId: user.companyId,
      userId: user._id,
      date,
    });

    if (!attendance) {
      return {
        status: 'NOT_STARTED',
        date,
        clockInAt: null,
        clockOutAt: null,
        workingMinutes: 0,
        breakMinutes: 0,
        breakCount: 0,
        activeBreakStartAt: null,
        liveWorkingSeconds: 0,
        serverTime: new Date().toISOString(),
      };
    }

    return this._mapStatus(attendance);
  }

  async getToday(user) {
    const date = todayDateKey();
    const attendance = await Attendance.findOne({
      companyId: user.companyId,
      userId: user._id,
      date,
    });

    if (!attendance) {
      return { attendance: null, events: [], breakSessions: [] };
    }

    const [events, breakSessions] = await Promise.all([
      AttendanceEvent.find({ attendanceId: attendance._id }).sort({ at: 1 }),
      BreakSession.find({ attendanceId: attendance._id }).sort({ startAt: 1 }),
    ]);

    return {
      attendance: this._mapAttendance(attendance),
      events: events.map((event) => this._mapEvent(event)),
      breakSessions: breakSessions.map((session) => this._mapBreakSession(session)),
    };
  }

  async getHistory(user, { page = 1, limit = 20, startDate, endDate } = {}) {
    const filter = { companyId: user.companyId, userId: user._id };

    if (startDate || endDate) {
      filter.date = {};
      if (startDate) {
        filter.date.$gte = startDate.slice(0, 10);
      }
      if (endDate) {
        filter.date.$lte = endDate.slice(0, 10);
      }
    }

    const skip = (page - 1) * limit;

    const [items, total] = await Promise.all([
      AttendanceSummary.find(filter).sort({ date: -1 }).skip(skip).limit(limit),
      AttendanceSummary.countDocuments(filter),
    ]);

    return {
      items: items.map((item) => this._mapSummary(item)),
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.max(1, Math.ceil(total / limit)),
      },
    };
  }

  /**
   * Company/team attendance list for managers (additive endpoint).
   * Does not change personal history/clock behavior.
   */
  async listRecords(user, auth, {
    page = 1,
    limit = 20,
    status,
    search,
    startDate,
    endDate,
    userId,
    role,
  } = {}) {
    const filter = { companyId: new mongoose.Types.ObjectId(auth.companyId) };
    const scopedUserIds = await this._resolveViewableUserIds(user, auth);
    if (scopedUserIds) {
      filter.userId = { $in: scopedUserIds };
    }

    if (userId) {
      const requested = new mongoose.Types.ObjectId(userId);
      if (scopedUserIds && !scopedUserIds.some((id) => String(id) === String(requested))) {
        throw new ForbiddenError('You cannot view this employee attendance');
      }
      filter.userId = requested;
    }

    if (status) {
      filter.status = String(status).toUpperCase();
    }

    if (startDate || endDate) {
      filter.date = {};
      if (startDate) filter.date.$gte = String(startDate).slice(0, 10);
      if (endDate) filter.date.$lte = String(endDate).slice(0, 10);
    }

    let employeeIdsForSearch = null;
    if ((search && String(search).trim()) || role) {
      const userFilter = {
        companyId: auth.companyId,
        deletedAt: null,
      };
      if (search && String(search).trim()) {
        const term = escapeRegex(String(search).trim());
        userFilter.$or = [
          { firstName: { $regex: term, $options: 'i' } },
          { lastName: { $regex: term, $options: 'i' } },
          { email: { $regex: term, $options: 'i' } },
          { fullName: { $regex: term, $options: 'i' } },
        ];
      }
      if (role) {
        userFilter.roles = String(role).toUpperCase();
      }
      const matchingUsers = await User.find(userFilter).select('_id').lean();
      employeeIdsForSearch = matchingUsers.map((item) => item._id);
      if (filter.userId?.$in) {
        const allowed = new Set(filter.userId.$in.map(String));
        employeeIdsForSearch = employeeIdsForSearch.filter((id) =>
          allowed.has(String(id))
        );
      } else if (filter.userId && !filter.userId.$in) {
        employeeIdsForSearch = employeeIdsForSearch.filter(
          (id) => String(id) === String(filter.userId)
        );
      }
      filter.userId = { $in: employeeIdsForSearch };
    }

    const skip = (page - 1) * limit;
    const [items, total] = await Promise.all([
      Attendance.find(filter)
        .populate('userId', 'firstName lastName fullName email roles avatarUrl')
        .sort({ date: -1, updatedAt: -1 })
        .skip(skip)
        .limit(limit)
        .lean(),
      Attendance.countDocuments(filter),
    ]);

    return {
      items: items.map((item) => this._mapAttendanceListItem(item)),
      pagination: {
        page: Number(page),
        limit: Number(limit),
        total,
        totalPages: Math.max(1, Math.ceil(total / limit)),
      },
    };
  }

  async getRecordById(user, auth, id) {
    const attendance = await Attendance.findOne({
      _id: id,
      companyId: auth.companyId,
    })
      .populate('userId', 'firstName lastName fullName email roles avatarUrl')
      .lean();

    if (!attendance) {
      throw new NotFoundError('Attendance record');
    }

    await this._assertCanViewAttendanceRecord(user, auth, attendance);

    const [events, breakSessions] = await Promise.all([
      AttendanceEvent.find({ attendanceId: attendance._id }).sort({ at: 1 }).lean(),
      BreakSession.find({ attendanceId: attendance._id }).sort({ startAt: 1 }).lean(),
    ]);

    return {
      attendance: this._mapAttendanceListItem(attendance),
      events: events.map((event) => this._mapEvent(event)),
      breakSessions: breakSessions.map((session) => this._mapBreakSession(session)),
    };
  }

  async _resolveViewableUserIds(user, auth) {
    const permissions = auth.permissions || [];
    if (permissions.includes(PERMISSIONS.ATTENDANCE_VIEW_ALL)) {
      return null;
    }
    if (!permissions.includes(PERMISSIONS.ATTENDANCE_VIEW_TEAM)) {
      throw new ForbiddenError('Attendance view permission required');
    }

    const companyId = new mongoose.Types.ObjectId(auth.companyId);
    const userId = new mongoose.Types.ObjectId(auth.userId);

    const [self, ledTeams] = await Promise.all([
      User.findOne({ _id: userId, companyId, deletedAt: null })
        .select('teamId departmentId')
        .lean(),
      Team.find({ companyId, leadId: userId, deletedAt: null, isActive: true })
        .select('_id')
        .lean(),
    ]);

    const teamIds = new Set();
    if (self?.teamId) teamIds.add(String(self.teamId));
    for (const team of ledTeams) {
      teamIds.add(String(team._id));
    }

    let members = [];
    if (teamIds.size > 0) {
      members = await User.find({
        companyId,
        deletedAt: null,
        teamId: { $in: [...teamIds].map((id) => new mongoose.Types.ObjectId(id)) },
      })
        .select('_id')
        .lean();
    } else if (self?.departmentId) {
      members = await User.find({
        companyId,
        deletedAt: null,
        departmentId: self.departmentId,
      })
        .select('_id')
        .lean();
    }

    const memberIds = members.map((m) => m._id);
    if (!memberIds.some((id) => String(id) === String(userId))) {
      memberIds.push(userId);
    }
    return memberIds;
  }

  async _assertCanViewAttendanceRecord(user, auth, attendance) {
    const permissions = auth.permissions || [];
    if (permissions.includes(PERMISSIONS.ATTENDANCE_VIEW_ALL)) {
      return;
    }

    const recordUserId =
      attendance.userId?._id?.toString?.() ||
      attendance.userId?.toString?.() ||
      String(attendance.userId);

    if (
      permissions.includes(PERMISSIONS.ATTENDANCE_VIEW_OWN) &&
      recordUserId === String(auth.userId)
    ) {
      return;
    }

    if (permissions.includes(PERMISSIONS.ATTENDANCE_VIEW_TEAM)) {
      const scoped = await this._resolveViewableUserIds(user, auth);
      if (scoped?.some((id) => String(id) === recordUserId)) {
        return;
      }
    }

    throw new ForbiddenError('You cannot view this attendance record');
  }

  _mapEmployee(userDoc) {
    if (!userDoc || typeof userDoc !== 'object' || !userDoc._id) {
      return null;
    }
    const firstName = userDoc.firstName || '';
    const lastName = userDoc.lastName || '';
    const fullName =
      userDoc.fullName ||
      [firstName, lastName].filter(Boolean).join(' ').trim() ||
      userDoc.email ||
      '';
    return {
      id: userDoc._id.toString(),
      firstName,
      lastName,
      fullName,
      email: userDoc.email || null,
      roles: Array.isArray(userDoc.roles) ? userDoc.roles : [],
      avatarUrl: userDoc.avatarUrl || null,
    };
  }

  _mapAttendanceListItem(attendance) {
    const base = this._mapAttendance(attendance);
    const employee = this._mapEmployee(attendance.userId);
    return {
      ...base,
      userId:
        employee?.id ||
        attendance.userId?._id?.toString?.() ||
        attendance.userId?.toString?.() ||
        null,
      employee,
    };
  }

  async _recordEvent(attendance, user, { type, at, gps, selfieUrl, body }) {
    return AttendanceEvent.create({
      companyId: user.companyId,
      userId: user._id,
      attendanceId: attendance._id,
      type,
      at,
      clientEventId: body.clientEventId,
      clientRecordedAt: body.clientRecordedAt ? new Date(body.clientRecordedAt) : null,
      gps,
      selfieUrl,
      deviceId: body.deviceId,
      source: body.clientRecordedAt ? 'OFFLINE_SYNC' : 'ONLINE',
    });
  }

  async _syncSummary(attendance) {
    await AttendanceSummary.findOneAndUpdate(
      {
        companyId: attendance.companyId,
        userId: attendance.userId,
        date: attendance.date,
      },
      {
        attendanceId: attendance._id,
        status: attendance.status,
        clockInAt: attendance.clockIn?.at || null,
        clockOutAt: attendance.clockOut?.at || null,
        workingMinutes: attendance.workingMinutes,
        breakMinutes: attendance.breakMinutes,
        breakCount: attendance.breakCount,
      },
      { upsert: true, new: true, setDefaultsOnInsert: true }
    );
  }

  _mapStatus(attendance) {
    const now = Date.now();
    let liveWorkingSeconds = attendance.workingMinutes * 60;

    if (attendance.status === 'CLOCKED_IN') {
      const elapsedSeconds = Math.floor((now - attendance.clockIn.at.getTime()) / 1000);
      liveWorkingSeconds = elapsedSeconds - attendance.breakMinutes * 60;
    } else if (attendance.status === 'ON_BREAK' && attendance.activeBreakStartAt) {
      const elapsedSeconds = Math.floor((now - attendance.clockIn.at.getTime()) / 1000);
      const activeBreakSeconds = Math.floor(
        (now - attendance.activeBreakStartAt.getTime()) / 1000
      );
      liveWorkingSeconds =
        elapsedSeconds - attendance.breakMinutes * 60 - activeBreakSeconds;
    }

    return {
      status: attendance.status,
      date: attendance.date,
      clockInAt: attendance.clockIn?.at?.toISOString() || null,
      clockOutAt: attendance.clockOut?.at?.toISOString() || null,
      workingMinutes: attendance.workingMinutes,
      breakMinutes: attendance.breakMinutes,
      breakCount: attendance.breakCount,
      activeBreakStartAt: attendance.activeBreakStartAt?.toISOString() || null,
      liveWorkingSeconds: Math.max(0, liveWorkingSeconds),
      serverTime: new Date().toISOString(),
    };
  }

  _mapAttendance(attendance) {
    const createdAt = attendance.createdAt;
    const updatedAt = attendance.updatedAt;
    return {
      id: attendance._id.toString(),
      date: attendance.date,
      status: attendance.status,
      clockIn: attendance.clockIn ? this._mapActionRecord(attendance.clockIn) : null,
      clockOut: attendance.clockOut ? this._mapActionRecord(attendance.clockOut) : null,
      breakCount: attendance.breakCount,
      breakMinutes: attendance.breakMinutes,
      workingMinutes: attendance.workingMinutes,
      createdAt:
        createdAt instanceof Date
          ? createdAt.toISOString()
          : createdAt || null,
      updatedAt:
        updatedAt instanceof Date
          ? updatedAt.toISOString()
          : updatedAt || null,
    };
  }

  _mapActionRecord(record) {
    const at = record.at;
    return {
      at: at instanceof Date ? at.toISOString() : at || null,
      gps: this._mapGps(record.gps),
      selfieUrl: record.selfieUrl,
      deviceId: record.deviceId,
      source: record.source,
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
      recordedAt: gps.recordedAt?.toISOString() || null,
      fullAddress: gps.fullAddress || null,
      street: gps.street || null,
      area: gps.area || null,
      city: gps.city || null,
      country: gps.country || null,
      addressResolvedAt: gps.addressResolvedAt?.toISOString?.() || null,
    };
  }

  _mapEvent(event) {
    return {
      id: event._id.toString(),
      type: event.type,
      at: event.at?.toISOString() || null,
      gps: this._mapGps(event.gps),
      selfieUrl: event.selfieUrl,
      deviceId: event.deviceId,
      source: event.source,
    };
  }

  _mapBreakSession(session) {
    return {
      id: session._id.toString(),
      status: session.status,
      startAt: session.startAt?.toISOString() || null,
      endAt: session.endAt?.toISOString() || null,
      durationMinutes: session.durationMinutes,
    };
  }

  _mapSummary(summary) {
    return {
      id: summary._id.toString(),
      date: summary.date,
      status: summary.status,
      clockInAt: summary.clockInAt?.toISOString() || null,
      clockOutAt: summary.clockOutAt?.toISOString() || null,
      workingMinutes: summary.workingMinutes,
      breakMinutes: summary.breakMinutes,
      breakCount: summary.breakCount,
    };
  }

  /**
   * Fills reverse-geocoded address onto an existing attendance GPS snapshot.
   * Used after offline sync when address resolution was deferred.
   */
  async updateGpsAddress(user, body) {
    const clientEventId = body.clientEventId;
    if (!clientEventId) {
      throw new AppError('VALIDATION_ERROR', 'clientEventId is required', 422);
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

    const event = await AttendanceEvent.findOne({
      companyId: user.companyId,
      userId: user._id,
      clientEventId,
    }).lean();

    if (!event) {
      throw new NotFoundError('Attendance event');
    }

    // Events are otherwise immutable — allow address enrichment only via collection API.
    await AttendanceEvent.collection.updateOne(
      { _id: event._id },
      {
        $set: {
          'gps.fullAddress': addressPatch.fullAddress,
          'gps.street': addressPatch.street,
          'gps.area': addressPatch.area,
          'gps.city': addressPatch.city,
          'gps.country': addressPatch.country,
          'gps.addressResolvedAt': addressPatch.addressResolvedAt,
        },
      }
    );

    const attendance = await Attendance.findOne({
      _id: event.attendanceId,
      companyId: user.companyId,
      userId: user._id,
    });

    if (attendance) {
      const applyToRecord = (record) => {
        if (!record?.gps || record.clientEventId !== clientEventId) {
          return false;
        }
        record.gps.fullAddress = addressPatch.fullAddress;
        record.gps.street = addressPatch.street;
        record.gps.area = addressPatch.area;
        record.gps.city = addressPatch.city;
        record.gps.country = addressPatch.country;
        record.gps.addressResolvedAt = addressPatch.addressResolvedAt;
        return true;
      };

      applyToRecord(attendance.clockIn);
      applyToRecord(attendance.clockOut);
      await attendance.save();
    }

    return {
      clientEventId,
      gps: {
        ...this._mapGps(event.gps),
        ...addressPatch,
        addressResolvedAt: addressPatch.addressResolvedAt.toISOString(),
      },
    };
  }
}

export default new AttendanceService();
