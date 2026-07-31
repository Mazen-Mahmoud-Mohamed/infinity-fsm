import { Router } from 'express';
import authenticate from '../../../shared/middleware/authenticate.middleware.js';
import { requirePermission } from '../../../shared/middleware/authorize.middleware.js';
import { validate } from '../../../shared/middleware/validate.middleware.js';
import { upload } from '../../../config/multer.config.js';
import PERMISSIONS from '../../../shared/constants/permissions.constants.js';
import * as reportsController from './reports.controller.js';
import {
  listReportsValidator,
  listSignaturesValidator,
  idValidator,
  createSignatureValidator,
  generateReportValidator,
} from './reports.validator.js';

const router = Router();

router.use(authenticate);

router.get(
  '/dashboard',
  requirePermission(PERMISSIONS.REPORTS_VIEW),
  reportsController.getDashboard
);

router.get(
  '/signatures',
  requirePermission(PERMISSIONS.REPORTS_VIEW),
  validate(listSignaturesValidator),
  reportsController.listSignatures
);

router.post(
  '/signatures',
  requirePermission(PERMISSIONS.REPORTS_GENERATE),
  upload.single('signature'),
  validate(createSignatureValidator),
  reportsController.createSignature
);

router.get(
  '/signatures/:id',
  requirePermission(PERMISSIONS.REPORTS_VIEW),
  validate(idValidator),
  reportsController.getSignature
);

router.delete(
  '/signatures/:id',
  requirePermission(PERMISSIONS.REPORTS_GENERATE),
  validate(idValidator),
  reportsController.deleteSignature
);

router.get(
  '/',
  requirePermission(PERMISSIONS.REPORTS_VIEW),
  validate(listReportsValidator),
  reportsController.listReports
);

router.post(
  '/generate',
  requirePermission(PERMISSIONS.REPORTS_GENERATE),
  validate(generateReportValidator),
  reportsController.generateReport
);

router.get(
  '/:id/download',
  requirePermission(PERMISSIONS.REPORTS_DOWNLOAD),
  validate(idValidator),
  reportsController.downloadReport
);

router.get(
  '/:id',
  requirePermission(PERMISSIONS.REPORTS_VIEW),
  validate(idValidator),
  reportsController.getReport
);

export default router;
