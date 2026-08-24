import jwt from 'jsonwebtoken';
import config from '../../config/index.js';
import { UnauthorizedError } from '../errors/AppError.js';
import User from '../../modules/core/organization/models/user.model.js';
import rbacService from '../../modules/core/rbac/rbac.service.js';
import { getPermissionsForRoles } from '../constants/permissions.constants.js';

/**
 * Normalize role lists for set comparison (order-independent).
 */
export function normalizeRoleSet(roles) {
  return [
    ...new Set(
      (Array.isArray(roles) ? roles : [])
        .map((role) => String(role || '').trim().toUpperCase())
        .filter(Boolean)
    ),
  ].sort();
}

/**
 * True when JWT roles and DB user roles contain the same membership.
 */
export function rolesMatch(jwtRoles, dbRoles) {
  const left = normalizeRoleSet(jwtRoles);
  const right = normalizeRoleSet(dbRoles);
  if (left.length !== right.length) return false;
  return left.every((role, index) => role === right[index]);
}

/**
 * Build auth context after JWT verify. Exported for focused tests.
 *
 * Overlaps User.findOne and Role.find (using verified JWT roles/companyId).
 * DB user remains authoritative; mismatched JWT roles/company → safe fallback.
 */
export async function buildAuthContextFromToken(decoded) {
  if (decoded.type !== 'access') {
    throw new UnauthorizedError('Invalid token type');
  }

  const jwtRoles = Array.isArray(decoded.roles) ? decoded.roles : [];
  const jwtCompanyId = decoded.companyId;

  // Warm in-memory system-role seed (0 ms after first request).
  await rbacService.ensureSystemRoles();

  const userQuery = User.findOne({
    _id: decoded.sub,
    isActive: true,
    deletedAt: null,
  })
    .select('-passwordHash')
    .lean();

  const roleQuery =
    jwtRoles.length > 0 && jwtCompanyId
      ? rbacService.findRoleDocuments(jwtRoles, jwtCompanyId)
      : Promise.resolve([]);

  const [user, prefetchedRoleDocs] = await Promise.all([userQuery, roleQuery]);

  if (!user) {
    throw new UnauthorizedError('User account is inactive or does not exist');
  }

  const dbCompanyId = user.companyId?.toString?.() ?? String(user.companyId);
  const tokenCompanyId =
    jwtCompanyId?.toString?.() ?? (jwtCompanyId ? String(jwtCompanyId) : '');
  const companyMatches = Boolean(tokenCompanyId) && tokenCompanyId === dbCompanyId;
  const jwtRolesCompatible = rolesMatch(jwtRoles, user.roles);

  let permissions;
  try {
    if (companyMatches && jwtRolesCompatible) {
      permissions = rbacService.permissionsFromRoleDocs(user, prefetchedRoleDocs);
    } else {
      // Roles/company changed since token was issued — re-resolve from DB user.
      permissions = await rbacService.resolveUserPermissions(user);
    }
  } catch {
    permissions = getPermissionsForRoles(user.roles || []);
  }

  return {
    user,
    auth: {
      userId: user._id.toString(),
      companyId: dbCompanyId,
      roles: user.roles,
      permissions,
    },
    // Test/diagnostics only — not attached to req in production path.
    _meta: {
      usedPrefetchedRoles: companyMatches && jwtRolesCompatible,
      companyMatches,
      jwtRolesCompatible,
    },
  };
}

export default async function authenticate(req, _res, next) {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader?.startsWith('Bearer ')) {
      throw new UnauthorizedError('Authorization token is required');
    }

    const token = authHeader.slice(7);

    let decoded;
    try {
      decoded = jwt.verify(token, config.jwt.accessSecret);
    } catch {
      throw new UnauthorizedError('Invalid or expired access token');
    }

    const { user, auth } = await buildAuthContextFromToken(decoded);

    req.user = user;
    req.auth = auth;

    next();
  } catch (error) {
    next(error);
  }
}

export function optionalAuthenticate(req, _res, next) {
  const authHeader = req.headers.authorization;

  if (!authHeader?.startsWith('Bearer ')) {
    return next();
  }

  return authenticate(req, _res, next);
}
