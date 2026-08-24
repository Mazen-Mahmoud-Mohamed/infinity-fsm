import Role from './models/role.model.js';
import User from '../organization/models/user.model.js';
import {
  PERMISSIONS,
  ROLE_PERMISSIONS,
  getPermissionCatalog,
  getPermissionsForRoles,
} from '../../../shared/constants/permissions.constants.js';
import {
  ROLES,
  SYSTEM_ROLE_DEFINITIONS,
} from '../../../shared/constants/roles.constants.js';
import AppError, {
  ConflictError,
  ForbiddenError,
  NotFoundError,
} from '../../../shared/errors/AppError.js';
import auditService from '../audit/audit.service.js';

function escapeRegex(value) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function toId(value) {
  return value?.toString?.() ?? value ?? null;
}

function slugify(name) {
  return String(name || '')
    .trim()
    .toUpperCase()
    .replace(/[^A-Z0-9]+/g, '_')
    .replace(/^_+|_+$/g, '')
    .slice(0, 80);
}

function isAdminActor(auth) {
  return (auth?.roles || []).includes(ROLES.ADMIN);
}

function applyPermissionOverrides(basePermissions, overrides = []) {
  const permissions = new Set(basePermissions);
  for (const override of overrides) {
    if (override.type === 'grant') {
      permissions.add(override.permission);
    } else if (override.type === 'deny') {
      permissions.delete(override.permission);
    }
  }
  return Array.from(permissions);
}

class RbacService {
  constructor() {
    this._systemRolesReady = null;
  }

  async ensureSystemRoles() {
    if (this._systemRolesReady) {
      return this._systemRolesReady;
    }

    this._systemRolesReady = this._ensureSystemRolesInternal().catch((error) => {
      this._systemRolesReady = null;
      throw error;
    });
    return this._systemRolesReady;
  }

  async _ensureSystemRolesInternal() {
    await Promise.all(
      SYSTEM_ROLE_DEFINITIONS.map(async (def) => {
        const permissions = ROLE_PERMISSIONS[def.slug] || [];
        const existing = await Role.findOne({
          slug: def.slug,
          companyId: null,
          deletedAt: null,
        });

        if (existing) {
          let dirty = false;
          if (!existing.isSystem) {
            existing.isSystem = true;
            dirty = true;
          }
          if (existing.name !== def.name) {
            existing.name = def.name;
            dirty = true;
          }
          if (!existing.description && def.description) {
            existing.description = def.description;
            dirty = true;
          }
          if (!existing.color && def.color) {
            existing.color = def.color;
            dirty = true;
          }
          // Seed permissions only when empty so admin edits are preserved.
          // Additive merge only for newly introduced system permissions.
          if (!existing.permissions?.length && permissions.length) {
            existing.permissions = permissions;
            dirty = true;
          } else if (permissions.includes(PERMISSIONS.DASHBOARD_VIEW)) {
            const current = existing.permissions || [];
            if (!current.includes(PERMISSIONS.DASHBOARD_VIEW)) {
              existing.permissions = [...current, PERMISSIONS.DASHBOARD_VIEW];
              dirty = true;
            }
          }
          if (dirty) await existing.save();
          return;
        }

        await Role.create({
          companyId: null,
          name: def.name,
          slug: def.slug,
          description: def.description,
          permissions,
          color: def.color,
          isSystem: true,
          isActive: true,
          createdBy: null,
          updatedBy: null,
        });
      })
    );
  }

  /**
   * Resolve permissions from Role documents with static ROLE_PERMISSIONS fallback.
   */
  async resolveUserPermissions(user) {
    await this.ensureSystemRoles();
    const roleDocs = await this.findRoleDocuments(
      user.roles || [],
      user.companyId
    );
    return this.permissionsFromRoleDocs(user, roleDocs);
  }

  /**
   * Same Role.find used by permission resolution (system + company roles).
   * Safe to call in parallel with User.findOne when roleSlugs/companyId come
   * from a verified JWT — caller MUST still validate against DB user.
   */
  async findRoleDocuments(roleSlugs, companyId) {
    const slugs = Array.isArray(roleSlugs) ? roleSlugs : [];
    if (slugs.length === 0) {
      return [];
    }

    return Role.find({
      slug: { $in: slugs },
      deletedAt: null,
      isActive: true,
      $or: [{ companyId: null }, { companyId }],
    }).lean();
  }

  /**
   * Merge Role.permissions (with static fallback) + user permissionOverrides.
   * Iterates user.roles (DB-authoritative order/membership).
   */
  permissionsFromRoleDocs(user, roleDocs) {
    const roleSlugs = user.roles || [];
    const bySlug = new Map((roleDocs || []).map((r) => [r.slug, r]));
    const permissionSet = new Set();

    for (const slug of roleSlugs) {
      const doc = bySlug.get(slug);
      if (doc?.permissions?.length) {
        doc.permissions.forEach((p) => permissionSet.add(p));
      } else {
        getPermissionsForRoles([slug]).forEach((p) => permissionSet.add(p));
      }
    }

    return applyPermissionOverrides(
      Array.from(permissionSet),
      user.permissionOverrides
    );
  }

  async validateRoleSlugs(companyId, roles) {
    await this.ensureSystemRoles();

    let list = roles;
    if (typeof roles === 'string') list = [roles];
    if (!Array.isArray(list) || list.length === 0) {
      throw new AppError('INVALID_ROLES', 'At least one role is required', 422);
    }

    const normalized = [
      ...new Set(list.map((r) => String(r).trim().toUpperCase()).filter(Boolean)),
    ];

    const found = await Role.find({
      slug: { $in: normalized },
      deletedAt: null,
      isActive: true,
      $or: [{ companyId: null }, { companyId }],
    })
      .select('slug')
      .lean();

    const foundSlugs = new Set(found.map((r) => r.slug));
    const missing = normalized.filter((s) => !foundSlugs.has(s));
    if (missing.length) {
      throw new AppError(
        'INVALID_ROLES',
        `Invalid or inactive role(s): ${missing.join(', ')}`,
        422
      );
    }

    return normalized;
  }

  _toDto(doc, { assignedUsersCount = 0 } = {}) {
    return {
      id: toId(doc._id),
      companyId: toId(doc.companyId),
      name: doc.name,
      slug: doc.slug,
      description: doc.description,
      permissions: doc.permissions || [],
      color: doc.color || '#1565C0',
      isSystem: Boolean(doc.isSystem),
      isActive: doc.isActive !== false,
      assignedUsersCount,
      createdBy: toId(doc.createdBy),
      updatedBy: toId(doc.updatedBy),
      createdAt: doc.createdAt,
      updatedAt: doc.updatedAt,
    };
  }

  async _countAssignedUsers(companyId, slug) {
    return User.countDocuments({
      companyId,
      deletedAt: null,
      roles: slug,
    });
  }

  async _findAccessibleRole(companyId, id) {
    const doc = await Role.findOne({
      _id: id,
      deletedAt: null,
      $or: [{ companyId: null }, { companyId }],
    });
    if (!doc) throw new NotFoundError('Role not found');
    return doc;
  }

  async _assertUniqueName({ companyId, name, excludeId }) {
    const existing = await Role.findOne({
      name: new RegExp(`^${escapeRegex(String(name).trim())}$`, 'i'),
      deletedAt: null,
      $or: [{ companyId: null }, { companyId }],
      ...(excludeId ? { _id: { $ne: excludeId } } : {}),
    }).select('_id name');
    if (existing) {
      throw new ConflictError('Role name must be unique');
    }
  }

  async _assertUniqueSlug({ companyId, slug, excludeId }) {
    const existing = await Role.findOne({
      slug,
      deletedAt: null,
      $or: [{ companyId: null }, { companyId }],
      ...(excludeId ? { _id: { $ne: excludeId } } : {}),
    }).select('_id slug');
    if (existing) {
      throw new ConflictError('Role slug must be unique');
    }
  }

  async getDashboard(user) {
    await this.ensureSystemRoles();
    const companyId = user.companyId;
    const scope = {
      deletedAt: null,
      $or: [{ companyId: null }, { companyId }],
    };

    const [totalRoles, activeRoles, systemRoles, customRoles] =
      await Promise.all([
        Role.countDocuments(scope),
        Role.countDocuments({ ...scope, isActive: true }),
        Role.countDocuments({ companyId: null, deletedAt: null, isSystem: true }),
        Role.countDocuments({ companyId, deletedAt: null, isSystem: false }),
      ]);

    return {
      totalRoles,
      activeRoles,
      systemRoles,
      customRoles,
    };
  }

  async listRoles(user, query = {}) {
    await this.ensureSystemRoles();
    const companyId = user.companyId;
    const page = Math.max(1, Number(query.page) || 1);
    const limit = Math.min(100, Math.max(1, Number(query.limit) || 20));
    const skip = (page - 1) * limit;

    const filter = {
      deletedAt: null,
      $or: [{ companyId: null }, { companyId }],
    };

    if (query.search) {
      const re = new RegExp(escapeRegex(String(query.search).trim()), 'i');
      filter.$and = [
        {
          $or: [{ name: re }, { slug: re }, { description: re }],
        },
      ];
    }

    if (query.isActive === 'true' || query.isActive === true) {
      filter.isActive = true;
    } else if (query.isActive === 'false' || query.isActive === false) {
      filter.isActive = false;
    }

    if (query.isSystem === 'true' || query.isSystem === true) {
      filter.isSystem = true;
    } else if (query.isSystem === 'false' || query.isSystem === false) {
      filter.isSystem = false;
      filter.companyId = companyId;
    }

    const [total, docs] = await Promise.all([
      Role.countDocuments(filter),
      Role.find(filter)
        .sort({ isSystem: -1, name: 1 })
        .skip(skip)
        .limit(limit)
        .lean(),
    ]);

    const items = await Promise.all(
      docs.map(async (doc) => {
        const assignedUsersCount = await this._countAssignedUsers(
          companyId,
          doc.slug
        );
        return this._toDto(doc, { assignedUsersCount });
      })
    );

    return {
      items,
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit) || 1,
      },
    };
  }

  async getRoleById(user, id) {
    await this.ensureSystemRoles();
    const doc = await this._findAccessibleRole(user.companyId, id);
    const assignedUsersCount = await this._countAssignedUsers(
      user.companyId,
      doc.slug
    );
    return this._toDto(doc, { assignedUsersCount });
  }

  getPermissionCatalog() {
    return getPermissionCatalog();
  }

  async createRole(user, auth, payload) {
    await this.ensureSystemRoles();
    const companyId = user.companyId;
    const name = String(payload.name || '').trim();
    if (!name) {
      throw new AppError('VALIDATION_ERROR', 'Role name is required', 422);
    }

    const slug = slugify(payload.slug || name);
    if (!slug) {
      throw new AppError('VALIDATION_ERROR', 'Invalid role slug', 422);
    }

    if (SYSTEM_ROLE_DEFINITIONS.some((d) => d.slug === slug)) {
      throw new ConflictError('Cannot create a role with a reserved system slug');
    }

    await this._assertUniqueName({ companyId, name });
    await this._assertUniqueSlug({ companyId, slug });

    const permissions = Array.isArray(payload.permissions)
      ? [...new Set(payload.permissions.map(String))]
      : [];

    const doc = await Role.create({
      companyId,
      name,
      slug,
      description: payload.description?.trim() || null,
      permissions,
      color: payload.color?.trim() || '#1565C0',
      isSystem: false,
      isActive: payload.isActive !== false,
      createdBy: user._id,
      updatedBy: user._id,
    });

    await auditService.log({
      companyId,
      actorId: user._id,
      actorRole: auth.roles?.[0] || null,
      action: 'ROLE_CREATED',
      module: 'roles',
      resourceType: 'Role',
      resourceId: doc._id,
      metadata: { slug: doc.slug, name: doc.name },
    });

    return this._toDto(doc);
  }

  async updateRole(user, auth, id, payload) {
    await this.ensureSystemRoles();
    const companyId = user.companyId;
    const doc = await this._findAccessibleRole(companyId, id);

    if (doc.isSystem && !isAdminActor(auth)) {
      throw new ForbiddenError(
        'Only Administrators can edit system roles'
      );
    }

    // Custom roles belong to company; system roles are global
    if (!doc.isSystem && toId(doc.companyId) !== toId(companyId)) {
      throw new ForbiddenError('Cannot update this role');
    }

    if (payload.name !== undefined) {
      const name = String(payload.name).trim();
      if (!name) {
        throw new AppError('VALIDATION_ERROR', 'Role name is required', 422);
      }
      await this._assertUniqueName({
        companyId,
        name,
        excludeId: doc._id,
      });
      doc.name = name;
    }

    if (payload.description !== undefined) {
      doc.description = payload.description?.trim() || null;
    }

    if (payload.color !== undefined) {
      doc.color = payload.color?.trim() || '#1565C0';
    }

    if (payload.permissions !== undefined) {
      if (!Array.isArray(payload.permissions)) {
        throw new AppError(
          'VALIDATION_ERROR',
          'permissions must be an array',
          422
        );
      }
      doc.permissions = [...new Set(payload.permissions.map(String))];
    }

    if (payload.isActive !== undefined && !doc.isSystem) {
      doc.isActive = Boolean(payload.isActive);
    }

    // System role slugs are immutable; custom slug changes only when not assigned
    if (payload.slug !== undefined && !doc.isSystem) {
      const slug = slugify(payload.slug);
      if (!slug) {
        throw new AppError('VALIDATION_ERROR', 'Invalid role slug', 422);
      }
      if (slug !== doc.slug) {
        const assigned = await this._countAssignedUsers(companyId, doc.slug);
        if (assigned > 0) {
          throw new ConflictError(
            'Cannot change slug while role is assigned to users'
          );
        }
        await this._assertUniqueSlug({
          companyId,
          slug,
          excludeId: doc._id,
        });
        doc.slug = slug;
      }
    }

    doc.updatedBy = user._id;
    await doc.save();

    await auditService.log({
      companyId,
      actorId: user._id,
      actorRole: auth.roles?.[0] || null,
      action: 'ROLE_UPDATED',
      module: 'roles',
      resourceType: 'Role',
      resourceId: doc._id,
      metadata: { slug: doc.slug, name: doc.name },
    });

    const assignedUsersCount = await this._countAssignedUsers(
      companyId,
      doc.slug
    );
    return this._toDto(doc, { assignedUsersCount });
  }

  async setRoleStatus(user, auth, id, isActive) {
    await this.ensureSystemRoles();
    const companyId = user.companyId;
    const doc = await this._findAccessibleRole(companyId, id);

    if (doc.isSystem) {
      if (!isAdminActor(auth)) {
        throw new ForbiddenError(
          'Only Administrators can change system role status'
        );
      }
      // Keep ADMIN always active
      if (doc.slug === ROLES.ADMIN && isActive === false) {
        throw new AppError(
          'INVALID_STATUS',
          'Administrator role cannot be deactivated',
          422
        );
      }
    } else if (toId(doc.companyId) !== toId(companyId)) {
      throw new ForbiddenError('Cannot update this role');
    }

    doc.isActive = Boolean(isActive);
    doc.updatedBy = user._id;
    await doc.save();

    await auditService.log({
      companyId,
      actorId: user._id,
      actorRole: auth.roles?.[0] || null,
      action: isActive ? 'ROLE_ACTIVATED' : 'ROLE_DEACTIVATED',
      module: 'roles',
      resourceType: 'Role',
      resourceId: doc._id,
      metadata: { slug: doc.slug },
    });

    return this._toDto(doc, {
      assignedUsersCount: await this._countAssignedUsers(companyId, doc.slug),
    });
  }

  async deleteRole(user, auth, id) {
    await this.ensureSystemRoles();
    const companyId = user.companyId;
    const doc = await this._findAccessibleRole(companyId, id);

    if (doc.isSystem) {
      throw new ForbiddenError('System roles cannot be deleted');
    }

    if (toId(doc.companyId) !== toId(companyId)) {
      throw new ForbiddenError('Cannot delete this role');
    }

    const assigned = await this._countAssignedUsers(companyId, doc.slug);
    if (assigned > 0) {
      throw new ConflictError(
        `Cannot delete role assigned to ${assigned} user(s)`
      );
    }

    doc.deletedAt = new Date();
    doc.isActive = false;
    doc.updatedBy = user._id;
    await doc.save();

    await auditService.log({
      companyId,
      actorId: user._id,
      actorRole: auth.roles?.[0] || null,
      action: 'ROLE_DELETED',
      module: 'roles',
      resourceType: 'Role',
      resourceId: doc._id,
      metadata: { slug: doc.slug, name: doc.name },
    });

    return { id: toId(doc._id), deleted: true };
  }

  async cloneRole(user, auth, id, payload = {}) {
    await this.ensureSystemRoles();
    const companyId = user.companyId;
    const source = await this._findAccessibleRole(companyId, id);

    const name =
      String(payload.name || '').trim() || `Copy of ${source.name}`;
    const slug = slugify(payload.slug || name);

    if (SYSTEM_ROLE_DEFINITIONS.some((d) => d.slug === slug)) {
      throw new ConflictError('Cannot create a role with a reserved system slug');
    }

    await this._assertUniqueName({ companyId, name });
    await this._assertUniqueSlug({ companyId, slug });

    const doc = await Role.create({
      companyId,
      name,
      slug,
      description: source.description,
      permissions: [...(source.permissions || [])],
      color: source.color || '#1565C0',
      isSystem: false,
      isActive: true,
      createdBy: user._id,
      updatedBy: user._id,
    });

    await auditService.log({
      companyId,
      actorId: user._id,
      actorRole: auth.roles?.[0] || null,
      action: 'ROLE_CLONED',
      module: 'roles',
      resourceType: 'Role',
      resourceId: doc._id,
      metadata: {
        slug: doc.slug,
        sourceId: toId(source._id),
        sourceSlug: source.slug,
      },
    });

    return this._toDto(doc);
  }

  async listRoleUsers(user, id, query = {}) {
    await this.ensureSystemRoles();
    const companyId = user.companyId;
    const doc = await this._findAccessibleRole(companyId, id);
    const page = Math.max(1, Number(query.page) || 1);
    const limit = Math.min(100, Math.max(1, Number(query.limit) || 20));
    const skip = (page - 1) * limit;

    const filter = {
      companyId,
      deletedAt: null,
      roles: doc.slug,
    };

    if (query.search) {
      const re = new RegExp(escapeRegex(String(query.search).trim()), 'i');
      filter.$or = [
        { firstName: re },
        { lastName: re },
        { email: re },
        { username: re },
        { employeeId: re },
      ];
    }

    const [total, users] = await Promise.all([
      User.countDocuments(filter),
      User.find(filter)
        .select(
          'firstName lastName email username employeeId roles status isActive avatarUrl'
        )
        .sort({ firstName: 1, lastName: 1 })
        .skip(skip)
        .limit(limit)
        .lean(),
    ]);

    return {
      role: this._toDto(doc, {
        assignedUsersCount: total,
      }),
      items: users.map((u) => ({
        id: toId(u._id),
        firstName: u.firstName,
        lastName: u.lastName,
        fullName: [u.firstName, u.lastName].filter(Boolean).join(' ').trim(),
        email: u.email,
        username: u.username,
        employeeId: u.employeeId,
        roles: u.roles || [],
        status: u.status,
        isActive: u.isActive,
        avatarUrl: u.avatarUrl,
      })),
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit) || 1,
      },
    };
  }

  async assignRoleToUsers(user, auth, id, userIds = []) {
    await this.ensureSystemRoles();
    const companyId = user.companyId;
    const doc = await this._findAccessibleRole(companyId, id);

    if (!doc.isActive) {
      throw new AppError(
        'ROLE_INACTIVE',
        'Cannot assign an inactive role',
        422
      );
    }

    if (!Array.isArray(userIds) || userIds.length === 0) {
      throw new AppError(
        'VALIDATION_ERROR',
        'userIds must be a non-empty array',
        422
      );
    }

    const uniqueIds = [...new Set(userIds.map(String))];
    const targets = await User.find({
      _id: { $in: uniqueIds },
      companyId,
      deletedAt: null,
    });

    if (targets.length !== uniqueIds.length) {
      throw new NotFoundError('One or more users were not found');
    }

    let updatedCount = 0;
    for (const target of targets) {
      if (!target.roles.includes(doc.slug)) {
        target.roles = [...target.roles, doc.slug];
        target.updatedBy = user._id;
        await target.save();
        updatedCount += 1;
      }
    }

    await auditService.log({
      companyId,
      actorId: user._id,
      actorRole: auth.roles?.[0] || null,
      action: 'ROLE_ASSIGNED',
      module: 'roles',
      resourceType: 'Role',
      resourceId: doc._id,
      metadata: {
        slug: doc.slug,
        userIds: uniqueIds,
        updatedCount,
      },
    });

    return {
      roleId: toId(doc._id),
      slug: doc.slug,
      requested: uniqueIds.length,
      updatedCount,
      assignedUsersCount: await this._countAssignedUsers(companyId, doc.slug),
    };
  }
}

const rbacService = new RbacService();
export default rbacService;
