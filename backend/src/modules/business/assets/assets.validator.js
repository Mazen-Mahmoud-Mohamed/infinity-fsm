import { body, query, param } from 'express-validator';
import { ASSET_STATUSES } from './models/asset.model.js';
import { ASSET_HISTORY_TYPES } from './models/assetHistory.model.js';

const statusValues = [
  'ALL',
  ...ASSET_STATUSES,
  'all',
  ...ASSET_STATUSES.map((s) => s.toLowerCase()),
];

const historyTypeValues = [
  'ALL',
  ...ASSET_HISTORY_TYPES,
  'all',
  ...ASSET_HISTORY_TYPES.map((t) => t.toLowerCase()),
];

export const listPaginationValidator = [
  query('page').optional().isInt({ min: 1 }).toInt(),
  query('limit').optional().isInt({ min: 1, max: 100 }).toInt(),
  query('search').optional().isString().trim().isLength({ max: 120 }),
];

export const listCategoriesValidator = [
  ...listPaginationValidator,
  query('isActive').optional().isIn(['true', 'false', true, false]),
];

export const listAssetsValidator = [
  ...listPaginationValidator,
  query('status').optional().isString().trim().isIn(statusValues),
  query('categoryId').optional().isMongoId(),
  query('branchId').optional().isMongoId(),
];

export const listHistoryValidator = [
  ...listPaginationValidator,
  query('assetId').optional().isMongoId(),
  query('type').optional().isString().trim().isIn(historyTypeValues),
];

export const idValidator = [
  param('id').isMongoId().withMessage('id must be a valid MongoDB ObjectId'),
];

export const createCategoryValidator = [
  body('name').isString().trim().notEmpty().isLength({ max: 200 }),
  body('code').isString().trim().notEmpty().isLength({ max: 50 }),
  body('description')
    .optional({ values: 'falsy' })
    .isString()
    .trim()
    .isLength({ max: 2000 }),
  body('icon').optional({ values: 'falsy' }).isString().trim().isLength({ max: 80 }),
  body('isActive').optional().isIn(['true', 'false', true, false]),
];

export const updateCategoryValidator = [
  ...idValidator,
  body('name').optional().isString().trim().notEmpty().isLength({ max: 200 }),
  body('code').optional().isString().trim().notEmpty().isLength({ max: 50 }),
  body('description')
    .optional({ values: 'falsy' })
    .isString()
    .trim()
    .isLength({ max: 2000 }),
  body('icon').optional({ values: 'falsy' }).isString().trim().isLength({ max: 80 }),
  body('isActive').optional().isIn(['true', 'false', true, false]),
];

export const createAssetValidator = [
  body('assetNumber').isString().trim().notEmpty().isLength({ max: 100 }),
  body('name').isString().trim().notEmpty().isLength({ max: 200 }),
  body('categoryId').optional({ values: 'falsy' }).isMongoId(),
  body('serialNumber')
    .optional({ values: 'falsy' })
    .isString()
    .trim()
    .isLength({ max: 120 }),
  body('manufacturer')
    .optional({ values: 'falsy' })
    .isString()
    .trim()
    .isLength({ max: 200 }),
  body('model').optional({ values: 'falsy' }).isString().trim().isLength({ max: 200 }),
  body('installationDate').optional({ values: 'falsy' }).isISO8601(),
  body('warrantyExpiry').optional({ values: 'falsy' }).isISO8601(),
  body('status')
    .optional({ values: 'falsy' })
    .isString()
    .trim()
    .custom((value) => ASSET_STATUSES.includes(String(value).toUpperCase())),
  body('branchId').optional({ values: 'falsy' }).isMongoId(),
  body('regionName')
    .optional({ values: 'falsy' })
    .isString()
    .trim()
    .isLength({ max: 200 }),
  body('cityName')
    .optional({ values: 'falsy' })
    .isString()
    .trim()
    .isLength({ max: 200 }),
  body('location').optional(),
  body('gps').optional(),
  body('qrCode').optional({ values: 'falsy' }).isString().trim().isLength({ max: 200 }),
  body('barcode').optional({ values: 'falsy' }).isString().trim().isLength({ max: 200 }),
  body('customer')
    .optional({ values: 'falsy' })
    .isString()
    .trim()
    .isLength({ max: 200 }),
  body('notes').optional({ values: 'falsy' }).isString().trim().isLength({ max: 5000 }),
];

export const updateAssetValidator = [
  ...idValidator,
  body('assetNumber').optional().isString().trim().notEmpty().isLength({ max: 100 }),
  body('name').optional().isString().trim().notEmpty().isLength({ max: 200 }),
  body('categoryId').optional({ values: 'falsy' }).isMongoId(),
  body('serialNumber')
    .optional({ values: 'falsy' })
    .isString()
    .trim()
    .isLength({ max: 120 }),
  body('manufacturer')
    .optional({ values: 'falsy' })
    .isString()
    .trim()
    .isLength({ max: 200 }),
  body('model').optional({ values: 'falsy' }).isString().trim().isLength({ max: 200 }),
  body('installationDate').optional({ values: 'falsy' }).isISO8601(),
  body('warrantyExpiry').optional({ values: 'falsy' }).isISO8601(),
  body('status')
    .optional({ values: 'falsy' })
    .isString()
    .trim()
    .custom((value) => ASSET_STATUSES.includes(String(value).toUpperCase())),
  body('branchId').optional({ values: 'falsy' }).isMongoId(),
  body('regionName')
    .optional({ values: 'falsy' })
    .isString()
    .trim()
    .isLength({ max: 200 }),
  body('cityName')
    .optional({ values: 'falsy' })
    .isString()
    .trim()
    .isLength({ max: 200 }),
  body('location').optional(),
  body('gps').optional(),
  body('qrCode').optional({ values: 'falsy' }).isString().trim().isLength({ max: 200 }),
  body('barcode').optional({ values: 'falsy' }).isString().trim().isLength({ max: 200 }),
  body('customer')
    .optional({ values: 'falsy' })
    .isString()
    .trim()
    .isLength({ max: 200 }),
  body('notes').optional({ values: 'falsy' }).isString().trim().isLength({ max: 5000 }),
  body('removeImage').optional().isIn(['true', 'false', true, false]),
];

export const createHistoryValidator = [
  body('assetId').isMongoId().withMessage('assetId is required'),
  body('type')
    .isString()
    .trim()
    .custom((value) => ASSET_HISTORY_TYPES.includes(String(value).toUpperCase()))
    .withMessage(`type must be one of: ${ASSET_HISTORY_TYPES.join(', ')}`),
  body('title').optional({ values: 'falsy' }).isString().trim().isLength({ max: 200 }),
  body('description')
    .optional({ values: 'falsy' })
    .isString()
    .trim()
    .isLength({ max: 2000 }),
  body('toStatus')
    .optional({ values: 'falsy' })
    .isString()
    .trim()
    .custom((value) => ASSET_STATUSES.includes(String(value).toUpperCase())),
  body('eventDate').optional({ values: 'falsy' }).isISO8601(),
];
