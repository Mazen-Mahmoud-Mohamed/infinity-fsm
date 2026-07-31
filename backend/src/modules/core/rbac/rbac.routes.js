import { Router } from 'express';
import authenticate from '../../../shared/middleware/authenticate.middleware.js';
import { requirePermission } from '../../../shared/middleware/authorize.middleware.js';
import { validate } from '../../../shared/middleware/validate.middleware.js';
import PERMISSIONS from '../../../shared/constants/permissions.constants.js';
import * as rbacController from './rbac.controller.js';
import {
  listRolesValidator,
  idValidator,
  createRoleValidator,
  updateRoleValidator,
  setStatusValidator,
  cloneRoleValidator,
  assignUsersValidator,
  listRoleUsersValidator,
} from './rbac.validator.js';

const router = Router();

router.use(authenticate);

router.get(
  '/dashboard',
  requirePermission(PERMISSIONS.ROLES_VIEW),
  rbacController.getDashboard
);

router.get(
  '/permissions',
  requirePermission(PERMISSIONS.ROLES_VIEW),
  rbacController.getPermissionCatalog
);

router.get(
  '/',
  requirePermission(PERMISSIONS.ROLES_VIEW),
  validate(listRolesValidator),
  rbacController.listRoles
);

router.post(
  '/',
  requirePermission(PERMISSIONS.ROLES_CREATE),
  validate(createRoleValidator),
  rbacController.createRole
);

router.get(
  '/:id',
  requirePermission(PERMISSIONS.ROLES_VIEW),
  validate(idValidator),
  rbacController.getRole
);

router.put(
  '/:id',
  requirePermission(PERMISSIONS.ROLES_UPDATE),
  validate(updateRoleValidator),
  rbacController.updateRole
);

router.patch(
  '/:id/status',
  requirePermission(PERMISSIONS.ROLES_UPDATE),
  validate(setStatusValidator),
  rbacController.setRoleStatus
);

router.delete(
  '/:id',
  requirePermission(PERMISSIONS.ROLES_DELETE),
  validate(idValidator),
  rbacController.deleteRole
);

router.post(
  '/:id/clone',
  requirePermission(PERMISSIONS.ROLES_CREATE),
  validate(cloneRoleValidator),
  rbacController.cloneRole
);

router.get(
  '/:id/users',
  requirePermission(PERMISSIONS.ROLES_VIEW),
  validate(listRoleUsersValidator),
  rbacController.listRoleUsers
);

router.post(
  '/:id/assign-users',
  requirePermission(PERMISSIONS.ROLES_UPDATE),
  validate(assignUsersValidator),
  rbacController.assignRoleToUsers
);

export default router;
