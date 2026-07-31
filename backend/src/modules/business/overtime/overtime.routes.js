import { Router } from 'express';
import authenticate from '../../../shared/middleware/authenticate.middleware.js';
import {
  requireAnyPermission,
  requirePermission,
} from '../../../shared/middleware/authorize.middleware.js';
import { validate } from '../../../shared/middleware/validate.middleware.js';
import upload from '../../../config/multer.config.js';
import PERMISSIONS from '../../../shared/constants/permissions.constants.js';
import * as overtimeController from './overtime.controller.js';
import {
  startOvertimeValidator,
  endOvertimeValidator,
  listOvertimeValidator,
  rejectOvertimeValidator,
  overtimeIdValidator,
  updateOvertimeGpsAddressValidator,
} from './overtime.validator.js';

const router = Router();

router.use(authenticate);

router.get(
  '/running',
  requireAnyPermission(
    PERMISSIONS.OVERTIME_VIEW_OWN,
    PERMISSIONS.OVERTIME_VIEW_TEAM,
    PERMISSIONS.OVERTIME_VIEW_ALL
  ),
  overtimeController.getRunning
);

router.get(
  '/mine',
  requireAnyPermission(PERMISSIONS.OVERTIME_VIEW_OWN, PERMISSIONS.OVERTIME_VIEW_ALL),
  validate(listOvertimeValidator),
  overtimeController.listMine
);

router.get(
  '/stats',
  requirePermission(PERMISSIONS.OVERTIME_VIEW_ALL),
  overtimeController.getDashboardStats
);

router.get(
  '/',
  requirePermission(PERMISSIONS.OVERTIME_VIEW_ALL),
  validate(listOvertimeValidator),
  overtimeController.listSessions
);

router.post(
  '/start',
  requireAnyPermission(PERMISSIONS.OVERTIME_START, PERMISSIONS.OVERTIME_CREATE),
  upload.single('photo'),
  validate(startOvertimeValidator),
  overtimeController.startSession
);

router.get(
  '/:id',
  requireAnyPermission(
    PERMISSIONS.OVERTIME_VIEW_OWN,
    PERMISSIONS.OVERTIME_VIEW_ALL
  ),
  validate(overtimeIdValidator),
  overtimeController.getSession
);

router.post(
  '/:id/end',
  requireAnyPermission(PERMISSIONS.OVERTIME_END, PERMISSIONS.OVERTIME_CREATE),
  upload.single('photo'),
  validate([...overtimeIdValidator, ...endOvertimeValidator]),
  overtimeController.endSession
);

router.patch(
  '/:id/gps-address',
  requireAnyPermission(
    PERMISSIONS.OVERTIME_START,
    PERMISSIONS.OVERTIME_END,
    PERMISSIONS.OVERTIME_CREATE,
    PERMISSIONS.OVERTIME_VIEW_OWN
  ),
  validate(updateOvertimeGpsAddressValidator),
  overtimeController.updateGpsAddress
);

router.post(
  '/:id/approve',
  requirePermission(PERMISSIONS.OVERTIME_APPROVE),
  validate(overtimeIdValidator),
  overtimeController.approveSession
);

router.post(
  '/:id/reject',
  requirePermission(PERMISSIONS.OVERTIME_REJECT),
  validate([...overtimeIdValidator, ...rejectOvertimeValidator]),
  overtimeController.rejectSession
);

export default router;
