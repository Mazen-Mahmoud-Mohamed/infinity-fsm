import { Router } from 'express';
import authenticate from '../../../shared/middleware/authenticate.middleware.js';
import { requirePermission } from '../../../shared/middleware/authorize.middleware.js';
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
  updateGpsAddressValidator,
} from './attendance.validator.js';

const router = Router();

router.use(authenticate);
router.use(requirePermission(PERMISSIONS.ATTENDANCE_MANAGE_OWN));

router.post(
  '/clock-in',
  upload.single('selfie'),
  validate(clockInValidator),
  attendanceController.clockIn
);

router.post(
  '/clock-out',
  upload.single('selfie'),
  validate(clockOutValidator),
  attendanceController.clockOut
);

router.post(
  '/break-start',
  validate(breakStartValidator),
  attendanceController.breakStart
);

router.post(
  '/break-end',
  validate(breakEndValidator),
  attendanceController.breakEnd
);

router.post(
  '/gps-address',
  validate(updateGpsAddressValidator),
  attendanceController.updateGpsAddress
);

router.get('/status', attendanceController.getStatus);
router.get('/today', attendanceController.getToday);
router.get('/history', validate(historyValidator), attendanceController.getHistory);

export default router;
