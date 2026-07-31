import { body, query, param } from 'express-validator';
import { SERVICE_REPORT_STATUSES } from './models/serviceReport.model.js';

const statusValues = [
  'ALL',
  'all',
  ...SERVICE_REPORT_STATUSES,
  ...SERVICE_REPORT_STATUSES.map((v) => v.toLowerCase()),
];

export const listPaginationValidator = [
  query('page').optional().isInt({ min: 1 }).toInt(),
  query('limit').optional().isInt({ min: 1, max: 100 }).toInt(),
  query('search').optional().isString().trim().isLength({ max: 120 }),
];

export const listReportsValidator = [
  ...listPaginationValidator,
  query('status').optional().isString().trim().isIn(statusValues),
];

export const listSignaturesValidator = [...listPaginationValidator];

export const idValidator = [
  param('id').isMongoId().withMessage('id must be a valid MongoDB ObjectId'),
];

export const createSignatureValidator = [
  body('customerName').isString().trim().notEmpty().isLength({ max: 200 }),
  body('customerPosition')
    .optional({ values: 'falsy' })
    .isString()
    .trim()
    .isLength({ max: 200 }),
  body('workOrderId').optional({ values: 'falsy' }).isMongoId(),
  body('workOrderNumber')
    .optional({ values: 'falsy' })
    .isString()
    .trim()
    .isLength({ max: 100 }),
  body('signedAt').optional({ values: 'falsy' }).isISO8601(),
  body('notes')
    .optional({ values: 'falsy' })
    .isString()
    .trim()
    .isLength({ max: 5000 }),
];

export const generateReportValidator = [
  body('companyName')
    .optional({ values: 'falsy' })
    .isString()
    .trim()
    .isLength({ max: 200 }),
  body('companyLogoUrl')
    .optional({ values: 'falsy' })
    .isString()
    .trim()
    .isLength({ max: 2000 }),
  body('workOrderId').optional({ values: 'falsy' }).isMongoId(),
  body('signatureId').optional({ values: 'falsy' }).isMongoId(),
  body('startTime').optional({ values: 'falsy' }).isISO8601(),
  body('endTime').optional({ values: 'falsy' }).isISO8601(),
  body('totalDurationMinutes')
    .optional({ values: 'falsy' })
    .isFloat({ min: 0 })
    .toFloat(),
  body('technicianNotes')
    .optional({ values: 'falsy' })
    .isString()
    .trim()
    .isLength({ max: 10000 }),
  body('customerNotes')
    .optional({ values: 'falsy' })
    .isString()
    .trim()
    .isLength({ max: 10000 }),
  body('workOrder').optional().isObject(),
  body('asset').optional().isObject(),
  body('technician').optional().isObject(),
  body('customerSignature').optional().isObject(),
  body('beforePhotos').optional(),
  body('progressPhotos').optional(),
  body('afterPhotos').optional(),
];
