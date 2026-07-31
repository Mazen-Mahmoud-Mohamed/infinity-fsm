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

export default requirePermission;
