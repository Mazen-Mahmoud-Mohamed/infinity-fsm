import { ForbiddenError } from '../errors/AppError.js';

export function requireRole(...allowedRoles) {
  return (req, _res, next) => {
    if (!req.auth) {
      return next(new ForbiddenError('Authentication required'));
    }

    const hasRole = req.auth.roles.some((role) => allowedRoles.includes(role));

    if (!hasRole) {
      return next(
        new ForbiddenError('Insufficient role privileges', {
          requiredRoles: allowedRoles,
          userRoles: req.auth.roles,
        })
      );
    }

    return next();
  };
}

export function requirePermission(...requiredPermissions) {
  return (req, _res, next) => {
    if (!req.auth) {
      return next(new ForbiddenError('Authentication required'));
    }

    const missing = requiredPermissions.filter(
      (permission) => !req.auth.permissions.includes(permission)
    );

    if (missing.length > 0) {
      return next(
        new ForbiddenError('Missing required permissions', {
          requiredPermissions,
          missingPermissions: missing,
          userPermissions: req.auth.permissions,
        })
      );
    }

    return next();
  };
}

export function requireAnyPermission(...requiredPermissions) {
  return (req, _res, next) => {
    if (!req.auth) {
      return next(new ForbiddenError('Authentication required'));
    }

    const hasAny = requiredPermissions.some((permission) =>
      req.auth.permissions.includes(permission)
    );

    if (!hasAny) {
      return next(
        new ForbiddenError('Missing required permissions', {
          requiredAny: requiredPermissions,
          userPermissions: req.auth.permissions,
        })
      );
    }

    return next();
  };
}

/**
 * Allow when the authenticated user is the resource owner (param match),
 * or when they hold at least one of [requiredPermissions].
 */
export function requireSelfOrPermission(paramName, ...requiredPermissions) {
  return (req, _res, next) => {
    if (!req.auth) {
      return next(new ForbiddenError('Authentication required'));
    }

    const targetId = req.params?.[paramName]?.toString?.() ?? req.params?.[paramName];
    const selfId = req.auth.userId?.toString?.() ?? req.auth.userId;
    const isSelf = Boolean(targetId && selfId && targetId === selfId);

    if (isSelf) {
      return next();
    }

    const hasPermission = requiredPermissions.some((permission) =>
      req.auth.permissions.includes(permission)
    );

    if (!hasPermission) {
      return next(
        new ForbiddenError('You can only update your own avatar', {
          requiredPermissions,
          userPermissions: req.auth.permissions,
          targetId,
        })
      );
    }

    return next();
  };
}

export default requirePermission;
