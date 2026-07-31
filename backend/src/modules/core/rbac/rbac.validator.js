import { body, param, query } from 'express-validator';

export const listRolesValidator = [
  query('page').optional().isInt({ min: 1 }).toInt(),
  query('limit').optional().isInt({ min: 1, max: 100 }).toInt(),
  query('search').optional().isString().trim().isLength({ max: 200 }),
  query('isActive').optional().isIn(['true', 'false', true, false]),
  query('isSystem').optional().isIn(['true', 'false', true, false]),
];

export const idValidator = [
  param('id').isMongoId().withMessage('Invalid role id'),
];

export const createRoleValidator = [
  body('name').isString().trim().notEmpty().isLength({ max: 120 }),
  body('slug').optional().isString().trim().isLength({ max: 80 }),
  body('description').optional({ nullable: true }).isString().trim().isLength({ max: 2000 }),
  body('permissions').optional().isArray(),
  body('permissions.*').optional().isString().trim(),
  body('color').optional().isString().trim().isLength({ max: 32 }),
  body('isActive').optional().isBoolean().toBoolean(),
];

export const updateRoleValidator = [
  ...idValidator,
  body('name').optional().isString().trim().notEmpty().isLength({ max: 120 }),
  body('slug').optional().isString().trim().isLength({ max: 80 }),
  body('description').optional({ nullable: true }).isString().trim().isLength({ max: 2000 }),
  body('permissions').optional().isArray(),
  body('permissions.*').optional().isString().trim(),
  body('color').optional().isString().trim().isLength({ max: 32 }),
  body('isActive').optional().isBoolean().toBoolean(),
];

export const setStatusValidator = [
  ...idValidator,
  body('isActive').isBoolean().toBoolean(),
];

export const cloneRoleValidator = [
  ...idValidator,
  body('name').optional().isString().trim().notEmpty().isLength({ max: 120 }),
  body('slug').optional().isString().trim().isLength({ max: 80 }),
];

export const assignUsersValidator = [
  ...idValidator,
  body('userIds').isArray({ min: 1 }),
  body('userIds.*').isMongoId().withMessage('Invalid user id'),
];

export const listRoleUsersValidator = [
  ...idValidator,
  query('page').optional().isInt({ min: 1 }).toInt(),
  query('limit').optional().isInt({ min: 1, max: 100 }).toInt(),
  query('search').optional().isString().trim().isLength({ max: 200 }),
];
