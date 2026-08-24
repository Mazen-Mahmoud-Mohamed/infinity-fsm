import { body, query, param } from 'express-validator';
import {
  WORK_ORDER_PRIORITIES,
  WORK_ORDER_STATUSES,
} from './models/workOrder.model.js';

const statusValues = [
  'ALL',
  ...WORK_ORDER_STATUSES,
  'all',
  ...WORK_ORDER_STATUSES.map((s) => s.toLowerCase()),
];

export const listWorkOrdersValidator = [
  query('page').optional().isInt({ min: 1 }).toInt(),
  query('limit').optional().isInt({ min: 1, max: 100 }).toInt(),
  query('status').optional().isString().trim().isIn(statusValues),
  query('search').optional().isString().trim().isLength({ max: 120 }),
];

export const workOrderIdValidator = [
  param('id').isMongoId().withMessage('id must be a valid MongoDB ObjectId'),
];

export const createWorkOrderValidator = [
  body('jobTitle').isString().trim().notEmpty().isLength({ max: 200 }),
  body('customerName').optional({ values: 'falsy' }).isString().trim().isLength({ max: 200 }),
  body('customerPhoneNumbers').optional(),
  body('locationLabel').optional({ values: 'falsy' }).isString().trim().isLength({ max: 300 }),
  body('locationUrl')
    .optional({ values: 'falsy' })
    .isString()
    .trim()
    .isLength({ max: 2000 })
    .custom((value) => {
      try {
        const parsed = new URL(String(value));
        return parsed.protocol === 'http:' || parsed.protocol === 'https:';
      } catch {
        return false;
      }
    })
    .withMessage('locationUrl must be a valid http(s) URL'),
  body('description').optional({ values: 'falsy' }).isString().trim().isLength({ max: 5000 }),
  body('notes').optional({ values: 'falsy' }).isString().trim().isLength({ max: 5000 }),
  body('priority')
    .optional({ values: 'falsy' })
    .isString()
    .trim()
    .custom((value) => WORK_ORDER_PRIORITIES.includes(String(value).toUpperCase()))
    .withMessage(`priority must be one of: ${WORK_ORDER_PRIORITIES.join(', ')}`),
  body('scheduledAt').optional({ values: 'falsy' }).isISO8601(),
  body('assignedTechnicianId').optional({ values: 'falsy' }).isMongoId(),
  body('assignedTechnicianIds').optional(),
  body('clearVoiceNote').optional().isIn(['true', 'false', true, false]),
  body('estimatedDurationMinutes')
    .optional({ values: 'falsy' })
    .isInt({ min: 0 })
    .toInt(),
  body('customerAddress').optional(),
];

export const updateWorkOrderValidator = [
  ...workOrderIdValidator,
  body('jobTitle').optional().isString().trim().notEmpty().isLength({ max: 200 }),
  body('customerName').optional({ values: 'falsy' }).isString().trim().isLength({ max: 200 }),
  body('customerPhoneNumbers').optional(),
  body('locationLabel').optional({ values: 'falsy' }).isString().trim().isLength({ max: 300 }),
  body('locationUrl')
    .optional({ values: 'falsy' })
    .custom((value) => {
      if (value === '' || value === null || value === undefined) {
        return true;
      }
      try {
        const parsed = new URL(String(value));
        return parsed.protocol === 'http:' || parsed.protocol === 'https:';
      } catch {
        return false;
      }
    })
    .withMessage('locationUrl must be a valid http(s) URL')
    .isLength({ max: 2000 }),
  body('description').optional({ values: 'falsy' }).isString().trim().isLength({ max: 5000 }),
  body('notes').optional({ values: 'falsy' }).isString().trim().isLength({ max: 5000 }),
  body('priority')
    .optional({ values: 'falsy' })
    .isString()
    .trim()
    .custom((value) => WORK_ORDER_PRIORITIES.includes(String(value).toUpperCase()))
    .withMessage(`priority must be one of: ${WORK_ORDER_PRIORITIES.join(', ')}`),
  body('scheduledAt').optional({ values: 'falsy' }).isISO8601(),
  body('assignedTechnicianId')
    .optional({ values: 'falsy' })
    .custom((value) => {
      if (value === '' || value === null || value === undefined) {
        return true;
      }
      return /^[a-fA-F0-9]{24}$/.test(String(value));
    })
    .withMessage('assignedTechnicianId must be a valid MongoDB ObjectId'),
  body('assignedTechnicianIds').optional(),
  body('clearVoiceNote').optional().isIn(['true', 'false', true, false]),
  body('estimatedDurationMinutes')
    .optional({ values: 'falsy' })
    .isInt({ min: 0 })
    .toInt(),
  body('customerAddress').optional(),
  body('replaceAttachments').optional().isIn(['true', 'false', true, false]),
  body('keepAttachmentUrls').optional(),
];

export const assignWorkOrderValidator = [
  ...workOrderIdValidator,
  body('assignedTechnicianId')
    .optional({ values: 'falsy' })
    .isMongoId()
    .withMessage('assignedTechnicianId must be a valid MongoDB ObjectId'),
  body('assignedTechnicianIds').optional(),
  body('priority')
    .optional({ values: 'falsy' })
    .isString()
    .trim()
    .custom((value) => WORK_ORDER_PRIORITIES.includes(String(value).toUpperCase())),
  body('scheduledAt').optional({ values: 'falsy' }).isISO8601(),
];

export const rejectWorkOrderValidator = [
  ...workOrderIdValidator,
  body('rejectionReason')
    .optional({ values: 'falsy' })
    .isString()
    .trim()
    .isLength({ max: 1000 }),
];

export const completeWorkOrderValidator = [
  ...workOrderIdValidator,
  body('notes').optional({ values: 'falsy' }).isString().trim().isLength({ max: 5000 }),
  body('completionNotes')
    .optional({ values: 'falsy' })
    .isString()
    .trim()
    .isLength({ max: 5000 }),
  body('latitude').isFloat({ min: -90, max: 90 }),
  body('longitude').isFloat({ min: -180, max: 180 }),
  body('accuracy').optional({ values: 'falsy' }).isFloat({ min: 0 }),
  body('address').optional({ values: 'falsy' }).isString().trim().isLength({ max: 500 }),
  body('recordedAt').optional({ values: 'falsy' }).isISO8601(),
];

export const cancelWorkOrderValidator = [
  ...workOrderIdValidator,
  body('cancellationReason')
    .optional({ values: 'falsy' })
    .isString()
    .trim()
    .isLength({ max: 1000 }),
];

export const startWorkOrderValidator = [
  ...workOrderIdValidator,
  body('latitude').isFloat({ min: -90, max: 90 }),
  body('longitude').isFloat({ min: -180, max: 180 }),
  body('accuracy').optional({ values: 'falsy' }).isFloat({ min: 0 }),
  body('address').optional({ values: 'falsy' }).isString().trim().isLength({ max: 500 }),
  body('recordedAt').optional({ values: 'falsy' }).isISO8601(),
];

export const beforeWorkValidator = [
  ...workOrderIdValidator,
  body('beforeNotes')
    .optional({ values: 'falsy' })
    .isString()
    .trim()
    .isLength({ max: 5000 }),
];

export const progressNoteValidator = [
  ...workOrderIdValidator,
  body('text').isString().trim().notEmpty().isLength({ max: 2000 }),
];

export const removePhotoValidator = [
  ...workOrderIdValidator,
  body('category').isString().trim().isIn(['before', 'progress', 'after']),
  body('url').isString().trim().notEmpty().isLength({ max: 2000 }),
];
