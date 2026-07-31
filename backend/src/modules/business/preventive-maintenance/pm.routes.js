import { Router } from 'express';
import authenticate from '../../../shared/middleware/authenticate.middleware.js';
import { requirePermission } from '../../../shared/middleware/authorize.middleware.js';
import { validate } from '../../../shared/middleware/validate.middleware.js';
import PERMISSIONS from '../../../shared/constants/permissions.constants.js';
import * as pmController from './pm.controller.js';
import {
  listPlansValidator,
  listSchedulesValidator,
  listHistoryValidator,
  idValidator,
  createPlanValidator,
  updatePlanValidator,
  updateChecklistValidator,
  generateSchedulesValidator,
  completeScheduleValidator,
  cancelScheduleValidator,
} from './pm.validator.js';

const router = Router();

router.use(authenticate);

router.get(
  '/dashboard',
  requirePermission(PERMISSIONS.PM_VIEW),
  pmController.getDashboard
);

router.get(
  '/history',
  requirePermission(PERMISSIONS.PM_VIEW),
  validate(listHistoryValidator),
  pmController.listHistory
);

router.get(
  '/schedules',
  requirePermission(PERMISSIONS.PM_VIEW),
  validate(listSchedulesValidator),
  pmController.listSchedules
);

router.get(
  '/schedules/:id',
  requirePermission(PERMISSIONS.PM_VIEW),
  validate(idValidator),
  pmController.getSchedule
);

router.post(
  '/schedules/:id/complete',
  requirePermission(PERMISSIONS.PM_UPDATE),
  validate(completeScheduleValidator),
  pmController.completeSchedule
);

router.post(
  '/schedules/:id/cancel',
  requirePermission(PERMISSIONS.PM_UPDATE),
  validate(cancelScheduleValidator),
  pmController.cancelSchedule
);

router.get(
  '/plans',
  requirePermission(PERMISSIONS.PM_VIEW),
  validate(listPlansValidator),
  pmController.listPlans
);

router.post(
  '/plans',
  requirePermission(PERMISSIONS.PM_CREATE),
  validate(createPlanValidator),
  pmController.createPlan
);

router.get(
  '/plans/:id',
  requirePermission(PERMISSIONS.PM_VIEW),
  validate(idValidator),
  pmController.getPlan
);

router.put(
  '/plans/:id',
  requirePermission(PERMISSIONS.PM_UPDATE),
  validate(updatePlanValidator),
  pmController.updatePlan
);

router.delete(
  '/plans/:id',
  requirePermission(PERMISSIONS.PM_DELETE),
  validate(idValidator),
  pmController.deletePlan
);

router.put(
  '/plans/:id/checklist',
  requirePermission(PERMISSIONS.PM_UPDATE),
  validate(updateChecklistValidator),
  pmController.updateChecklist
);

router.post(
  '/plans/:id/generate-schedules',
  requirePermission(PERMISSIONS.PM_UPDATE),
  validate(generateSchedulesValidator),
  pmController.generateSchedules
);

export default router;
