import { Router } from 'express';
import authenticate from '../../../shared/middleware/authenticate.middleware.js';
import { requirePermission } from '../../../shared/middleware/authorize.middleware.js';
import { validate } from '../../../shared/middleware/validate.middleware.js';
import { upload } from '../../../config/multer.config.js';
import PERMISSIONS from '../../../shared/constants/permissions.constants.js';
import * as settingsController from './settings.controller.js';
import {
  updateOrganizationSettingsValidator,
  updateOvertimeSettingsValidator,
  updateTechnicianInterfaceSettingsValidator,
  listHolidaysValidator,
  createHolidayValidator,
  replaceHolidaysValidator,
  deleteHolidayValidator,
} from './settings.validator.js';

const router = Router();

router.use(authenticate);

router.get(
  '/organization',
  requirePermission(PERMISSIONS.SETTINGS_VIEW),
  settingsController.getOrganizationSettings
);

router.put(
  '/organization',
  requirePermission(PERMISSIONS.SETTINGS_MANAGE),
  validate(updateOrganizationSettingsValidator),
  settingsController.updateOrganizationSettings
);

router.post(
  '/organization/logo',
  requirePermission(PERMISSIONS.SETTINGS_MANAGE),
  upload.single('logo'),
  settingsController.uploadOrganizationLogo
);

router.get(
  '/system',
  requirePermission(PERMISSIONS.SETTINGS_VIEW),
  settingsController.getSystemInfo
);

router.get(
  '/overtime/config',
  settingsController.getOvertimeMediaConfig
);

router.get(
  '/overtime/voice-duration',
  settingsController.getOvertimeVoiceDurationConfig
);

router.get(
  '/overtime',
  requirePermission(PERMISSIONS.SETTINGS_VIEW),
  settingsController.getOvertimeSettings
);

router.put(
  '/overtime',
  requirePermission(PERMISSIONS.SETTINGS_MANAGE),
  validate(updateOvertimeSettingsValidator),
  settingsController.updateOvertimeSettings
);

router.get(
  '/technician-interface',
  requirePermission(PERMISSIONS.SETTINGS_MANAGE),
  settingsController.getTechnicianInterfaceSettings
);

router.put(
  '/technician-interface',
  requirePermission(PERMISSIONS.SETTINGS_MANAGE),
  validate(updateTechnicianInterfaceSettingsValidator),
  settingsController.updateTechnicianInterfaceSettings
);

router.get(
  '/technician-interface/config',
  settingsController.getTechnicianInterfaceConfig
);

// Official holidays — authenticated company read; manage requires permission.
router.get(
  '/holidays',
  validate(listHolidaysValidator),
  settingsController.listHolidays
);

router.put(
  '/holidays',
  requirePermission(PERMISSIONS.SETTINGS_MANAGE_HOLIDAYS),
  validate(replaceHolidaysValidator),
  settingsController.replaceHolidays
);

router.post(
  '/holidays',
  requirePermission(PERMISSIONS.SETTINGS_MANAGE_HOLIDAYS),
  validate(createHolidayValidator),
  settingsController.createHoliday
);

router.delete(
  '/holidays/:date',
  requirePermission(PERMISSIONS.SETTINGS_MANAGE_HOLIDAYS),
  validate(deleteHolidayValidator),
  settingsController.deleteHoliday
);

export default router;
