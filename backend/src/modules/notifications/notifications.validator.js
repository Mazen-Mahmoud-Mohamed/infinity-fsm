import { body, param, query } from 'express-validator';

export const listNotificationsValidator = [
  query('page').optional().isInt({ min: 1 }),
  query('limit').optional().isInt({ min: 1, max: 100 }),
];

export const notificationIdValidator = [
  param('id').isMongoId().withMessage('Invalid notification id'),
];

export const registerDeviceTokenValidator = [
  body('token').isString().trim().isLength({ min: 20, max: 4096 }),
  body('platform')
    .optional()
    .isString()
    .isIn(['android', 'ios', 'windows', 'web', 'unknown']),
  body('locale').optional().isString().isLength({ min: 2, max: 16 }),
  body('deviceId').optional().isString().isLength({ max: 128 }),
];

export const deactivateDeviceTokenValidator = [
  body('token').isString().trim().isLength({ min: 20, max: 4096 }),
];
