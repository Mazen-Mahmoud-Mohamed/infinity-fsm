import { Router } from 'express';
import authenticate from '../../../shared/middleware/authenticate.middleware.js';
import { requirePermission } from '../../../shared/middleware/authorize.middleware.js';
import { validate } from '../../../shared/middleware/validate.middleware.js';
import PERMISSIONS from '../../../shared/constants/permissions.constants.js';
import * as dashboardController from './dashboard.controller.js';
import { summaryValidator } from './dashboard.validator.js';

const router = Router();

router.use(authenticate);

router.get(
  '/summary',
  requirePermission(PERMISSIONS.DASHBOARD_VIEW),
  validate(summaryValidator),
  dashboardController.getSummary
);

export default router;
