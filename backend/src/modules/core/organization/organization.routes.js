import { Router } from 'express';
import authenticate from '../../../shared/middleware/authenticate.middleware.js';
import { requirePermission } from '../../../shared/middleware/authorize.middleware.js';
import PERMISSIONS from '../../../shared/constants/permissions.constants.js';
import * as organizationController from './organization.controller.js';

const router = Router();

router.use(authenticate);

router.get('/me/context', organizationController.getMyContext);
router.get('/summary', organizationController.getSummary);

router.get(
  '/companies',
  requirePermission(PERMISSIONS.ORGANIZATION_VIEW),
  organizationController.listCompanies
);
router.get(
  '/companies/:id',
  requirePermission(PERMISSIONS.ORGANIZATION_VIEW),
  organizationController.getCompany
);

router.get(
  '/branches',
  requirePermission(PERMISSIONS.ORGANIZATION_VIEW),
  organizationController.listBranches
);
router.get(
  '/branches/:id',
  requirePermission(PERMISSIONS.ORGANIZATION_VIEW),
  organizationController.getBranch
);

router.get(
  '/departments',
  requirePermission(PERMISSIONS.ORGANIZATION_VIEW),
  organizationController.listDepartments
);
router.get(
  '/departments/:id',
  requirePermission(PERMISSIONS.ORGANIZATION_VIEW),
  organizationController.getDepartment
);

router.get(
  '/teams',
  requirePermission(PERMISSIONS.ORGANIZATION_VIEW),
  organizationController.listTeams
);
router.get(
  '/teams/:id',
  requirePermission(PERMISSIONS.ORGANIZATION_VIEW),
  organizationController.getTeam
);

router.get(
  '/positions',
  requirePermission(PERMISSIONS.ORGANIZATION_VIEW),
  organizationController.listPositions
);
router.get(
  '/positions/:id',
  requirePermission(PERMISSIONS.ORGANIZATION_VIEW),
  organizationController.getPosition
);

router.get(
  '/users',
  requirePermission(PERMISSIONS.ORGANIZATION_VIEW),
  organizationController.listUsers
);
router.get(
  '/users/:id',
  requirePermission(PERMISSIONS.ORGANIZATION_VIEW),
  organizationController.getUser
);

export default router;
