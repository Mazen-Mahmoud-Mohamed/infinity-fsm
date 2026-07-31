import User, { USER_STATUSES } from '../organization/models/user.model.js';
import UserActivity, {
  USER_ACTIVITY_ACTIONS,
} from './models/userActivity.model.js';
import Branch from '../organization/models/branch.model.js';
import Region from '../organization/models/region.model.js';
import City from '../organization/models/city.model.js';
import Department from '../organization/models/department.model.js';
import Team from '../organization/models/team.model.js';
import Position from '../organization/models/position.model.js';
import AppError, {
  ConflictError,
  ForbiddenError,
  NotFoundError,
} from '../../../shared/errors/AppError.js';
import auditService from '../audit/audit.service.js';
import { uploadUserAvatarBuffer } from './users.upload.js';
import rbacService from '../rbac/rbac.service.js';

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

function resolveStatus(doc) {
  if (doc.status && USER_STATUSES.includes(doc.status)) return doc.status;
  return doc.isActive === false ? 'DISABLED' : 'ACTIVE';
}

function applyStatus(user, status) {
  const normalized = String(status).toUpperCase();
  if (!USER_STATUSES.includes(normalized)) {
    throw new AppError(
      'INVALID_STATUS',
      `status must be one of: ${USER_STATUSES.join(', ')}`,
      422
    );
  }
  user.status = normalized;
  user.isActive = User.syncActiveFromStatus(normalized);
  return normalized;
}

class UsersService {
  _mapNamed(doc) {
    if (!doc) return null;
    return {
      id: toId(doc._id || doc.id),
      name: doc.name || null,
      code: doc.code || null,
    };
  }

  _mapUser(doc, extras = {}) {
    const status = resolveStatus(doc);
    const fullName =
      doc.fullName ||
      [doc.firstName, doc.lastName].filter(Boolean).join(' ').trim();

    return {
      id: toId(doc._id),
      companyId: toId(doc.companyId),
      employeeId: doc.employeeId,
      username: doc.username || null,
      email: doc.email,
      firstName: doc.firstName,
      lastName: doc.lastName,
      fullName,
      phone: doc.phone || null,
      jobTitle: doc.jobTitle || extras.positionName || null,
      avatarUrl: doc.avatarUrl || null,
      roles: doc.roles || [],
      primaryRole: doc.roles?.[0] || null,
      status,
      isActive: status === 'ACTIVE',
      branchId: toId(doc.branchId),
      regionId: toId(doc.regionId),
      cityId: toId(doc.cityId),
      departmentId: toId(doc.departmentId),
      teamId: toId(doc.teamId),
      positionId: toId(doc.positionId),
      department: extras.department || null,
      branch: extras.branch || null,
      team: extras.team || null,
      position: extras.position || null,
      lastLoginAt: doc.lastLoginAt || null,
      lastActiveAt: doc.lastSeenAt || null,
      createdBy: extras.createdBy || toId(doc.createdBy),
      updatedBy: extras.updatedBy || toId(doc.updatedBy),
      createdAt: doc.createdAt || null,
      updatedAt: doc.updatedAt || null,
    };
  }

  _mapActivity(doc) {
    return {
      id: toId(doc._id),
      companyId: toId(doc.companyId),
      userId: toId(doc.userId),
      actorId: toId(doc.actorId),
      action: doc.action,
      summary: doc.summary || null,
      metadata: doc.metadata || {},
      createdAt: doc.createdAt || null,
    };
  }

  async _logAudit(user, auth, { action, resourceId, metadata }) {
    await auditService.log({
      companyId: user.companyId,
      actorId: auth.userId,
      actorRole: auth.roles?.[0] || null,
      action,
      module: 'users',
      resourceType: 'User',
      resourceId,
      metadata,
    });
  }

  async _logActivity({
    companyId,
    userId,
    actorId,
    action,
    summary,
    metadata = {},
  }) {
    if (!USER_ACTIVITY_ACTIONS.includes(action)) return null;
    const doc = await UserActivity.create({
      companyId,
      userId,
      actorId,
      action,
      summary,
      metadata,
    });
    return doc;
  }

  async _getUserOrThrow(companyId, id) {
    const doc = await User.findOne({
      _id: id,
      companyId,
      deletedAt: null,
    }).select('-passwordHash -permissionOverrides');
    if (!doc) throw new NotFoundError('User not found');
    return doc;
  }

  async _enrich(doc) {
    const [
      department,
      branch,
      team,
      position,
      createdByUser,
      updatedByUser,
    ] = await Promise.all([
      doc.departmentId
        ? Department.findById(doc.departmentId).select('name code').lean()
        : null,
      doc.branchId
        ? Branch.findById(doc.branchId).select('name code').lean()
        : null,
      doc.teamId ? Team.findById(doc.teamId).select('name code').lean() : null,
      doc.positionId
        ? Position.findById(doc.positionId).select('name code').lean()
        : null,
      doc.createdBy
        ? User.findById(doc.createdBy).select('firstName lastName email').lean()
        : null,
      doc.updatedBy
        ? User.findById(doc.updatedBy).select('firstName lastName email').lean()
        : null,
    ]);

    return this._mapUser(doc, {
      department: this._mapNamed(department),
      branch: this._mapNamed(branch),
      team: this._mapNamed(team),
      position: this._mapNamed(position),
      positionName: position?.name || null,
      createdBy: createdByUser
        ? { id: toId(createdByUser._id), name: displayUserName(createdByUser) }
        : null,
      updatedBy: updatedByUser
        ? { id: toId(updatedByUser._id), name: displayUserName(updatedByUser) }
        : null,
    });
  }

  async _assertOrgRefs(companyId, payload) {
    const branch = await Branch.findOne({
      _id: payload.branchId,
      companyId,
      deletedAt: null,
    });
    if (!branch) throw new AppError('INVALID_BRANCH', 'branchId is invalid', 422);

    const region = await Region.findOne({
      _id: payload.regionId,
      companyId,
      deletedAt: null,
    });
    if (!region) throw new AppError('INVALID_REGION', 'regionId is invalid', 422);

    const city = await City.findOne({
      _id: payload.cityId,
      companyId,
      deletedAt: null,
    });
    if (!city) throw new AppError('INVALID_CITY', 'cityId is invalid', 422);

    const department = await Department.findOne({
      _id: payload.departmentId,
      companyId,
      deletedAt: null,
    });
    if (!department) {
      throw new AppError('INVALID_DEPARTMENT', 'departmentId is invalid', 422);
    }

    if (payload.teamId) {
      const team = await Team.findOne({
        _id: payload.teamId,
        companyId,
        deletedAt: null,
      });
      if (!team) throw new AppError('INVALID_TEAM', 'teamId is invalid', 422);
    }

    if (payload.positionId) {
      const position = await Position.findOne({
        _id: payload.positionId,
        companyId,
        deletedAt: null,
      });
      if (!position) {
        throw new AppError('INVALID_POSITION', 'positionId is invalid', 422);
      }
    }
  }

  async _assertUnique(companyId, { email, username, employeeId, excludeId }) {
    const emailExists = await User.findOne({
      email: email.toLowerCase(),
      deletedAt: null,
      ...(excludeId ? { _id: { $ne: excludeId } } : {}),
    }).select('_id');
    if (emailExists) throw new ConflictError('Email already exists');

    if (username) {
      const usernameExists = await User.findOne({
        companyId,
        username: username.toLowerCase(),
        deletedAt: null,
        ...(excludeId ? { _id: { $ne: excludeId } } : {}),
      }).select('_id');
      if (usernameExists) throw new ConflictError('Username already exists');
    }

    const employeeExists = await User.findOne({
      companyId,
      employeeId,
      deletedAt: null,
      ...(excludeId ? { _id: { $ne: excludeId } } : {}),
    }).select('_id');
    if (employeeExists) throw new ConflictError('Employee ID already exists');
  }

  async _normalizeRoles(companyId, roles) {
    return rbacService.validateRoleSlugs(companyId, roles);
  }

  async getDashboard(user) {
    const companyId = user.companyId;
    const base = { companyId, deletedAt: null };
    const [totalUsers, activeUsers, disabledUsers, lockedUsers] =
      await Promise.all([
        User.countDocuments(base),
        User.countDocuments({ ...base, status: 'ACTIVE' }),
        User.countDocuments({ ...base, status: 'DISABLED' }),
        User.countDocuments({ ...base, status: 'LOCKED' }),
      ]);

    // Backward-compatible counts for users without status field
    const legacyActive = await User.countDocuments({
      ...base,
      status: { $exists: false },
      isActive: true,
    });
    const legacyDisabled = await User.countDocuments({
      ...base,
      status: { $exists: false },
      isActive: false,
    });

    return {
      totalUsers,
      activeUsers: activeUsers + legacyActive,
      disabledUsers: disabledUsers + legacyDisabled,
      lockedUsers,
    };
  }

  async listUsers(
    user,
    {
      page = 1,
      limit = 20,
      search,
      status,
      role,
      departmentId,
      branchId,
    } = {}
  ) {
    const filter = { companyId: user.companyId, deletedAt: null };

    if (status && String(status).toUpperCase() !== 'ALL') {
      const normalized = String(status).toUpperCase();
      if (!USER_STATUSES.includes(normalized)) {
        throw new AppError('INVALID_STATUS', 'Invalid status filter', 422);
      }
      if (normalized === 'ACTIVE') {
        filter.$or = [{ status: 'ACTIVE' }, { status: { $exists: false }, isActive: true }];
      } else if (normalized === 'DISABLED') {
        filter.$or = [
          { status: 'DISABLED' },
          { status: { $exists: false }, isActive: false },
        ];
      } else {
        filter.status = normalized;
      }
    }

    if (role) {
      filter.roles = String(role).toUpperCase();
    }
    if (departmentId) filter.departmentId = departmentId;
    if (branchId) filter.branchId = branchId;

    if (search?.trim()) {
      const regex = new RegExp(escapeRegex(search.trim()), 'i');
      const searchClause = {
        $or: [
          { firstName: regex },
          { lastName: regex },
          { email: regex },
          { username: regex },
          { employeeId: regex },
          { phone: regex },
          { jobTitle: regex },
        ],
      };
      if (filter.$or) {
        filter.$and = [{ $or: filter.$or }, searchClause];
        delete filter.$or;
      } else {
        Object.assign(filter, searchClause);
      }
    }

    const skip = (Number(page) - 1) * Number(limit);
    const [items, total] = await Promise.all([
      User.find(filter)
        .select('-passwordHash -permissionOverrides')
        .sort({ firstName: 1, lastName: 1 })
        .skip(skip)
        .limit(Number(limit)),
      User.countDocuments(filter),
    ]);

    const mapped = await Promise.all(items.map((item) => this._enrich(item)));

    return {
      items: mapped,
      pagination: {
        page: Number(page),
        limit: Number(limit),
        total,
        totalPages: Math.max(1, Math.ceil(total / Number(limit))),
      },
    };
  }

  async getUserById(user, id) {
    const doc = await this._getUserOrThrow(user.companyId, id);
    const profile = await this._enrich(doc);
    const activities = await UserActivity.find({
      companyId: user.companyId,
      userId: id,
    })
      .sort({ createdAt: -1 })
      .limit(20)
      .lean();

    return {
      ...profile,
      recentActivity: activities.map((a) => this._mapActivity(a)),
    };
  }

  async createUser(user, auth, payload) {
    const firstName = payload.firstName?.toString?.()?.trim?.();
    const lastName = payload.lastName?.toString?.()?.trim?.();
    const email = payload.email?.toString?.()?.trim?.()?.toLowerCase?.();
    const username = payload.username?.toString?.()?.trim?.()?.toLowerCase?.();
    const employeeId =
      payload.employeeId?.toString?.()?.trim?.() ||
      payload.username?.toString?.()?.trim?.();
    const password = payload.password?.toString?.() || '';

    if (!firstName || !lastName || !email || !username || !employeeId) {
      throw new AppError(
        'VALIDATION_ERROR',
        'firstName, lastName, email, and username are required',
        422
      );
    }
    if (password.length < 8) {
      throw new AppError(
        'INVALID_PASSWORD',
        'Password must be at least 8 characters',
        422
      );
    }

    const roles = await this._normalizeRoles(
      user.companyId,
      payload.roles || payload.role
    );
    await this._assertOrgRefs(user.companyId, payload);
    await this._assertUnique(user.companyId, {
      email,
      username,
      employeeId,
    });

    const status = payload.status
      ? String(payload.status).toUpperCase()
      : 'ACTIVE';
    if (!USER_STATUSES.includes(status)) {
      throw new AppError('INVALID_STATUS', 'Invalid status', 422);
    }

    const passwordHash = await User.hashPassword(password);
    const doc = await User.create({
      companyId: user.companyId,
      employeeId,
      username,
      email,
      passwordHash,
      firstName,
      lastName,
      phone: payload.phone?.toString?.()?.trim?.() || null,
      jobTitle: payload.jobTitle?.toString?.()?.trim?.() || null,
      roles,
      branchId: payload.branchId,
      regionId: payload.regionId,
      cityId: payload.cityId,
      departmentId: payload.departmentId,
      teamId: payload.teamId || null,
      positionId: payload.positionId || null,
      status,
      isActive: User.syncActiveFromStatus(status),
      createdBy: auth.userId,
      updatedBy: auth.userId,
    });

    await this._logActivity({
      companyId: user.companyId,
      userId: doc._id,
      actorId: auth.userId,
      action: 'CREATED',
      summary: 'User account created',
    });
    await this._logAudit(user, auth, {
      action: 'users.create',
      resourceId: doc._id,
      metadata: { email, username },
    });

    return this._enrich(doc);
  }

  async updateUser(user, auth, id, payload) {
    const doc = await this._getUserOrThrow(user.companyId, id);

    if (payload.firstName !== undefined) {
      doc.firstName = payload.firstName.toString().trim();
    }
    if (payload.lastName !== undefined) {
      doc.lastName = payload.lastName.toString().trim();
    }
    if (payload.phone !== undefined) {
      doc.phone = payload.phone?.toString?.()?.trim?.() || null;
    }
    if (payload.jobTitle !== undefined) {
      doc.jobTitle = payload.jobTitle?.toString?.()?.trim?.() || null;
    }
    if (payload.email !== undefined) {
      doc.email = payload.email.toString().trim().toLowerCase();
    }
    if (payload.username !== undefined) {
      doc.username = payload.username.toString().trim().toLowerCase();
    }
    if (payload.employeeId !== undefined) {
      doc.employeeId = payload.employeeId.toString().trim();
    }
    if (payload.roles !== undefined || payload.role !== undefined) {
      doc.roles = await this._normalizeRoles(
        user.companyId,
        payload.roles || payload.role
      );
    }

    const orgPayload = {
      branchId: payload.branchId ?? doc.branchId,
      regionId: payload.regionId ?? doc.regionId,
      cityId: payload.cityId ?? doc.cityId,
      departmentId: payload.departmentId ?? doc.departmentId,
      teamId: payload.teamId !== undefined ? payload.teamId : doc.teamId,
      positionId:
        payload.positionId !== undefined ? payload.positionId : doc.positionId,
    };

    if (
      payload.branchId ||
      payload.regionId ||
      payload.cityId ||
      payload.departmentId ||
      payload.teamId !== undefined ||
      payload.positionId !== undefined
    ) {
      await this._assertOrgRefs(user.companyId, orgPayload);
      doc.branchId = orgPayload.branchId;
      doc.regionId = orgPayload.regionId;
      doc.cityId = orgPayload.cityId;
      doc.departmentId = orgPayload.departmentId;
      doc.teamId = orgPayload.teamId || null;
      doc.positionId = orgPayload.positionId || null;
    }

    await this._assertUnique(user.companyId, {
      email: doc.email,
      username: doc.username,
      employeeId: doc.employeeId,
      excludeId: doc._id,
    });

    if (payload.status !== undefined) {
      applyStatus(doc, payload.status);
    }

    doc.updatedBy = auth.userId;
    await doc.save();

    await this._logActivity({
      companyId: user.companyId,
      userId: doc._id,
      actorId: auth.userId,
      action: 'UPDATED',
      summary: 'User profile updated',
    });
    await this._logAudit(user, auth, {
      action: 'users.update',
      resourceId: doc._id,
      metadata: {},
    });

    return this._enrich(doc);
  }

  async setUserStatus(user, auth, id, status) {
    const doc = await this._getUserOrThrow(user.companyId, id);
    if (toId(doc._id) === toId(auth.userId) && status !== 'ACTIVE') {
      throw new ForbiddenError('You cannot disable or lock your own account');
    }

    const previous = resolveStatus(doc);
    const next = applyStatus(doc, status);
    doc.updatedBy = auth.userId;
    await doc.save();

    let action = 'UPDATED';
    if (next === 'ACTIVE' && previous !== 'ACTIVE') action = 'ENABLED';
    if (next === 'DISABLED') action = 'DISABLED';
    if (next === 'LOCKED') action = 'LOCKED';
    if (previous === 'LOCKED' && next === 'ACTIVE') action = 'UNLOCKED';

    await this._logActivity({
      companyId: user.companyId,
      userId: doc._id,
      actorId: auth.userId,
      action,
      summary: `User status changed to ${next}`,
      metadata: { from: previous, to: next },
    });
    await this._logAudit(user, auth, {
      action: 'users.set_status',
      resourceId: doc._id,
      metadata: { from: previous, to: next },
    });

    return this._enrich(doc);
  }

  async deleteUser(user, auth, id) {
    const doc = await this._getUserOrThrow(user.companyId, id);
    if (toId(doc._id) === toId(auth.userId)) {
      throw new ForbiddenError('You cannot delete your own account');
    }

    doc.deletedAt = new Date();
    doc.status = 'DISABLED';
    doc.isActive = false;
    doc.updatedBy = auth.userId;
    await doc.save();

    await this._logActivity({
      companyId: user.companyId,
      userId: doc._id,
      actorId: auth.userId,
      action: 'DELETED',
      summary: 'User account deleted',
    });
    await this._logAudit(user, auth, {
      action: 'users.delete',
      resourceId: doc._id,
      metadata: {},
    });

    return this._enrich(doc);
  }

  async resetPassword(user, auth, id, newPassword) {
    if (!newPassword || String(newPassword).length < 8) {
      throw new AppError(
        'INVALID_PASSWORD',
        'Password must be at least 8 characters',
        422
      );
    }

    const doc = await User.findOne({
      _id: id,
      companyId: user.companyId,
      deletedAt: null,
    }).select('+passwordHash');
    if (!doc) throw new NotFoundError('User not found');

    doc.passwordHash = await User.hashPassword(String(newPassword));
    doc.updatedBy = auth.userId;
    await doc.save();

    await this._logActivity({
      companyId: user.companyId,
      userId: doc._id,
      actorId: auth.userId,
      action: 'PASSWORD_RESET',
      summary: 'Password reset by administrator',
    });
    await this._logAudit(user, auth, {
      action: 'users.reset_password',
      resourceId: doc._id,
      metadata: {},
    });

    return { id: toId(doc._id), success: true };
  }

  async changeOwnPassword(user, auth, { currentPassword, newPassword }) {
    if (!newPassword || String(newPassword).length < 8) {
      throw new AppError(
        'INVALID_PASSWORD',
        'Password must be at least 8 characters',
        422
      );
    }

    const doc = await User.findOne({
      _id: auth.userId,
      companyId: user.companyId,
      deletedAt: null,
    }).select('+passwordHash');
    if (!doc) throw new NotFoundError('User not found');

    const valid = await doc.comparePassword(String(currentPassword || ''));
    if (!valid) {
      throw new AppError('INVALID_PASSWORD', 'Current password is incorrect', 400);
    }

    doc.passwordHash = await User.hashPassword(String(newPassword));
    doc.updatedBy = auth.userId;
    await doc.save();

    await this._logActivity({
      companyId: user.companyId,
      userId: doc._id,
      actorId: auth.userId,
      action: 'PASSWORD_CHANGED',
      summary: 'User changed their own password',
    });
    await this._logAudit(user, auth, {
      action: 'users.change_password',
      resourceId: doc._id,
      metadata: {},
    });

    return { id: toId(doc._id), success: true };
  }

  async uploadAvatar(user, auth, id, file) {
    if (!file?.buffer) {
      throw new AppError('AVATAR_REQUIRED', 'Avatar image is required', 422);
    }

    const doc = await this._getUserOrThrow(user.companyId, id);
    const uploaded = await uploadUserAvatarBuffer(file.buffer, {
      companyId: user.companyId,
      userId: doc._id,
    });

    doc.avatarUrl = uploaded.url;
    doc.avatarPublicId = uploaded.publicId;
    doc.updatedBy = auth.userId;
    await doc.save();

    await this._logActivity({
      companyId: user.companyId,
      userId: doc._id,
      actorId: auth.userId,
      action: 'AVATAR_UPDATED',
      summary: 'User avatar updated',
    });
    await this._logAudit(user, auth, {
      action: 'users.avatar_update',
      resourceId: doc._id,
      metadata: {},
    });

    return this._enrich(doc);
  }

  async listActivity(user, { userId, page = 1, limit = 20 } = {}) {
    const filter = { companyId: user.companyId };
    if (userId) filter.userId = userId;

    const skip = (Number(page) - 1) * Number(limit);
    const [items, total] = await Promise.all([
      UserActivity.find(filter)
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(Number(limit))
        .lean(),
      UserActivity.countDocuments(filter),
    ]);

    return {
      items: items.map((a) => this._mapActivity(a)),
      pagination: {
        page: Number(page),
        limit: Number(limit),
        total,
        totalPages: Math.max(1, Math.ceil(total / Number(limit))),
      },
    };
  }
}

export default new UsersService();
