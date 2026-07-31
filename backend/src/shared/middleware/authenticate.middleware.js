import jwt from 'jsonwebtoken';
import config from '../../config/index.js';
import { UnauthorizedError } from '../errors/AppError.js';
import User from '../../modules/core/organization/models/user.model.js';
import rbacService from '../../modules/core/rbac/rbac.service.js';
import { getPermissionsForRoles } from '../constants/permissions.constants.js';

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

    if (decoded.type !== 'access') {
      throw new UnauthorizedError('Invalid token type');
    }

    const user = await User.findOne({
      _id: decoded.sub,
      isActive: true,
      deletedAt: null,
    })
      .select('-passwordHash')
      .lean();

    if (!user) {
      throw new UnauthorizedError('User account is inactive or does not exist');
    }

    // Prefer dynamic Role.permissions; falls back to static ROLE_PERMISSIONS
    let permissions;
    try {
      permissions = await rbacService.resolveUserPermissions(user);
    } catch {
      permissions = getPermissionsForRoles(user.roles || []);
    }

    req.user = user;
    req.auth = {
      userId: user._id.toString(),
      companyId: user.companyId.toString(),
      roles: user.roles,
      permissions,
    };

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
