import { body, query, param } from 'express-validator';
import { STOCK_MOVEMENT_TYPES } from './models/stockMovement.model.js';

const stockStatusValues = [
  'ALL',
  'IN_STOCK',
  'LOW_STOCK',
  'OUT_OF_STOCK',
  'all',
  'in_stock',
  'low_stock',
  'out_of_stock',
];

const movementTypeValues = [
  'ALL',
  ...STOCK_MOVEMENT_TYPES,
  'all',
  ...STOCK_MOVEMENT_TYPES.map((t) => t.toLowerCase()),
];

export const listPaginationValidator = [
  query('page').optional().isInt({ min: 1 }).toInt(),
  query('limit').optional().isInt({ min: 1, max: 100 }).toInt(),
  query('search').optional().isString().trim().isLength({ max: 120 }),
];

export const listWarehousesValidator = [
  ...listPaginationValidator,
  query('isActive').optional().isIn(['true', 'false', true, false]),
];

export const listSparePartsValidator = [
  ...listPaginationValidator,
  query('category').optional().isString().trim().isLength({ max: 120 }),
  query('stockStatus').optional().isString().trim().isIn(stockStatusValues),
  query('isActive').optional().isIn(['true', 'false', true, false]),
];

export const listMovementsValidator = [
  ...listPaginationValidator,
  query('sparePartId').optional().isMongoId(),
  query('warehouseId').optional().isMongoId(),
  query('type').optional().isString().trim().isIn(movementTypeValues),
];

export const warehouseIdValidator = [
  param('id').isMongoId().withMessage('id must be a valid MongoDB ObjectId'),
];

export const sparePartIdValidator = [
  param('id').isMongoId().withMessage('id must be a valid MongoDB ObjectId'),
];

export const createWarehouseValidator = [
  body('name').isString().trim().notEmpty().isLength({ max: 200 }),
  body('code').isString().trim().notEmpty().isLength({ max: 50 }),
  body('address').optional({ values: 'falsy' }).isString().trim().isLength({ max: 500 }),
  body('description')
    .optional({ values: 'falsy' })
    .isString()
    .trim()
    .isLength({ max: 2000 }),
  body('isActive').optional().isIn(['true', 'false', true, false]),
];

export const updateWarehouseValidator = [
  ...warehouseIdValidator,
  body('name').optional().isString().trim().notEmpty().isLength({ max: 200 }),
  body('code').optional().isString().trim().notEmpty().isLength({ max: 50 }),
  body('address').optional({ values: 'falsy' }).isString().trim().isLength({ max: 500 }),
  body('description')
    .optional({ values: 'falsy' })
    .isString()
    .trim()
    .isLength({ max: 2000 }),
  body('isActive').optional().isIn(['true', 'false', true, false]),
];

export const createSparePartValidator = [
  body('partNumber').isString().trim().notEmpty().isLength({ max: 100 }),
  body('name').isString().trim().notEmpty().isLength({ max: 200 }),
  body('category').optional({ values: 'falsy' }).isString().trim().isLength({ max: 120 }),
  body('description')
    .optional({ values: 'falsy' })
    .isString()
    .trim()
    .isLength({ max: 5000 }),
  body('unit').optional({ values: 'falsy' }).isString().trim().isLength({ max: 40 }),
  body('currentQuantity')
    .optional({ values: 'falsy' })
    .isFloat({ min: 0 })
    .toFloat(),
  body('minimumQuantity')
    .optional({ values: 'falsy' })
    .isFloat({ min: 0 })
    .toFloat(),
  body('barcode').optional({ values: 'falsy' }).isString().trim().isLength({ max: 200 }),
  body('isActive').optional().isIn(['true', 'false', true, false]),
];

export const updateSparePartValidator = [
  ...sparePartIdValidator,
  body('partNumber').optional().isString().trim().notEmpty().isLength({ max: 100 }),
  body('name').optional().isString().trim().notEmpty().isLength({ max: 200 }),
  body('category').optional({ values: 'falsy' }).isString().trim().isLength({ max: 120 }),
  body('description')
    .optional({ values: 'falsy' })
    .isString()
    .trim()
    .isLength({ max: 5000 }),
  body('unit').optional({ values: 'falsy' }).isString().trim().isLength({ max: 40 }),
  body('minimumQuantity')
    .optional({ values: 'falsy' })
    .isFloat({ min: 0 })
    .toFloat(),
  body('barcode').optional({ values: 'falsy' }).isString().trim().isLength({ max: 200 }),
  body('isActive').optional().isIn(['true', 'false', true, false]),
  body('removeImage').optional().isIn(['true', 'false', true, false]),
];

const movementBaseValidator = [
  body('sparePartId').isMongoId().withMessage('sparePartId is required'),
  body('quantity').isFloat({ gt: 0 }).withMessage('quantity must be greater than 0').toFloat(),
  body('reason').optional({ values: 'falsy' }).isString().trim().isLength({ max: 500 }),
  body('notes').optional({ values: 'falsy' }).isString().trim().isLength({ max: 2000 }),
  body('movementDate').optional({ values: 'falsy' }).isISO8601(),
];

export const stockInValidator = [
  ...movementBaseValidator,
  body('warehouseId').isMongoId().withMessage('warehouseId is required'),
];

export const stockOutValidator = [
  ...movementBaseValidator,
  body('warehouseId').isMongoId().withMessage('warehouseId is required'),
];

export const transferValidator = [
  ...movementBaseValidator,
  body('fromWarehouseId').isMongoId().withMessage('fromWarehouseId is required'),
  body('toWarehouseId').isMongoId().withMessage('toWarehouseId is required'),
];

export const adjustmentValidator = [
  ...movementBaseValidator,
  body('warehouseId').isMongoId().withMessage('warehouseId is required'),
  body('reason').isString().trim().notEmpty().isLength({ max: 500 }),
  body('direction')
    .optional({ values: 'falsy' })
    .isString()
    .trim()
    .isIn(['INCREASE', 'DECREASE', 'increase', 'decrease']),
];
