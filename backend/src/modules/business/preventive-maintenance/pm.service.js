import MaintenancePlan, {
  PM_FREQUENCIES,
  PM_TRIGGERS,
  PM_PRIORITIES,
  PM_PLAN_STATUSES,
} from './models/maintenancePlan.model.js';
import MaintenanceSchedule, {
  PM_SCHEDULE_STATUSES,
} from './models/maintenanceSchedule.model.js';
import Asset from '../assets/models/asset.model.js';
import Team from '../../core/organization/models/team.model.js';
import User from '../../core/organization/models/user.model.js';
import { generateScheduleDates, startOfDay, addFrequency } from './pm.schedule.js';
import PERMISSIONS from '../../../shared/constants/permissions.constants.js';
import AppError, {
  ConflictError,
  ForbiddenError,
  NotFoundError,
} from '../../../shared/errors/AppError.js';
import auditService from '../../core/audit/audit.service.js';

function escapeRegex(value) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function toId(value) {
  return value?.toString?.() ?? value ?? null;
}

function displayUserName(user) {
  if (!user) return null;
  const full = [user.firstName, user.lastName].filter(Boolean).join(' ').trim();
  return full || user.email || user.username || null;
}

function parseOptionalDate(value, fieldName) {
  if (value === undefined || value === null || value === '') return null;
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) {
    throw new AppError('INVALID_DATE', `${fieldName} must be a valid ISO date`, 422);
  }
  return date;
}

function parseOptionalObjectId(value) {
  if (value === undefined || value === null || value === '') return null;
  return String(value);
}

function normalizeEnum(value, allowed, fieldName, { required = false, fallback = null } = {}) {
  if (value === undefined || value === null || value === '') {
    if (required) {
      throw new AppError('INVALID_VALUE', `${fieldName} is required`, 422);
    }
    return fallback;
  }
  const normalized = String(value).toUpperCase().replace(/[-\s]/g, '_');
  // Accept SEMI-ANNUAL / Semi Annual etc.
  const aliases = {
    SEMIANNUAL: 'SEMI_ANNUAL',
    SEMI_ANNUAL: 'SEMI_ANNUAL',
    TIMEBASED: 'TIME_BASED',
    TIME_BASED: 'TIME_BASED',
    METERBASED: 'METER_BASED',
    METER_BASED: 'METER_BASED',
  };
  const mapped = aliases[normalized] || normalized;
  if (!allowed.includes(mapped)) {
    throw new AppError(
      'INVALID_VALUE',
      `${fieldName} must be one of: ${allowed.join(', ')}`,
      422
    );
  }
  return mapped;
}

function parseChecklistItems(raw) {
  if (raw === undefined || raw === null || raw === '') return [];
  let items = raw;
  if (typeof raw === 'string') {
    try {
      items = JSON.parse(raw);
    } catch {
      throw new AppError('INVALID_CHECKLIST', 'checklistItems must be valid JSON', 422);
    }
  }
  if (!Array.isArray(items)) {
    throw new AppError('INVALID_CHECKLIST', 'checklistItems must be an array', 422);
  }
  return items.map((item, index) => ({
    title: String(item.title || '').trim(),
    description: item.description?.toString?.()?.trim?.() || null,
    requiresPassFail: item.requiresPassFail !== false,
    requiresNotes: item.requiresNotes === true,
    photoRequired: item.photoRequired === true,
    sortOrder: Number.isFinite(Number(item.sortOrder)) ? Number(item.sortOrder) : index,
  })).filter((item) => item.title);
}

class PreventiveMaintenanceService {
  _assertPermission(auth, permission) {
    if (!auth?.permissions?.includes(permission)) {
      throw new ForbiddenError('You do not have permission to perform this action');
    }
  }

  _mapChecklistItem(item) {
    return {
      id: toId(item._id),
      title: item.title,
      description: item.description || null,
      requiresPassFail: item.requiresPassFail !== false,
      requiresNotes: item.requiresNotes === true,
      photoRequired: item.photoRequired === true,
      sortOrder: item.sortOrder ?? 0,
    };
  }

  _mapNamedRef(doc, { nameFields = ['name'] } = {}) {
    if (!doc) return null;
    if (typeof doc === 'string' || doc._bsontype === 'ObjectId') {
      return { id: toId(doc), name: null };
    }
    let name = null;
    for (const field of nameFields) {
      if (doc[field]) {
        name = doc[field];
        break;
      }
    }
    if (!name) name = displayUserName(doc);
    return { id: toId(doc._id || doc.id), name };
  }

  _mapPlan(doc) {
    return {
      id: toId(doc._id),
      companyId: toId(doc.companyId),
      name: doc.name,
      code: doc.code,
      description: doc.description || null,
      frequency: doc.frequency,
      trigger: doc.trigger,
      nextDueDate: doc.nextDueDate ? new Date(doc.nextDueDate).toISOString() : null,
      priority: doc.priority || 'MEDIUM',
      estimatedDurationMinutes: Number(doc.estimatedDurationMinutes) || 0,
      assignedTeam: this._mapNamedRef(doc.assignedTeamId),
      assignedTechnician: this._mapNamedRef(doc.assignedTechnicianId, {
        nameFields: ['firstName'],
      }),
      asset: doc.assetId && typeof doc.assetId === 'object' && doc.assetId.name
        ? {
            id: toId(doc.assetId._id),
            name: doc.assetId.name,
            assetNumber: doc.assetId.assetNumber || null,
          }
        : doc.assetId
          ? { id: toId(doc.assetId), name: null, assetNumber: null }
          : null,
      meterThreshold: doc.meterThreshold ?? null,
      currentMeterReading: doc.currentMeterReading ?? null,
      status: doc.status || 'ACTIVE',
      checklistItems: (doc.checklistItems || [])
        .slice()
        .sort((a, b) => (a.sortOrder ?? 0) - (b.sortOrder ?? 0))
        .map((item) => this._mapChecklistItem(item)),
      createdAt: doc.createdAt ? new Date(doc.createdAt).toISOString() : null,
      updatedAt: doc.updatedAt ? new Date(doc.updatedAt).toISOString() : null,
    };
  }

  _mapSchedule(doc) {
    const plan =
      doc.planId && typeof doc.planId === 'object' && doc.planId.name
        ? {
            id: toId(doc.planId._id),
            name: doc.planId.name,
            code: doc.planId.code,
            priority: doc.planId.priority || null,
            assetId: toId(doc.planId.assetId),
          }
        : { id: toId(doc.planId), name: null, code: null, priority: null, assetId: null };

    let status = doc.status;
    if (
      (status === 'SCHEDULED' || status === 'OVERDUE') &&
      doc.scheduledDate &&
      new Date(doc.scheduledDate) < startOfDay()
    ) {
      status = 'OVERDUE';
    }

    return {
      id: toId(doc._id),
      companyId: toId(doc.companyId),
      plan,
      scheduledDate: doc.scheduledDate
        ? new Date(doc.scheduledDate).toISOString()
        : null,
      status,
      completedDate: doc.completedDate
        ? new Date(doc.completedDate).toISOString()
        : null,
      cancelledDate: doc.cancelledDate
        ? new Date(doc.cancelledDate).toISOString()
        : null,
      notes: doc.notes || null,
      checklistResults: (doc.checklistResults || []).map((item) => ({
        checklistItemId: toId(item.checklistItemId),
        title: item.title || null,
        result: item.result || null,
        notes: item.notes || null,
        photoUrl: item.photoUrl || null,
      })),
      workOrderId: toId(doc.workOrderId),
      completedBy: doc.completedById
        ? {
            id: toId(doc.completedById),
            name: doc.completedByName || null,
          }
        : null,
      createdAt: doc.createdAt ? new Date(doc.createdAt).toISOString() : null,
      updatedAt: doc.updatedAt ? new Date(doc.updatedAt).toISOString() : null,
    };
  }

  async _getPlanOrThrow(companyId, id) {
    const plan = await MaintenancePlan.findOne({
      _id: id,
      companyId,
      deletedAt: null,
    })
      .populate('assignedTeamId', 'name code')
      .populate('assignedTechnicianId', 'firstName lastName email')
      .populate('assetId', 'name assetNumber');
    if (!plan) throw new NotFoundError('Maintenance plan');
    return plan;
  }

  async _getScheduleOrThrow(companyId, id) {
    const schedule = await MaintenanceSchedule.findOne({
      _id: id,
      companyId,
    }).populate('planId', 'name code priority assetId checklistItems');
    if (!schedule) throw new NotFoundError('Maintenance schedule');
    return schedule;
  }

  async _validateAssignments(companyId, { teamId, technicianId, assetId }) {
    if (teamId) {
      const team = await Team.findOne({ _id: teamId, companyId, deletedAt: null });
      if (!team) throw new AppError('INVALID_TEAM', 'assignedTeamId is invalid', 422);
    }
    if (technicianId) {
      const user = await User.findOne({ _id: technicianId, companyId, isActive: true });
      if (!user) {
        throw new AppError('INVALID_TECHNICIAN', 'assignedTechnicianId is invalid', 422);
      }
    }
    if (assetId) {
      const asset = await Asset.findOne({ _id: assetId, companyId, deletedAt: null });
      if (!asset) throw new AppError('INVALID_ASSET', 'assetId is invalid', 422);
    }
  }

  async _logAudit(user, auth, { action, resourceType, resourceId, metadata }) {
    await auditService.log({
      companyId: user.companyId,
      actorId: auth.userId,
      actorRole: auth.roles?.[0] || null,
      action,
      module: 'preventive_maintenance',
      resourceType,
      resourceId,
      metadata,
    });
  }

  async _markOverdue(companyId) {
    const today = startOfDay();
    await MaintenanceSchedule.updateMany(
      {
        companyId,
        status: 'SCHEDULED',
        scheduledDate: { $lt: today },
      },
      { $set: { status: 'OVERDUE' } }
    );
  }

  async _generateSchedulesForPlan(plan, { count = 6, replaceFuture = false } = {}) {
    if (!plan.nextDueDate || plan.status !== 'ACTIVE') {
      return [];
    }

    if (replaceFuture) {
      await MaintenanceSchedule.deleteMany({
        companyId: plan.companyId,
        planId: plan._id,
        status: { $in: ['SCHEDULED', 'OVERDUE'] },
        scheduledDate: { $gte: startOfDay() },
      });
    }

    const dates = generateScheduleDates({
      startDate: plan.nextDueDate,
      frequency: plan.frequency,
      count,
    });

    const created = [];
    for (const date of dates) {
      try {
        const schedule = await MaintenanceSchedule.create({
          companyId: plan.companyId,
          planId: plan._id,
          scheduledDate: date,
          status: date < startOfDay() ? 'OVERDUE' : 'SCHEDULED',
        });
        created.push(schedule);
      } catch (error) {
        // Skip duplicate upcoming schedule for same plan/date
        if (error?.code !== 11000) throw error;
      }
    }
    return created;
  }

  // ─── Dashboard ────────────────────────────────────────────────────────────

  async getDashboard(user, auth) {
    this._assertPermission(auth, PERMISSIONS.PM_VIEW);
    await this._markOverdue(user.companyId);

    const companyId = user.companyId;
    const today = startOfDay();
    const soon = new Date(today);
    soon.setDate(soon.getDate() + 30);

    const [upcoming, overdue, completed, cancelled, activePlans, recentSchedules] =
      await Promise.all([
        MaintenanceSchedule.countDocuments({
          companyId,
          status: 'SCHEDULED',
          scheduledDate: { $gte: today, $lte: soon },
        }),
        MaintenanceSchedule.countDocuments({ companyId, status: 'OVERDUE' }),
        MaintenanceSchedule.countDocuments({ companyId, status: 'COMPLETED' }),
        MaintenanceSchedule.countDocuments({ companyId, status: 'CANCELLED' }),
        MaintenancePlan.countDocuments({
          companyId,
          deletedAt: null,
          status: 'ACTIVE',
        }),
        MaintenanceSchedule.find({
          companyId,
          status: { $in: ['SCHEDULED', 'OVERDUE'] },
        })
          .populate('planId', 'name code priority assetId')
          .sort({ scheduledDate: 1 })
          .limit(10),
      ]);

    return {
      upcoming,
      overdue,
      completed,
      cancelled,
      activePlans,
      recentSchedules: recentSchedules.map((item) => this._mapSchedule(item)),
    };
  }

  // ─── Plans ────────────────────────────────────────────────────────────────

  async listPlans(
    user,
    auth,
    { page = 1, limit = 20, search, status, frequency, priority } = {}
  ) {
    this._assertPermission(auth, PERMISSIONS.PM_VIEW);

    const filter = { companyId: user.companyId, deletedAt: null };
    const normalizedStatus = normalizeEnum(status, PM_PLAN_STATUSES, 'status');
    if (normalizedStatus) filter.status = normalizedStatus;
    const normalizedFrequency = normalizeEnum(frequency, PM_FREQUENCIES, 'frequency');
    if (normalizedFrequency) filter.frequency = normalizedFrequency;
    const normalizedPriority = normalizeEnum(priority, PM_PRIORITIES, 'priority');
    if (normalizedPriority) filter.priority = normalizedPriority;
    if (search) {
      const regex = new RegExp(escapeRegex(search), 'i');
      filter.$or = [{ name: regex }, { code: regex }, { description: regex }];
    }

    const skip = (page - 1) * limit;
    const [items, total] = await Promise.all([
      MaintenancePlan.find(filter)
        .populate('assignedTeamId', 'name code')
        .populate('assignedTechnicianId', 'firstName lastName email')
        .populate('assetId', 'name assetNumber')
        .sort({ nextDueDate: 1, name: 1 })
        .skip(skip)
        .limit(limit),
      MaintenancePlan.countDocuments(filter),
    ]);

    return {
      items: items.map((item) => this._mapPlan(item)),
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.max(1, Math.ceil(total / limit)),
      },
    };
  }

  async getPlanById(user, auth, id) {
    this._assertPermission(auth, PERMISSIONS.PM_VIEW);
    return this._mapPlan(await this._getPlanOrThrow(user.companyId, id));
  }

  async createPlan(user, auth, payload) {
    this._assertPermission(auth, PERMISSIONS.PM_CREATE);

    const code = String(payload.code || '').trim().toUpperCase();
    const existing = await MaintenancePlan.findOne({
      companyId: user.companyId,
      code,
      deletedAt: null,
    });
    if (existing) {
      throw new ConflictError('A maintenance plan with this code already exists');
    }

    const teamId = parseOptionalObjectId(payload.assignedTeamId);
    const technicianId = parseOptionalObjectId(payload.assignedTechnicianId);
    const assetId = parseOptionalObjectId(payload.assetId);
    await this._validateAssignments(user.companyId, {
      teamId,
      technicianId,
      assetId,
    });

    const plan = await MaintenancePlan.create({
      companyId: user.companyId,
      name: String(payload.name).trim(),
      code,
      description: payload.description?.toString?.()?.trim?.() || null,
      frequency: normalizeEnum(payload.frequency, PM_FREQUENCIES, 'frequency', {
        required: true,
        fallback: 'MONTHLY',
      }),
      trigger: normalizeEnum(payload.trigger, PM_TRIGGERS, 'trigger', {
        required: true,
        fallback: 'TIME_BASED',
      }),
      nextDueDate: parseOptionalDate(payload.nextDueDate, 'nextDueDate'),
      priority: normalizeEnum(payload.priority, PM_PRIORITIES, 'priority', {
        fallback: 'MEDIUM',
      }),
      estimatedDurationMinutes: Number(payload.estimatedDurationMinutes ?? 60) || 60,
      assignedTeamId: teamId,
      assignedTechnicianId: technicianId,
      assetId,
      meterThreshold:
        payload.meterThreshold !== undefined && payload.meterThreshold !== ''
          ? Number(payload.meterThreshold)
          : null,
      currentMeterReading:
        payload.currentMeterReading !== undefined &&
        payload.currentMeterReading !== ''
          ? Number(payload.currentMeterReading)
          : null,
      status: normalizeEnum(payload.status, PM_PLAN_STATUSES, 'status', {
        fallback: 'ACTIVE',
      }),
      checklistItems: parseChecklistItems(payload.checklistItems),
    });

    if (plan.status === 'ACTIVE' && plan.nextDueDate) {
      await this._generateSchedulesForPlan(plan, { count: 6 });
    }

    await this._logAudit(user, auth, {
      action: 'pm_plan.create',
      resourceType: 'maintenance_plan',
      resourceId: plan._id,
      metadata: { code: plan.code },
    });

    return this._mapPlan(await this._getPlanOrThrow(user.companyId, plan._id));
  }

  async updatePlan(user, auth, id, payload) {
    this._assertPermission(auth, PERMISSIONS.PM_UPDATE);
    const plan = await this._getPlanOrThrow(user.companyId, id);

    if (payload.code !== undefined && payload.code !== null && payload.code !== '') {
      const code = String(payload.code).trim().toUpperCase();
      if (code !== plan.code) {
        const existing = await MaintenancePlan.findOne({
          companyId: user.companyId,
          code,
          deletedAt: null,
          _id: { $ne: plan._id },
        });
        if (existing) {
          throw new ConflictError('A maintenance plan with this code already exists');
        }
        plan.code = code;
      }
    }

    if (payload.name !== undefined) plan.name = String(payload.name).trim();
    if (payload.description !== undefined) {
      plan.description = payload.description?.toString?.()?.trim?.() || null;
    }
    if (payload.frequency !== undefined) {
      plan.frequency = normalizeEnum(payload.frequency, PM_FREQUENCIES, 'frequency', {
        required: true,
      });
    }
    if (payload.trigger !== undefined) {
      plan.trigger = normalizeEnum(payload.trigger, PM_TRIGGERS, 'trigger', {
        required: true,
      });
    }
    if (payload.nextDueDate !== undefined) {
      plan.nextDueDate = parseOptionalDate(payload.nextDueDate, 'nextDueDate');
    }
    if (payload.priority !== undefined) {
      plan.priority = normalizeEnum(payload.priority, PM_PRIORITIES, 'priority', {
        fallback: plan.priority,
      });
    }
    if (payload.estimatedDurationMinutes !== undefined) {
      plan.estimatedDurationMinutes =
        Number(payload.estimatedDurationMinutes) || plan.estimatedDurationMinutes;
    }

    const teamId =
      payload.assignedTeamId !== undefined
        ? parseOptionalObjectId(payload.assignedTeamId)
        : toId(plan.assignedTeamId);
    const technicianId =
      payload.assignedTechnicianId !== undefined
        ? parseOptionalObjectId(payload.assignedTechnicianId)
        : toId(plan.assignedTechnicianId);
    const assetId =
      payload.assetId !== undefined
        ? parseOptionalObjectId(payload.assetId)
        : toId(plan.assetId);

    if (
      payload.assignedTeamId !== undefined ||
      payload.assignedTechnicianId !== undefined ||
      payload.assetId !== undefined
    ) {
      await this._validateAssignments(user.companyId, {
        teamId,
        technicianId,
        assetId,
      });
      if (payload.assignedTeamId !== undefined) plan.assignedTeamId = teamId;
      if (payload.assignedTechnicianId !== undefined) {
        plan.assignedTechnicianId = technicianId;
      }
      if (payload.assetId !== undefined) plan.assetId = assetId;
    }

    if (payload.meterThreshold !== undefined) {
      plan.meterThreshold =
        payload.meterThreshold === '' || payload.meterThreshold === null
          ? null
          : Number(payload.meterThreshold);
    }
    if (payload.currentMeterReading !== undefined) {
      plan.currentMeterReading =
        payload.currentMeterReading === '' || payload.currentMeterReading === null
          ? null
          : Number(payload.currentMeterReading);
    }
    if (payload.status !== undefined) {
      plan.status = normalizeEnum(payload.status, PM_PLAN_STATUSES, 'status', {
        required: true,
      });
    }
    if (payload.checklistItems !== undefined) {
      plan.checklistItems = parseChecklistItems(payload.checklistItems);
    }

    await plan.save();

    if (
      payload.nextDueDate !== undefined ||
      payload.frequency !== undefined ||
      payload.status !== undefined
    ) {
      await this._generateSchedulesForPlan(plan, {
        count: 6,
        replaceFuture: true,
      });
    }

    await this._logAudit(user, auth, {
      action: 'pm_plan.update',
      resourceType: 'maintenance_plan',
      resourceId: plan._id,
      metadata: { code: plan.code },
    });

    return this._mapPlan(await this._getPlanOrThrow(user.companyId, plan._id));
  }

  async deletePlan(user, auth, id) {
    this._assertPermission(auth, PERMISSIONS.PM_DELETE);
    const plan = await this._getPlanOrThrow(user.companyId, id);
    plan.deletedAt = new Date();
    plan.status = 'INACTIVE';
    await plan.save();

    await MaintenanceSchedule.updateMany(
      {
        companyId: user.companyId,
        planId: plan._id,
        status: { $in: ['SCHEDULED', 'OVERDUE'] },
      },
      { $set: { status: 'CANCELLED', cancelledDate: new Date() } }
    );

    await this._logAudit(user, auth, {
      action: 'pm_plan.delete',
      resourceType: 'maintenance_plan',
      resourceId: plan._id,
      metadata: { code: plan.code },
    });

    return this._mapPlan(plan);
  }

  async updateChecklist(user, auth, planId, checklistItems) {
    this._assertPermission(auth, PERMISSIONS.PM_UPDATE);
    const plan = await this._getPlanOrThrow(user.companyId, planId);
    plan.checklistItems = parseChecklistItems(checklistItems);
    await plan.save();

    await this._logAudit(user, auth, {
      action: 'pm_checklist.update',
      resourceType: 'maintenance_plan',
      resourceId: plan._id,
      metadata: { itemCount: plan.checklistItems.length },
    });

    return this._mapPlan(await this._getPlanOrThrow(user.companyId, plan._id));
  }

  async generateSchedules(user, auth, planId, { count = 6 } = {}) {
    this._assertPermission(auth, PERMISSIONS.PM_UPDATE);
    const plan = await this._getPlanOrThrow(user.companyId, planId);
    if (!plan.nextDueDate) {
      throw new AppError(
        'NEXT_DUE_REQUIRED',
        'nextDueDate is required to generate schedules',
        422
      );
    }
    const created = await this._generateSchedulesForPlan(plan, {
      count: Math.min(Number(count) || 6, 24),
      replaceFuture: false,
    });
    return {
      generated: created.length,
      items: created.map((item) => this._mapSchedule(item)),
    };
  }

  // ─── Schedules ────────────────────────────────────────────────────────────

  async listSchedules(
    user,
    auth,
    { page = 1, limit = 20, search, status, planId, from, to } = {}
  ) {
    this._assertPermission(auth, PERMISSIONS.PM_VIEW);
    await this._markOverdue(user.companyId);

    const filter = { companyId: user.companyId };
    const normalizedStatus = normalizeEnum(status, PM_SCHEDULE_STATUSES, 'status');
    if (normalizedStatus) filter.status = normalizedStatus;
    if (planId) filter.planId = planId;
    if (from || to) {
      filter.scheduledDate = {};
      if (from) filter.scheduledDate.$gte = parseOptionalDate(from, 'from');
      if (to) filter.scheduledDate.$lte = parseOptionalDate(to, 'to');
    }

    let planIdsFilter = null;
    if (search) {
      const regex = new RegExp(escapeRegex(search), 'i');
      const plans = await MaintenancePlan.find({
        companyId: user.companyId,
        deletedAt: null,
        $or: [{ name: regex }, { code: regex }],
      }).select('_id');
      planIdsFilter = plans.map((p) => p._id);
      filter.$or = [
        { notes: regex },
        ...(planIdsFilter.length ? [{ planId: { $in: planIdsFilter } }] : []),
      ];
    }

    const skip = (page - 1) * limit;
    const [items, total] = await Promise.all([
      MaintenanceSchedule.find(filter)
        .populate('planId', 'name code priority assetId')
        .sort({ scheduledDate: 1 })
        .skip(skip)
        .limit(limit),
      MaintenanceSchedule.countDocuments(filter),
    ]);

    return {
      items: items.map((item) => this._mapSchedule(item)),
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.max(1, Math.ceil(total / limit)),
      },
    };
  }

  async getScheduleById(user, auth, id) {
    this._assertPermission(auth, PERMISSIONS.PM_VIEW);
    await this._markOverdue(user.companyId);
    return this._mapSchedule(await this._getScheduleOrThrow(user.companyId, id));
  }

  async completeSchedule(user, auth, id, payload = {}) {
    this._assertPermission(auth, PERMISSIONS.PM_UPDATE);
    const schedule = await this._getScheduleOrThrow(user.companyId, id);
    if (schedule.status === 'COMPLETED') {
      throw new ConflictError('Schedule is already completed');
    }
    if (schedule.status === 'CANCELLED') {
      throw new ConflictError('Cancelled schedules cannot be completed');
    }

    schedule.status = 'COMPLETED';
    schedule.completedDate =
      parseOptionalDate(payload.completedDate, 'completedDate') || new Date();
    schedule.notes = payload.notes?.toString?.()?.trim?.() || schedule.notes;
    schedule.completedById = auth.userId;
    schedule.completedByName = displayUserName(user);

    if (payload.checklistResults) {
      let results = payload.checklistResults;
      if (typeof results === 'string') {
        try {
          results = JSON.parse(results);
        } catch {
          throw new AppError('INVALID_RESULTS', 'checklistResults must be valid JSON', 422);
        }
      }
      if (Array.isArray(results)) {
        schedule.checklistResults = results.map((item) => ({
          checklistItemId: item.checklistItemId,
          title: item.title || null,
          result: item.result || null,
          notes: item.notes || null,
          photoUrl: item.photoUrl || null,
        }));
      }
    }

    await schedule.save();

    const plan = await MaintenancePlan.findOne({
      _id: schedule.planId,
      companyId: user.companyId,
      deletedAt: null,
    });
    if (plan?.nextDueDate) {
      plan.nextDueDate = addFrequency(schedule.scheduledDate, plan.frequency);
      await plan.save();
      await this._generateSchedulesForPlan(plan, { count: 1 });
    }

    await this._logAudit(user, auth, {
      action: 'pm_schedule.complete',
      resourceType: 'maintenance_schedule',
      resourceId: schedule._id,
      metadata: { planId: toId(schedule.planId) },
    });

    return this._mapSchedule(await this._getScheduleOrThrow(user.companyId, id));
  }

  async cancelSchedule(user, auth, id, payload = {}) {
    this._assertPermission(auth, PERMISSIONS.PM_UPDATE);
    const schedule = await this._getScheduleOrThrow(user.companyId, id);
    if (schedule.status === 'COMPLETED') {
      throw new ConflictError('Completed schedules cannot be cancelled');
    }
    schedule.status = 'CANCELLED';
    schedule.cancelledDate = new Date();
    schedule.notes = payload.notes?.toString?.()?.trim?.() || schedule.notes;
    await schedule.save();

    await this._logAudit(user, auth, {
      action: 'pm_schedule.cancel',
      resourceType: 'maintenance_schedule',
      resourceId: schedule._id,
      metadata: { planId: toId(schedule.planId) },
    });

    return this._mapSchedule(schedule);
  }

  // ─── History (completed/cancelled schedules) ──────────────────────────────

  async listHistory(
    user,
    auth,
    { page = 1, limit = 20, planId, search } = {}
  ) {
    this._assertPermission(auth, PERMISSIONS.PM_VIEW);

    const filter = {
      companyId: user.companyId,
      status: { $in: ['COMPLETED', 'CANCELLED'] },
    };
    if (planId) filter.planId = planId;
    if (search) {
      const regex = new RegExp(escapeRegex(search), 'i');
      filter.notes = regex;
    }

    const skip = (page - 1) * limit;
    const [items, total] = await Promise.all([
      MaintenanceSchedule.find(filter)
        .populate('planId', 'name code priority assetId')
        .sort({ updatedAt: -1 })
        .skip(skip)
        .limit(limit),
      MaintenanceSchedule.countDocuments(filter),
    ]);

    return {
      items: items.map((item) => this._mapSchedule(item)),
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.max(1, Math.ceil(total / limit)),
      },
    };
  }
}

export default new PreventiveMaintenanceService();
