import mongoose from 'mongoose';
import User from '../organization/models/user.model.js';
import Team from '../organization/models/team.model.js';
import Attendance from '../../business/attendance/models/attendance.model.js';
import OvertimeRecord from '../../business/overtime/models/overtimeRecord.model.js';
import WorkOrder from '../../business/work-orders/models/workOrder.model.js';
import MaintenanceSchedule from '../../business/preventive-maintenance/models/maintenanceSchedule.model.js';
import MaintenancePlan from '../../business/preventive-maintenance/models/maintenancePlan.model.js';
import SparePart from '../../business/inventory/models/sparePart.model.js';
import StockMovement from '../../business/inventory/models/stockMovement.model.js';
import Asset from '../../business/assets/models/asset.model.js';
import AuditLog from '../audit/models/auditLog.model.js';
import { ROLES } from '../../../shared/constants/roles.constants.js';
import { ValidationError } from '../../../shared/errors/AppError.js';
import {
  getZonedParts,
  splitSessionMinutesAcrossCalendarDays,
  zonedLocalToUtc,
} from '../../business/overtime/overtime.calculation.js';
import { OFFICIAL_WORKING_HOURS } from '../../business/overtime/working-hours.policy.js';

const COMPANY_TZ = OFFICIAL_WORKING_HOURS.timeZone;

function otMinutesExpr() {
  // Prefer approvedHours (decimal hours → minutes); fallback to eligible OT.
  return {
    $cond: [
      {
        $and: [
          { $ne: [{ $ifNull: ['$approvedHours', null] }, null] },
          { $ne: ['$approvedHours', ''] },
        ],
      },
      {
        $multiply: [{ $toDouble: { $ifNull: ['$approvedHours', 0] } }, 60],
      },
      { $ifNull: ['$eligibleOvertimeMinutes', 0] },
    ],
  };
}

function addCairoCalendarDays(year, month, day, daysToAdd) {
  const utc = new Date(Date.UTC(year, month - 1, day, 12, 0, 0));
  utc.setUTCDate(utc.getUTCDate() + daysToAdd);
  return {
    year: utc.getUTCFullYear(),
    month: utc.getUTCMonth() + 1,
    day: utc.getUTCDate(),
  };
}

/** Start of calendar day in Africa/Cairo (absolute UTC instant). */
function startOfDay(date) {
  const parts = getZonedParts(new Date(date), COMPANY_TZ);
  return zonedLocalToUtc(
    COMPANY_TZ,
    parts.year,
    parts.month,
    parts.day,
    0,
    0,
    0
  );
}

/** Inclusive end of calendar day in Africa/Cairo. */
function endOfDay(date) {
  const parts = getZonedParts(new Date(date), COMPANY_TZ);
  const next = addCairoCalendarDays(parts.year, parts.month, parts.day, 1);
  const nextMidnight = zonedLocalToUtc(
    COMPANY_TZ,
    next.year,
    next.month,
    next.day,
    0,
    0,
    0
  );
  return new Date(nextMidnight.getTime() - 1);
}

function toHours(minutes) {
  if (minutes == null || Number.isNaN(Number(minutes))) return 0;
  return Math.round((Number(minutes) / 60) * 10) / 10;
}

/** Approved / eligible minutes for a single overtime record (matches otMinutesExpr). */
function overtimeRecordTrendMinutes(record) {
  const approved = record?.approvedHours;
  if (approved != null && approved !== '') {
    return Math.floor(Number(approved) * 60);
  }
  return Math.floor(Number(record?.eligibleOvertimeMinutes) || 0);
}

/**
 * Build daily overtime trend buckets by splitting each session across the
 * calendar days it actually spans (Africa/Cairo), instead of attributing all
 * minutes to startAt's date.
 */
function buildOvertimeTrendDayMap(records) {
  /** @type {Record<string, number>} */
  const otMap = {};

  for (const record of records) {
    const startAt = record?.startAt ? new Date(record.startAt) : null;
    const endAt = record?.endAt ? new Date(record.endAt) : null;
    const totalMinutes = overtimeRecordTrendMinutes(record);

    if (
      !startAt ||
      !endAt ||
      Number.isNaN(startAt.getTime()) ||
      Number.isNaN(endAt.getTime()) ||
      endAt.getTime() <= startAt.getTime() ||
      totalMinutes <= 0
    ) {
      continue;
    }

    const dayBuckets = splitSessionMinutesAcrossCalendarDays(
      startAt,
      endAt,
      totalMinutes,
      COMPANY_TZ
    );

    for (const [key, minutes] of Object.entries(dayBuckets)) {
      otMap[key] = (otMap[key] || 0) + minutes;
    }
  }

  return otMap;
}

function resolvePeriod(query = {}) {
  const period = String(query.period || 'month').toLowerCase();
  const now = new Date();

  if (period === 'custom') {
    if (!query.from || !query.to) {
      throw new ValidationError([
        {
          field: 'from/to',
          message: 'Custom period requires from and to ISO dates',
        },
      ]);
    }
    const from = startOfDay(new Date(query.from));
    const to = endOfDay(new Date(query.to));
    if (Number.isNaN(from.getTime()) || Number.isNaN(to.getTime()) || from > to) {
      throw new ValidationError([
        { field: 'from/to', message: 'Invalid custom date range' },
      ]);
    }
    return { period: 'custom', from, to };
  }

  if (period === 'today') {
    return { period: 'today', from: startOfDay(now), to: endOfDay(now) };
  }

  if (period === 'week') {
    // ISO business week starting Monday in Africa/Cairo.
    const todayStart = startOfDay(now);
    const weekdayShort = new Intl.DateTimeFormat('en-US', {
      timeZone: COMPANY_TZ,
      weekday: 'short',
    }).format(todayStart);
    const mondayOffset = {
      Mon: 0,
      Tue: 1,
      Wed: 2,
      Thu: 3,
      Fri: 4,
      Sat: 5,
      Sun: 6,
    }[weekdayShort] ?? 0;

    const parts = getZonedParts(todayStart, COMPANY_TZ);
    const monday = addCairoCalendarDays(
      parts.year,
      parts.month,
      parts.day,
      -mondayOffset
    );
    const from = zonedLocalToUtc(
      COMPANY_TZ,
      monday.year,
      monday.month,
      monday.day,
      0,
      0,
      0
    );
    return { period: 'week', from, to: endOfDay(now) };
  }

  if (period === 'year') {
    const parts = getZonedParts(now, COMPANY_TZ);
    const from = zonedLocalToUtc(COMPANY_TZ, parts.year, 1, 1, 0, 0, 0);
    return { period: 'year', from, to: endOfDay(now) };
  }

  // Calendar month-to-date in Africa/Cairo (default)
  const parts = getZonedParts(now, COMPANY_TZ);
  const from = zonedLocalToUtc(COMPANY_TZ, parts.year, parts.month, 1, 0, 0, 0);
  return { period: 'month', from, to: endOfDay(now) };
}

function resolveViewRole(roles = []) {
  const normalized = roles.map((r) => String(r).toUpperCase());
  if (normalized.includes(ROLES.ADMIN) || normalized.includes('ADMIN')) {
    return 'admin';
  }
  if (normalized.includes(ROLES.SUPERVISOR) || normalized.includes('SUPERVISOR')) {
    return 'supervisor';
  }
  return 'technician';
}

function dateKey(date) {
  const parts = getZonedParts(new Date(date), COMPANY_TZ);
  const m = String(parts.month).padStart(2, '0');
  const d = String(parts.day).padStart(2, '0');
  return `${parts.year}-${m}-${d}`;
}

function buildTrendBuckets(from, to) {
  const buckets = [];
  const fromDay = startOfDay(from);
  const toDay = startOfDay(to);
  const spanDays = Math.max(
    1,
    Math.round((toDay.getTime() - fromDay.getTime()) / 86400000) + 1
  );
  const days = Math.min(31, spanDays);

  let cursorParts = getZonedParts(toDay, COMPANY_TZ);
  cursorParts = addCairoCalendarDays(
    cursorParts.year,
    cursorParts.month,
    cursorParts.day,
    -(days - 1)
  );
  const fromKey = dateKey(fromDay);

  for (let i = 0; i < days; i += 1) {
    const cursor = zonedLocalToUtc(
      COMPANY_TZ,
      cursorParts.year,
      cursorParts.month,
      cursorParts.day,
      0,
      0,
      0
    );
    const key = dateKey(cursor);
    if (key >= fromKey) {
      buckets.push({
        key,
        label: `${cursorParts.month}/${cursorParts.day}`,
        from: cursor,
        to: endOfDay(cursor),
      });
    }
    cursorParts = addCairoCalendarDays(
      cursorParts.year,
      cursorParts.month,
      cursorParts.day,
      1
    );
  }

  return buckets;
}

class DashboardService {
  async getSummary(auth, query = {}) {
    const companyId = new mongoose.Types.ObjectId(auth.companyId);
    const userId = new mongoose.Types.ObjectId(auth.userId);
    const viewRole = resolveViewRole(auth.roles || []);
    const { period, from, to } = resolvePeriod(query);

    const scope = await this._resolveScope({
      companyId,
      userId,
      viewRole,
    });

    if (viewRole === 'admin') {
      const data = await this._buildAdminSummary({ companyId, from, to, period });
      return { viewRole, period, from: from.toISOString(), to: to.toISOString(), ...data };
    }

    if (viewRole === 'supervisor') {
      const data = await this._buildSupervisorSummary({
        companyId,
        memberIds: scope.memberIds,
        from,
        to,
        period,
      });
      return {
        viewRole,
        period,
        from: from.toISOString(),
        to: to.toISOString(),
        teamSize: scope.memberIds.length,
        ...data,
      };
    }

    const data = await this._buildTechnicianSummary({
      companyId,
      userId,
      from,
      to,
      period,
    });
    return { viewRole, period, from: from.toISOString(), to: to.toISOString(), ...data };
  }

  async _resolveScope({ companyId, userId, viewRole }) {
    if (viewRole === 'admin') {
      return { memberIds: null };
    }
    if (viewRole === 'technician') {
      return { memberIds: [userId] };
    }

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
    return { memberIds };
  }

  async _buildAdminSummary({ companyId, from, to, period }) {
    const userBase = { companyId, deletedAt: null };
    const attendanceBase = {
      companyId,
      createdAt: { $gte: from, $lte: to },
    };
    const overtimeBase = {
      companyId,
      startAt: { $gte: from, $lte: to },
    };
    const woBase = {
      companyId,
      deletedAt: null,
      createdAt: { $gte: from, $lte: to },
    };
    const pmBase = {
      companyId,
      scheduledDate: { $gte: from, $lte: to },
    };

    const [
      totalEmployees,
      activeEmployees,
      currentlyWorking,
      onOvertime,
      onTravelOvertime,
      attendanceAgg,
      presentDays,
      expectedWorkDays,
      overtimeTotals,
      topOvertime,
      travelOtMinutesAgg,
      woByStatus,
      pmByStatus,
      lowStock,
      outOfStock,
      recentMovements,
      assetsByStatus,
      liveActivity,
      trends,
    ] = await Promise.all([
      User.countDocuments(userBase),
      User.countDocuments({ ...userBase, isActive: true }),
      Attendance.countDocuments({
        companyId,
        status: { $in: ['CLOCKED_IN', 'ON_BREAK'] },
        date: dateKey(new Date()),
      }),
      OvertimeRecord.countDocuments({
        companyId,
        status: 'RUNNING',
      }),
      OvertimeRecord.countDocuments({
        companyId,
        status: 'RUNNING',
        type: 'TRAVEL',
      }),
      Attendance.aggregate([
        { $match: attendanceBase },
        {
          $group: {
            _id: null,
            totalMinutes: { $sum: { $ifNull: ['$workingMinutes', 0] } },
            records: { $sum: 1 },
            users: { $addToSet: '$userId' },
          },
        },
      ]),
      Attendance.distinct('userId', {
        companyId,
        createdAt: { $gte: from, $lte: to },
        status: { $in: ['CLOCKED_IN', 'ON_BREAK', 'CLOCKED_OUT'] },
      }),
      User.countDocuments({ ...userBase, isActive: true }),
      OvertimeRecord.aggregate([
        { $match: overtimeBase },
        {
          $group: {
            _id: null,
            minutes: { $sum: otMinutesExpr() },
            trips: { $sum: 1 },
            overnightTrips: {
              $sum: { $cond: [{ $eq: ['$isOvernight', true] }, 1, 0] },
            },
            technicians: { $addToSet: '$userId' },
          },
        },
      ]),
      OvertimeRecord.aggregate([
        { $match: overtimeBase },
        {
          $group: {
            _id: '$userId',
            minutes: { $sum: otMinutesExpr() },
            trips: { $sum: 1 },
            overnightTrips: {
              $sum: { $cond: [{ $eq: ['$isOvernight', true] }, 1, 0] },
            },
          },
        },
        { $sort: { minutes: -1 } },
        { $limit: 20 },
        {
          $lookup: {
            from: 'users',
            localField: '_id',
            foreignField: '_id',
            as: 'user',
          },
        },
        { $unwind: { path: '$user', preserveNullAndEmptyArrays: true } },
        {
          $project: {
            userId: '$_id',
            minutes: 1,
            trips: 1,
            overnightTrips: 1,
            fullName: {
              $ifNull: [
                '$user.fullName',
                {
                  $trim: {
                    input: {
                      $concat: [
                        { $ifNull: ['$user.firstName', ''] },
                        ' ',
                        { $ifNull: ['$user.lastName', ''] },
                      ],
                    },
                  },
                },
              ],
            },
          },
        },
      ]),
      OvertimeRecord.aggregate([
        { $match: { ...overtimeBase, type: 'TRAVEL' } },
        {
          $group: {
            _id: null,
            minutes: { $sum: otMinutesExpr() },
          },
        },
      ]),
      WorkOrder.aggregate([
        { $match: woBase },
        { $group: { _id: '$status', count: { $sum: 1 } } },
      ]),
      MaintenanceSchedule.aggregate([
        { $match: pmBase },
        { $group: { _id: '$status', count: { $sum: 1 } } },
      ]),
      SparePart.countDocuments({
        companyId,
        deletedAt: null,
        isActive: true,
        $expr: {
          $and: [
            { $gt: ['$currentQuantity', 0] },
            { $lte: ['$currentQuantity', '$minimumQuantity'] },
          ],
        },
      }),
      SparePart.countDocuments({
        companyId,
        deletedAt: null,
        isActive: true,
        currentQuantity: { $lte: 0 },
      }),
      StockMovement.find({ companyId })
        .sort({ movementDate: -1, createdAt: -1 })
        .limit(5)
        .select('type quantity quantityDelta createdAt movementDate sparePartId')
        .populate('sparePartId', 'name partNumber')
        .lean(),
      Asset.aggregate([
        { $match: { companyId, deletedAt: null } },
        { $group: { _id: '$status', count: { $sum: 1 } } },
      ]),
      this._liveActivity(companyId, null),
      this._buildTrends({ companyId, userIds: null, from, to }),
    ]);

    const att = attendanceAgg[0] || { totalMinutes: 0, records: 0, users: [] };
    const presentCount = presentDays.length;
    const expected = Math.max(expectedWorkDays, 1);
    const daySpan = Math.max(
      1,
      Math.ceil((to.getTime() - from.getTime()) / (24 * 60 * 60 * 1000)) + 1
    );
    const attendanceRate = Math.round(
      (presentCount / (expected * Math.min(daySpan, 31))) * 1000
    ) / 10;

    const otRow = overtimeTotals[0] || {
      minutes: 0,
      trips: 0,
      overnightTrips: 0,
      technicians: [],
    };
    const otTotalMinutes = otRow.minutes || 0;
    const totalTrips = otRow.trips || 0;
    const overnightTrips = otRow.overnightTrips || 0;
    const totalTechnicians = Array.isArray(otRow.technicians)
      ? otRow.technicians.length
      : 0;
    const otTravel = travelOtMinutesAgg[0]?.minutes || 0;

    const technicianRows = topOvertime.map((row) => {
      const hours = toHours(row.minutes);
      const trips = row.trips || 0;
      return {
        userId: String(row.userId),
        fullName: row.fullName || '—',
        hours,
        trips,
        overnightTrips: row.overnightTrips || 0,
        averageHoursPerTrip: trips > 0 ? Math.round((hours / trips) * 100) / 100 : 0,
      };
    });

    const woMap = Object.fromEntries(woByStatus.map((r) => [r._id, r.count]));
    const pmMap = Object.fromEntries(pmByStatus.map((r) => [r._id, r.count]));
    const assetMap = Object.fromEntries(assetsByStatus.map((r) => [r._id, r.count]));
    const totalAssets = Object.values(assetMap).reduce((a, b) => a + b, 0);
    const woTotal = Object.values(woMap).reduce((a, b) => a + b, 0);

    return {
      kpis: {
        totalEmployees,
        activeEmployees,
        employeesCurrentlyWorking: currentlyWorking,
        employeesOnOvertime: onOvertime,
        employeesOnTravelOvertime: onTravelOvertime,
      },
      attendance: {
        totalWorkingHours: toHours(att.totalMinutes),
        averageWorkingHours:
          att.users?.length > 0
            ? toHours(att.totalMinutes / att.users.length)
            : 0,
        attendanceRate: Math.min(100, Math.max(0, attendanceRate || 0)),
      },
      overtime: {
        // Phase 3: totalApprovedHours semantics (approvedHours ?? worked).
        totalOvertimeHours: toHours(otTotalMinutes),
        // Backward-compatible field (TRAVEL only); UI no longer splits types.
        totalTravelOvertimeHours: toHours(otTravel),
        totalTrips,
        overnightTrips,
        totalTechnicians,
        averageHoursPerTrip:
          totalTrips > 0
            ? Math.round((toHours(otTotalMinutes) / totalTrips) * 100) / 100
            : 0,
        averageOtHoursPerEmployee:
          activeEmployees > 0 ? toHours(otTotalMinutes / activeEmployees) : 0,
        topOvertimeEmployees: technicianRows,
        hoursPerTechnician: technicianRows.map((row) => ({
          label: row.fullName,
          value: row.hours,
        })),
        tripsPerTechnician: technicianRows.map((row) => ({
          label: row.fullName,
          value: row.trips,
        })),
      },
      workOrders: {
        total: woTotal,
        pending: woMap.PENDING || 0,
        assigned: (woMap.ASSIGNED || 0) + (woMap.ACCEPTED || 0),
        inProgress: woMap.IN_PROGRESS || 0,
        completed: woMap.COMPLETED || 0,
        cancelled: woMap.CANCELLED || 0,
      },
      preventiveMaintenance: {
        due: pmMap.SCHEDULED || 0,
        overdue: pmMap.OVERDUE || 0,
        completed: pmMap.COMPLETED || 0,
      },
      inventory: {
        lowStock,
        outOfStock,
        recentStockMovements: recentMovements.map((m) => ({
          id: String(m._id),
          type: m.type,
          quantity: m.quantity,
          quantityDelta: m.quantityDelta,
          partName: m.sparePartId?.name || null,
          sku: m.sparePartId?.partNumber || null,
          createdAt: (m.movementDate || m.createdAt)?.toISOString?.() || null,
        })),
      },
      assets: {
        totalAssets,
        active: assetMap.ACTIVE || 0,
        underMaintenance: assetMap.MAINTENANCE || 0,
        retired: assetMap.RETIRED || 0,
      },
      liveActivity,
      notifications: liveActivity.slice(0, 5).map((e) => ({
        id: e.id,
        title: e.action,
        body: `${e.module} · ${e.actorName || 'System'}`,
        createdAt: e.createdAt,
      })),
      charts: trends,
      period,
      from: from.toISOString(),
      to: to.toISOString(),
    };
  }

  async _buildSupervisorSummary({ companyId, memberIds, from, to }) {
    const ids = memberIds || [];
    const attendanceBase = {
      companyId,
      userId: { $in: ids },
      createdAt: { $gte: from, $lte: to },
    };
    const overtimeBase = {
      companyId,
      userId: { $in: ids },
      startAt: { $gte: from, $lte: to },
    };
    const woBase = {
      companyId,
      deletedAt: null,
      assignedTechnicianId: { $in: ids },
      createdAt: { $gte: from, $lte: to },
    };

    const teamPlans = await MaintenancePlan.find({
      companyId,
      deletedAt: null,
      assignedTechnicianId: { $in: ids },
    })
      .select('_id')
      .lean();
    const planIds = teamPlans.map((p) => p._id);
    const pmBase = {
      companyId,
      scheduledDate: { $gte: from, $lte: to },
      ...(planIds.length ? { planId: { $in: planIds } } : { planId: { $in: [] } }),
    };

    const [
      currentlyWorking,
      attendanceAgg,
      overtimeAgg,
      woByStatus,
      pmByStatus,
      lowStock,
      liveActivity,
      trends,
    ] = await Promise.all([
      Attendance.countDocuments({
        companyId,
        userId: { $in: ids },
        status: { $in: ['CLOCKED_IN', 'ON_BREAK'] },
        date: dateKey(new Date()),
      }),
      Attendance.aggregate([
        { $match: attendanceBase },
        {
          $group: {
            _id: null,
            totalMinutes: { $sum: { $ifNull: ['$workingMinutes', 0] } },
            users: { $addToSet: '$userId' },
          },
        },
      ]),
      OvertimeRecord.aggregate([
        { $match: overtimeBase },
        {
          $group: {
            _id: '$type',
            minutes: { $sum: otMinutesExpr() },
          },
        },
      ]),
      WorkOrder.aggregate([
        { $match: woBase },
        { $group: { _id: '$status', count: { $sum: 1 } } },
      ]),
      MaintenanceSchedule.aggregate([
        { $match: pmBase },
        { $group: { _id: '$status', count: { $sum: 1 } } },
      ]),
      SparePart.countDocuments({
        companyId,
        deletedAt: null,
        isActive: true,
        $expr: {
          $and: [
            { $gt: ['$currentQuantity', 0] },
            { $lte: ['$currentQuantity', '$minimumQuantity'] },
          ],
        },
      }),
      this._liveActivity(companyId, ids),
      this._buildTrends({ companyId, userIds: ids, from, to }),
    ]);

    const att = attendanceAgg[0] || { totalMinutes: 0, users: [] };
    const otNormal = overtimeAgg.find((r) => r._id === 'NORMAL')?.minutes || 0;
    const otTravel = overtimeAgg.find((r) => r._id === 'TRAVEL')?.minutes || 0;
    const otTotal = otNormal + otTravel;
    const woMap = Object.fromEntries(woByStatus.map((r) => [r._id, r.count]));
    const pmMap = Object.fromEntries((pmByStatus || []).map((r) => [r._id, r.count]));
    const woTotal = Object.values(woMap).reduce((a, b) => a + b, 0);
    const completed = woMap.COMPLETED || 0;

    return {
      teamAttendance: {
        currentlyWorking,
        totalWorkingHours: toHours(att.totalMinutes),
        membersPresent: att.users?.length || 0,
      },
      teamOvertime: {
        totalOvertimeHours: toHours(otTotal),
        totalTravelOvertimeHours: toHours(otTravel),
      },
      teamWorkOrders: {
        total: woTotal,
        pending: woMap.PENDING || 0,
        assigned: (woMap.ASSIGNED || 0) + (woMap.ACCEPTED || 0),
        inProgress: woMap.IN_PROGRESS || 0,
        completed,
      },
      teamPm: {
        due: pmMap.SCHEDULED || 0,
        overdue: pmMap.OVERDUE || 0,
        completed: pmMap.COMPLETED || 0,
      },
      teamInventoryAlerts: { lowStock },
      teamActivity: liveActivity,
      teamPerformance: {
        completionRate:
          woTotal > 0 ? Math.round((completed / woTotal) * 1000) / 10 : 0,
        averageWorkingHours:
          ids.length > 0 ? toHours(att.totalMinutes / ids.length) : 0,
      },
      charts: trends,
    };
  }

  async _buildTechnicianSummary({ companyId, userId, from, to }) {
    const todayKey = dateKey(new Date());
    const [
      todayAttendance,
      attendanceAgg,
      overtimeAgg,
      woByStatus,
      pmByStatus,
      completedWithDuration,
      trends,
    ] = await Promise.all([
      Attendance.findOne({ companyId, userId, date: todayKey }).lean(),
      Attendance.aggregate([
        {
          $match: {
            companyId,
            userId,
            createdAt: { $gte: from, $lte: to },
          },
        },
        {
          $group: {
            _id: null,
            totalMinutes: { $sum: { $ifNull: ['$workingMinutes', 0] } },
            days: { $sum: 1 },
          },
        },
      ]),
      OvertimeRecord.aggregate([
        {
          $match: {
            companyId,
            userId,
            startAt: { $gte: from, $lte: to },
          },
        },
        {
          $group: {
            _id: '$type',
            minutes: { $sum: otMinutesExpr() },
          },
        },
      ]),
      WorkOrder.aggregate([
        {
          $match: {
            companyId,
            deletedAt: null,
            assignedTechnicianId: userId,
            createdAt: { $gte: from, $lte: to },
          },
        },
        { $group: { _id: '$status', count: { $sum: 1 } } },
      ]),
      (async () => {
        const plans = await MaintenancePlan.find({
          companyId,
          deletedAt: null,
          assignedTechnicianId: userId,
        })
          .select('_id')
          .lean();
        const planIds = plans.map((p) => p._id);
        if (!planIds.length) return [];
        return MaintenanceSchedule.aggregate([
          {
            $match: {
              companyId,
              planId: { $in: planIds },
              scheduledDate: { $gte: from, $lte: to },
            },
          },
          { $group: { _id: '$status', count: { $sum: 1 } } },
        ]);
      })(),
      WorkOrder.aggregate([
        {
          $match: {
            companyId,
            deletedAt: null,
            assignedTechnicianId: userId,
            status: 'COMPLETED',
            completedAt: { $gte: from, $lte: to },
            startedAt: { $ne: null },
          },
        },
        {
          $project: {
            durationMs: { $subtract: ['$completedAt', '$startedAt'] },
          },
        },
        {
          $group: {
            _id: null,
            avgMs: { $avg: '$durationMs' },
            count: { $sum: 1 },
          },
        },
      ]),
      this._buildTrends({ companyId, userIds: [userId], from, to }),
    ]);

    const att = attendanceAgg[0] || { totalMinutes: 0, days: 0 };
    const otNormal = overtimeAgg.find((r) => r._id === 'NORMAL')?.minutes || 0;
    const otTravel = overtimeAgg.find((r) => r._id === 'TRAVEL')?.minutes || 0;
    const otTotal = otNormal + otTravel;
    const woMap = Object.fromEntries(woByStatus.map((r) => [r._id, r.count]));
    const pmMap = Object.fromEntries((pmByStatus || []).map((r) => [r._id, r.count]));
    const daySpan = Math.max(
      1,
      Math.ceil((to.getTime() - from.getTime()) / (24 * 60 * 60 * 1000)) + 1
    );
    const attendanceRate =
      Math.round(((att.days || 0) / Math.min(daySpan, 31)) * 1000) / 10;
    const avgCompletion = completedWithDuration[0];

    const gps =
      todayAttendance?.clockOut?.gps ||
      todayAttendance?.clockIn?.gps ||
      null;

    return {
      attendance: {
        todayStatus: todayAttendance?.status || 'NOT_STARTED',
        checkInAt: todayAttendance?.clockIn?.recordedAt?.toISOString?.() || null,
        checkOutAt: todayAttendance?.clockOut?.recordedAt?.toISOString?.() || null,
        totalWorkingHours: toHours(att.totalMinutes),
        todayWorkingHours: toHours(todayAttendance?.workingMinutes || 0),
      },
      overtime: {
        totalOvertimeHours: toHours(otTotal),
        totalTravelOvertimeHours: toHours(otTravel),
      },
      work: {
        assigned:
          (woMap.ASSIGNED || 0) +
          (woMap.ACCEPTED || 0) +
          (woMap.IN_PROGRESS || 0),
        completed: woMap.COMPLETED || 0,
        pending: woMap.PENDING || 0,
      },
      preventiveMaintenance: {
        assignedTasks: (pmMap.SCHEDULED || 0) + (pmMap.OVERDUE || 0),
        completedTasks: pmMap.COMPLETED || 0,
      },
      location: {
        latitude: gps?.latitude ?? null,
        longitude: gps?.longitude ?? null,
        lastKnownAddress:
          gps?.fullAddress || gps?.address || gps?.city || null,
        lastSynchronization:
          todayAttendance?.updatedAt?.toISOString?.() ||
          todayAttendance?.clockIn?.recordedAt?.toISOString?.() ||
          null,
      },
      performance: {
        attendanceRate: Math.min(100, Math.max(0, attendanceRate || 0)),
        monthlyWorkingHours: toHours(att.totalMinutes),
        monthlyOvertimeHours: toHours(otTotal),
        monthlyTravelOtHours: toHours(otTravel),
        completedJobs: woMap.COMPLETED || 0,
        averageCompletionHours: avgCompletion?.avgMs
          ? Math.round((avgCompletion.avgMs / 3600000) * 10) / 10
          : 0,
      },
      charts: trends,
    };
  }

  async _liveActivity(companyId, userIds) {
    const filter = { companyId };
    if (userIds?.length) {
      filter.actorId = { $in: userIds };
    }
    const rows = await AuditLog.find(filter)
      .sort({ createdAt: -1 })
      .limit(10)
      .populate('actorId', 'firstName lastName fullName')
      .lean();

    return rows.map((row) => ({
      id: String(row._id),
      action: row.action,
      module: row.module,
      actorName:
        row.actorId?.fullName ||
        [row.actorId?.firstName, row.actorId?.lastName].filter(Boolean).join(' ') ||
        null,
      createdAt: row.createdAt?.toISOString?.() || null,
    }));
  }

  async _buildTrends({ companyId, userIds, from, to }) {
    const buckets = buildTrendBuckets(from, to);
    if (buckets.length === 0) {
      return {
        attendance: [],
        overtime: [],
        workOrders: [],
        preventiveMaintenance: [],
      };
    }

    const userFilter = userIds?.length ? { userId: { $in: userIds } } : {};
    const woUserFilter = userIds?.length
      ? { assignedTechnicianId: { $in: userIds } }
      : {};

    const [attendanceRows, overtimeRecords, woRows, pmRows] = await Promise.all([
      Attendance.aggregate([
        {
          $match: {
            companyId,
            ...userFilter,
            createdAt: { $gte: from, $lte: to },
          },
        },
        {
          $group: {
            _id: {
              $dateToString: { format: '%Y-%m-%d', date: '$createdAt' },
            },
            minutes: { $sum: { $ifNull: ['$workingMinutes', 0] } },
          },
        },
      ]),
      OvertimeRecord.find({
        companyId,
        ...userFilter,
        startAt: { $gte: from, $lte: to },
        endAt: { $ne: null },
      })
        .select('startAt endAt approvedHours eligibleOvertimeMinutes')
        .lean(),
      WorkOrder.aggregate([
        {
          $match: {
            companyId,
            deletedAt: null,
            ...woUserFilter,
            createdAt: { $gte: from, $lte: to },
          },
        },
        {
          $group: {
            _id: {
              $dateToString: { format: '%Y-%m-%d', date: '$createdAt' },
            },
            count: { $sum: 1 },
          },
        },
      ]),
      (async () => {
        const planFilter = { companyId, deletedAt: null };
        if (userIds?.length) {
          planFilter.assignedTechnicianId = { $in: userIds };
        }
        const plans = await MaintenancePlan.find(planFilter).select('_id').lean();
        const planIds = plans.map((p) => p._id);
        if (userIds?.length && !planIds.length) return [];
        return MaintenanceSchedule.aggregate([
          {
            $match: {
              companyId,
              scheduledDate: { $gte: from, $lte: to },
              ...(planIds.length && userIds?.length
                ? { planId: { $in: planIds } }
                : {}),
            },
          },
          {
            $group: {
              _id: {
                $dateToString: { format: '%Y-%m-%d', date: '$scheduledDate' },
              },
              count: { $sum: 1 },
            },
          },
        ]);
      })(),
    ]);

    const attMap = Object.fromEntries(
      attendanceRows.map((r) => [r._id, toHours(r.minutes)])
    );
    const otMinutesMap = buildOvertimeTrendDayMap(overtimeRecords);
    const otMap = Object.fromEntries(
      Object.entries(otMinutesMap).map(([key, minutes]) => [key, toHours(minutes)])
    );
    const woMap = Object.fromEntries(woRows.map((r) => [r._id, r.count]));
    const pmMap = Object.fromEntries((pmRows || []).map((r) => [r._id, r.count]));

    const isDaily = buckets[0]?.key?.length === 10;

    const mapBucket = (bucket, source, isHours) => {
      if (isDaily) {
        return {
          label: bucket.label,
          value: source[bucket.key] || 0,
        };
      }
      // Monthly: sum matching day keys in range
      let value = 0;
      for (const [key, val] of Object.entries(source)) {
        const d = new Date(key);
        if (d >= bucket.from && d <= bucket.to) {
          value += val;
        }
      }
      return { label: bucket.label, value: isHours ? Math.round(value * 10) / 10 : value };
    };

    return {
      attendance: buckets.map((b) => mapBucket(b, attMap, true)),
      overtime: buckets.map((b) => mapBucket(b, otMap, true)),
      workOrders: buckets.map((b) => mapBucket(b, woMap, false)),
      preventiveMaintenance: buckets.map((b) => mapBucket(b, pmMap, false)),
    };
  }
}

export default new DashboardService();

export { buildOvertimeTrendDayMap, overtimeRecordTrendMinutes };
