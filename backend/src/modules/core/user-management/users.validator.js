import { body, query, param } from 'express-validator';
import { USER_STATUSES } from '../organization/models/user.model.js';

const statusValues = [
  'ALL',
  'all',
  ...USER_STATUSES,
  ...USER_STATUSES.map((v) => v.toLowerCase()),
];

export const listUsersValidator = [
  query('page').optional().isInt({ min: 1 }).toInt(),
  query('limit').optional().isInt({ min: 1, max: 100 }).toInt(),
  query('search').optional().isString().trim().isLength({ max: 120 }),
  query('status').optional().isString().trim().isIn(statusValues),
  query('role').optional().isString().trim(),
  query('departmentId').optional({ values: 'falsy' }).isMongoId(),
  query('branchId').optional({ values: 'falsy' }).isMongoId(),
];

export const listActivityValidator = [
  query('page').optional().isInt({ min: 1 }).toInt(),
  query('limit').optional().isInt({ min: 1, max: 100 }).toInt(),
  query('userId').optional({ values: 'falsy' }).isMongoId(),
];

export const idValidator = [
  param('id').isMongoId().withMessage('id must be a valid MongoDB ObjectId'),
];

export const createUserValidator = [
  body('firstName').isString().trim().notEmpty().isLength({ max: 100 }),
  body('lastName').isString().trim().notEmpty().isLength({ max: 100 }),
  body('username').isString().trim().notEmpty().isLength({ max: 80 }),
  body('email').isEmail().normalizeEmail(),
  body('password').isString().isLength({ min: 8, max: 128 }),
  body('phone').optional({ values: 'falsy' }).isString().trim().isLength({ max: 40 }),
  body('jobTitle')
    .optional({ values: 'falsy' })
    .isString()
    .trim()
    .isLength({ max: 200 }),
  body('employeeId')
    .optional({ values: 'falsy' })
    .isString()
    .trim()
    .isLength({ max: 50 }),
  body('role').optional().isString().trim().isLength({ max: 80 }),
  body('roles').optional().isArray({ min: 1 }),
  body('roles.*').optional().isString().trim().isLength({ max: 80 }),
  body('branchId').isMongoId(),
  body('regionId').isMongoId(),
  body('cityId').isMongoId(),
  body('departmentId').isMongoId(),
  body('teamId').optional({ values: 'falsy' }).isMongoId(),
  body('positionId').optional({ values: 'falsy' }).isMongoId(),
  body('status').optional().isString().trim().isIn(statusValues.filter((v) => v.toUpperCase() !== 'ALL')),
];

export const updateUserValidator = [
  ...idValidator,
  body('firstName').optional().isString().trim().notEmpty().isLength({ max: 100 }),
  body('lastName').optional().isString().trim().notEmpty().isLength({ max: 100 }),
  body('username').optional().isString().trim().notEmpty().isLength({ max: 80 }),
  body('email').optional().isEmail().normalizeEmail(),
  body('phone').optional({ values: 'falsy' }).isString().trim().isLength({ max: 40 }),
  body('jobTitle')
    .optional({ values: 'falsy' })
    .isString()
    .trim()
    .isLength({ max: 200 }),
  body('employeeId')
    .optional({ values: 'falsy' })
    .isString()
    .trim()
    .isLength({ max: 50 }),
  body('role').optional().isString().trim(),
  body('roles').optional().isArray({ min: 1 }),
  body('branchId').optional().isMongoId(),
  body('regionId').optional().isMongoId(),
  body('cityId').optional().isMongoId(),
  body('departmentId').optional().isMongoId(),
  body('teamId').optional({ values: 'falsy' }).isMongoId(),
  body('positionId').optional({ values: 'falsy' }).isMongoId(),
  body('status').optional().isString().trim(),
];

export const setStatusValidator = [
  ...idValidator,
  body('status')
    .isString()
    .trim()
    .isIn(USER_STATUSES)
    .withMessage(`status must be one of: ${USER_STATUSES.join(', ')}`),
];

export const resetPasswordValidator = [
  ...idValidator,
  body('newPassword').isString().isLength({ min: 8, max: 128 }),
];

export const changePasswordValidator = [
  body('currentPassword').isString().notEmpty(),
  body('newPassword').isString().isLength({ min: 8, max: 128 }),
];
