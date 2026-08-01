import { Router } from 'express';
import authenticate from '../../../shared/middleware/authenticate.middleware.js';
import {
  requireAnyPermission,
  requirePermission,
} from '../../../shared/middleware/authorize.middleware.js';
import { validate } from '../../../shared/middleware/validate.middleware.js';
import upload from '../../../config/multer.config.js';
import PERMISSIONS from '../../../shared/constants/permissions.constants.js';
import * as attendanceController from './attendance.controller.js';
import {
  clockInValidator,
  clockOutValidator,
  breakStartValidator,
  breakEndValidator,
  historyValidator,
  listAttendanceValidator,
  attendanceIdValidator,
  updateGpsAddressValidator,
} from './attendance.validator.js';

const router = Router();

router.use(authenticate);

router.post(
  '/clock-in',
  requirePermission(PERMISSIONS.ATTENDANCE_MANAGE_OWN),
  upload.single('selfie'),
  validate(clockInValidator),
  attendanceController.clockIn
);

router.post(
  '/clock-out',
  requirePermission(PERMISSIONS.ATTENDANCE_MANAGE_OWN),
  upload.single('selfie'),
  validate(clockOutValidator),
  attendanceController.clockOut
);

router.post(
  '/break-start',
  requirePermission(PERMISSIONS.ATTENDANCE_MANAGE_OWN),
  validate(breakStartValidator),
  attendanceController.breakStart
);

router.post(
  '/break-end',
  requirePermission(PERMISSIONS.ATTENDANCE_MANAGE_OWN),
  validate(breakEndValidator),
  attendanceController.breakEnd
);

router.post(
  '/gps-address',
  requirePermission(PERMISSIONS.ATTENDANCE_MANAGE_OWN),
  validate(updateGpsAddressValidator),
  attendanceController.updateGpsAddress
);

router.get(
  '/status',
  requireAnyPermission(
    PERMISSIONS.ATTENDANCE_MANAGE_OWN,
    PERMISSIONS.ATTENDANCE_VIEW_OWN
  ),
  attendanceController.getStatus
);

router.get(
  '/today',
  requireAnyPermission(
    PERMISSIONS.ATTENDANCE_MANAGE_OWN,
    PERMISSIONS.ATTENDANCE_VIEW_OWN
  ),
  attendanceController.getToday
);

router.get(
  '/history',
  requireAnyPermission(
    PERMISSIONS.ATTENDANCE_MANAGE_OWN,
    PERMISSIONS.ATTENDANCE_VIEW_OWN
  ),
  validate(historyValidator),
  attendanceController.getHistory
);

router.get(
  '/',
  requireAnyPermission(
    PERMISSIONS.ATTENDANCE_VIEW_ALL,
    PERMISSIONS.ATTENDANCE_VIEW_TEAM
  ),
  validate(listAttendanceValidator),
  attendanceController.listRecords
);

router.get(
  '/:id',
  requireAnyPermission(
    PERMISSIONS.ATTENDANCE_VIEW_ALL,
    PERMISSIONS.ATTENDANCE_VIEW_TEAM,
    PERMISSIONS.ATTENDANCE_VIEW_OWN
  ),
  validate(attendanceIdValidator),
  attendanceController.getRecordById
);

export default router;
