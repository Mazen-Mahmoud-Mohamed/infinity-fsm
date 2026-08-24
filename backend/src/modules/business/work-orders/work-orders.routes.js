import { Router } from 'express';
import authenticate from '../../../shared/middleware/authenticate.middleware.js';
import {
  requireAnyPermission,
  requirePermission,
} from '../../../shared/middleware/authorize.middleware.js';
import { validate } from '../../../shared/middleware/validate.middleware.js';
import { workOrderMultipart, workOrderUpload } from '../../../config/multer.config.js';
import PERMISSIONS from '../../../shared/constants/permissions.constants.js';
import * as workOrdersController from './work-orders.controller.js';
import {
  listWorkOrdersValidator,
  workOrderIdValidator,
  createWorkOrderValidator,
  updateWorkOrderValidator,
  assignWorkOrderValidator,
  rejectWorkOrderValidator,
  completeWorkOrderValidator,
  cancelWorkOrderValidator,
  startWorkOrderValidator,
  beforeWorkValidator,
  progressNoteValidator,
  removePhotoValidator,
} from './work-orders.validator.js';

const router = Router();

router.use(authenticate);

router.get(
  '/my-assignments',
  requirePermission(PERMISSIONS.WORK_ORDERS_VIEW_OWN),
  validate(listWorkOrdersValidator),
  workOrdersController.listMyAssignments
);

router.get(
  '/',
  requireAnyPermission(
    PERMISSIONS.WORK_ORDERS_VIEW_TEAM,
    PERMISSIONS.WORK_ORDERS_VIEW_ALL
  ),
  validate(listWorkOrdersValidator),
  workOrdersController.listWorkOrders
);

router.post(
  '/',
  requirePermission(PERMISSIONS.WORK_ORDERS_CREATE),
  workOrderMultipart,
  validate(createWorkOrderValidator),
  workOrdersController.createWorkOrder
);

router.get(
  '/:id',
  requireAnyPermission(
    PERMISSIONS.WORK_ORDERS_VIEW_OWN,
    PERMISSIONS.WORK_ORDERS_VIEW_TEAM,
    PERMISSIONS.WORK_ORDERS_VIEW_ALL
  ),
  validate(workOrderIdValidator),
  workOrdersController.getWorkOrder
);

router.put(
  '/:id',
  requirePermission(PERMISSIONS.WORK_ORDERS_UPDATE),
  workOrderMultipart,
  validate(updateWorkOrderValidator),
  workOrdersController.updateWorkOrder
);

router.delete(
  '/:id',
  requirePermission(PERMISSIONS.WORK_ORDERS_UPDATE),
  validate(workOrderIdValidator),
  workOrdersController.deleteWorkOrder
);

router.post(
  '/:id/assign',
  requirePermission(PERMISSIONS.WORK_ORDERS_ASSIGN),
  validate(assignWorkOrderValidator),
  workOrdersController.assignWorkOrder
);

router.post(
  '/:id/accept',
  requirePermission(PERMISSIONS.WORK_ORDERS_VIEW_OWN),
  validate(workOrderIdValidator),
  workOrdersController.acceptWorkOrder
);

router.post(
  '/:id/reject',
  requirePermission(PERMISSIONS.WORK_ORDERS_VIEW_OWN),
  validate(rejectWorkOrderValidator),
  workOrdersController.rejectWorkOrder
);

router.post(
  '/:id/before-work',
  requirePermission(PERMISSIONS.WORK_ORDERS_VIEW_OWN),
  workOrderUpload.array('photos', 5),
  validate(beforeWorkValidator),
  workOrdersController.saveBeforeWork
);

router.post(
  '/:id/start',
  requirePermission(PERMISSIONS.WORK_ORDERS_VIEW_OWN),
  validate(startWorkOrderValidator),
  workOrdersController.startWorkOrder
);

router.post(
  '/:id/progress-notes',
  requirePermission(PERMISSIONS.WORK_ORDERS_VIEW_OWN),
  validate(progressNoteValidator),
  workOrdersController.addProgressNote
);

router.post(
  '/:id/progress-photos',
  requirePermission(PERMISSIONS.WORK_ORDERS_VIEW_OWN),
  workOrderUpload.array('photos', 5),
  validate(workOrderIdValidator),
  workOrdersController.addProgressPhotos
);

router.post(
  '/:id/after-photos',
  requirePermission(PERMISSIONS.WORK_ORDERS_VIEW_OWN),
  workOrderUpload.array('photos', 5),
  validate(workOrderIdValidator),
  workOrdersController.addAfterPhotos
);

router.delete(
  '/:id/photos',
  requirePermission(PERMISSIONS.WORK_ORDERS_VIEW_OWN),
  validate(removePhotoValidator),
  workOrdersController.removePhoto
);

router.post(
  '/:id/complete',
  requirePermission(PERMISSIONS.WORK_ORDERS_COMPLETE),
  validate(completeWorkOrderValidator),
  workOrdersController.completeWorkOrder
);

router.post(
  '/:id/cancel',
  requirePermission(PERMISSIONS.WORK_ORDERS_CANCEL),
  validate(cancelWorkOrderValidator),
  workOrdersController.cancelWorkOrder
);

export default router;
