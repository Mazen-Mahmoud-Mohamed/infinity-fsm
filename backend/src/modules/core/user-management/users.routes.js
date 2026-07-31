import { Router } from 'express';
import authenticate from '../../../shared/middleware/authenticate.middleware.js';
import { requirePermission } from '../../../shared/middleware/authorize.middleware.js';
import { validate } from '../../../shared/middleware/validate.middleware.js';
import { upload } from '../../../config/multer.config.js';
import PERMISSIONS from '../../../shared/constants/permissions.constants.js';
import * as usersController from './users.controller.js';
import {
  listUsersValidator,
  listActivityValidator,
  idValidator,
  createUserValidator,
  updateUserValidator,
  setStatusValidator,
  resetPasswordValidator,
  changePasswordValidator,
} from './users.validator.js';

const router = Router();

router.use(authenticate);

router.get(
  '/dashboard',
  requirePermission(PERMISSIONS.USERS_VIEW),
  usersController.getDashboard
);

router.get(
  '/activity',
  requirePermission(PERMISSIONS.USERS_VIEW),
  validate(listActivityValidator),
  usersController.listActivity
);

router.post(
  '/me/change-password',
  validate(changePasswordValidator),
  usersController.changeOwnPassword
);

router.get(
  '/',
  requirePermission(PERMISSIONS.USERS_VIEW),
  validate(listUsersValidator),
  usersController.listUsers
);

router.post(
  '/',
  requirePermission(PERMISSIONS.USERS_CREATE),
  validate(createUserValidator),
  usersController.createUser
);

router.get(
  '/:id',
  requirePermission(PERMISSIONS.USERS_VIEW),
  validate(idValidator),
  usersController.getUser
);

router.put(
  '/:id',
  requirePermission(PERMISSIONS.USERS_UPDATE),
  validate(updateUserValidator),
  usersController.updateUser
);

router.patch(
  '/:id/status',
  requirePermission(PERMISSIONS.USERS_UPDATE),
  validate(setStatusValidator),
  usersController.setUserStatus
);

router.delete(
  '/:id',
  requirePermission(PERMISSIONS.USERS_DELETE),
  validate(idValidator),
  usersController.deleteUser
);

router.post(
  '/:id/reset-password',
  requirePermission(PERMISSIONS.USERS_RESET_PASSWORD),
  validate(resetPasswordValidator),
  usersController.resetPassword
);

router.post(
  '/:id/avatar',
  requirePermission(PERMISSIONS.USERS_UPDATE),
  upload.single('avatar'),
  validate(idValidator),
  usersController.uploadAvatar
);

export default router;
