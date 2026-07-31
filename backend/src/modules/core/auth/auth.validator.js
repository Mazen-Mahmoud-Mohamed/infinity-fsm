import { body } from 'express-validator';

export const loginValidator = [
  body('email')
    .trim()
    .isEmail()
    .withMessage('Valid email is required')
    .normalizeEmail(),
  body('password')
    .isString()
    .notEmpty()
    .withMessage('Password is required')
    .isLength({ min: 8 })
    .withMessage('Password must be at least 8 characters'),
  body('deviceId')
    .trim()
    .notEmpty()
    .withMessage('Device ID is required'),
  body('deviceInfo')
    .optional()
    .isObject()
    .withMessage('Device info must be an object'),
  body('deviceInfo.platform')
    .optional()
    .isString(),
  body('deviceInfo.manufacturer')
    .optional()
    .isString(),
  body('deviceInfo.phoneModel')
    .optional()
    .isString(),
  body('deviceInfo.osVersion')
    .optional()
    .isString(),
  body('deviceInfo.appVersion')
    .optional()
    .isString(),
];

export const refreshValidator = [
  body('refreshToken')
    .isString()
    .notEmpty()
    .withMessage('Refresh token is required'),
  body('deviceId')
    .trim()
    .notEmpty()
    .withMessage('Device ID is required'),
];

export const logoutValidator = [
  body('refreshToken')
    .optional()
    .isString()
    .withMessage('Refresh token must be a string'),
  body('deviceId')
    .trim()
    .notEmpty()
    .withMessage('Device ID is required'),
];
