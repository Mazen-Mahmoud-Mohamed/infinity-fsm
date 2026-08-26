import { Router } from 'express';
import authenticate from '../../shared/middleware/authenticate.middleware.js';
import { validate } from '../../shared/middleware/validate.middleware.js';
import * as controller from './notifications.controller.js';
import {
  listNotificationsValidator,
  notificationIdValidator,
  registerDeviceTokenValidator,
  deactivateDeviceTokenValidator,
} from './notifications.validator.js';

const router = Router();

router.use(authenticate);

router.get(
  '/',
  validate(listNotificationsValidator),
  controller.listNotifications
);

router.get('/unread-count', controller.unreadCount);

router.put('/read-all', controller.markAllRead);

router.put(
  '/:id/read',
  validate(notificationIdValidator),
  controller.markRead
);

router.post(
  '/device-tokens',
  validate(registerDeviceTokenValidator),
  controller.registerDeviceToken
);

router.delete(
  '/device-tokens',
  validate(deactivateDeviceTokenValidator),
  controller.deactivateDeviceToken
);

export default router;
