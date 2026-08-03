import { body, query, param } from 'express-validator';

const telemetryFields = [
  body('notes').optional({ values: 'falsy' }).isString().trim().isLength({ max: 1000 }),
  body('batteryLevel')
    .optional({ values: 'falsy' })
    .isFloat({ min: 0, max: 100 })
    .withMessage('batteryLevel must be between 0 and 100'),
  body('networkStatus')
    .optional({ values: 'falsy' })
    .isString()
    .trim()
    .isLength({ max: 40 }),
];

export const startOvertimeValidator = [
  body('type')
    .isString()
    .trim()
    .isIn(['NORMAL', 'TRAVEL', 'normal', 'travel'])
    .withMessage('type must be NORMAL or TRAVEL'),
  body('latitude').isFloat({ min: -90, max: 90 }),
  body('longitude').isFloat({ min: -180, max: 180 }),
  body('accuracy').isFloat({ min: 0 }),
  body('recordedAt').isISO8601(),
  body('deviceId').isString().trim().notEmpty(),
  body('clientRequestId').isString().trim().notEmpty(),
  body('address').optional().isString().trim().isLength({ max: 500 }),
  body('fullAddress').optional().isString().trim().isLength({ max: 500 }),
  body('street').optional().isString().trim().isLength({ max: 200 }),
  body('area').optional().isString().trim().isLength({ max: 200 }),
  body('city').optional().isString().trim().isLength({ max: 120 }),
  body('country').optional().isString().trim().isLength({ max: 120 }),
  body('addressResolvedAt').optional({ values: 'falsy' }).isISO8601(),
  body('heading').optional({ values: 'falsy' }).isFloat(),
  body('speed').optional({ values: 'falsy' }).isFloat(),
  body('altitude').optional({ values: 'falsy' }).isFloat(),
  body('provider').optional().isString().trim(),
  ...telemetryFields,
  // Offline sync timeline (optional — online flow omits these)
  body('startedAt').optional({ values: 'falsy' }).isISO8601(),
  body('endedAt').optional({ values: 'falsy' }).isISO8601(),
  body('durationSeconds')
    .optional({ values: 'falsy' })
    .isInt({ min: 0 })
    .withMessage('durationSeconds must be >= 0'),
];

export const endOvertimeValidator = [
  body('latitude').isFloat({ min: -90, max: 90 }),
  body('longitude').isFloat({ min: -180, max: 180 }),
  body('accuracy').isFloat({ min: 0 }),
  body('recordedAt').isISO8601(),
  body('deviceId').isString().trim().notEmpty(),
  // Required for v2 End Journey idempotency; optional for legacy clients.
  body('clientRequestId').optional({ values: 'falsy' }).isString().trim().notEmpty(),
  body('address').optional().isString().trim().isLength({ max: 500 }),
  body('fullAddress').optional().isString().trim().isLength({ max: 500 }),
  body('street').optional().isString().trim().isLength({ max: 200 }),
  body('area').optional().isString().trim().isLength({ max: 200 }),
  body('city').optional().isString().trim().isLength({ max: 120 }),
  body('country').optional().isString().trim().isLength({ max: 120 }),
  body('addressResolvedAt').optional({ values: 'falsy' }).isISO8601(),
  body('heading').optional({ values: 'falsy' }).isFloat(),
  body('speed').optional({ values: 'falsy' }).isFloat(),
  body('altitude').optional({ values: 'falsy' }).isFloat(),
  body('provider').optional().isString().trim(),
  ...telemetryFields,
  // Offline sync timeline (optional — online flow omits these)
  body('startedAt').optional({ values: 'falsy' }).isISO8601(),
  body('endedAt').optional({ values: 'falsy' }).isISO8601(),
  body('durationSeconds')
    .optional({ values: 'falsy' })
    .isInt({ min: 0 })
    .withMessage('durationSeconds must be >= 0'),
];

/** Mid-journey checkpoints (v2 workflow only). */
export const checkpointOvertimeValidator = [
  body('latitude').isFloat({ min: -90, max: 90 }),
  body('longitude').isFloat({ min: -180, max: 180 }),
  body('accuracy').isFloat({ min: 0 }),
  body('recordedAt').isISO8601(),
  body('deviceId').isString().trim().notEmpty(),
  body('clientRequestId').isString().trim().notEmpty(),
  body('address').optional().isString().trim().isLength({ max: 500 }),
  body('fullAddress').optional().isString().trim().isLength({ max: 500 }),
  body('street').optional().isString().trim().isLength({ max: 200 }),
  body('area').optional().isString().trim().isLength({ max: 200 }),
  body('city').optional().isString().trim().isLength({ max: 120 }),
  body('country').optional().isString().trim().isLength({ max: 120 }),
  body('addressResolvedAt').optional({ values: 'falsy' }).isISO8601(),
  body('heading').optional({ values: 'falsy' }).isFloat(),
  body('speed').optional({ values: 'falsy' }).isFloat(),
  body('altitude').optional({ values: 'falsy' }).isFloat(),
  body('provider').optional().isString().trim(),
  ...telemetryFields,
  body('checkpointAt').optional({ values: 'falsy' }).isISO8601(),
  body('startedAt').optional({ values: 'falsy' }).isISO8601(),
];

export const listOvertimeValidator = [
  query('page').optional().isInt({ min: 1 }).toInt(),
  query('limit').optional().isInt({ min: 1, max: 100 }).toInt(),
  query('status')
    .optional()
    .isString()
    .trim()
    .isIn([
      'ALL',
      'PENDING',
      'PENDING_REVIEW',
      'APPROVED',
      'REJECTED',
      'RUNNING',
      'CANCELLED',
      'all',
      'pending',
      'approved',
      'rejected',
    ]),
  query('search').optional().isString().trim().isLength({ max: 120 }),
];

export const rejectOvertimeValidator = [
  body('rejectionReason')
    .optional({ values: 'falsy' })
    .isString()
    .trim()
    .isLength({ max: 1000 })
    .withMessage('rejectionReason must be at most 1000 characters'),
  body('reviewNotes')
    .optional({ values: 'falsy' })
    .isString()
    .trim()
    .isLength({ max: 2000 })
    .withMessage('reviewNotes must be at most 2000 characters'),
];

export const approveOvertimeValidator = [
  body('reviewNotes')
    .optional({ values: 'falsy' })
    .isString()
    .trim()
    .isLength({ max: 2000 })
    .withMessage('reviewNotes must be at most 2000 characters'),
];

export const overtimeIdValidator = [
  param('id').isMongoId().withMessage('id must be a valid MongoDB ObjectId'),
];

export const updateOvertimeGpsAddressValidator = [
  param('id').isMongoId().withMessage('id must be a valid MongoDB ObjectId'),
  body('point')
    .isString()
    .trim()
    .isIn([
      'start',
      'end',
      'START',
      'END',
      'startJourney',
      'arrivedAtWorkSite',
      'finishedWork',
      'endJourney',
    ]),
  body('fullAddress').optional().isString().trim().isLength({ max: 500 }),
  body('street').optional().isString().trim().isLength({ max: 200 }),
  body('area').optional().isString().trim().isLength({ max: 200 }),
  body('city').optional().isString().trim().isLength({ max: 120 }),
  body('country').optional().isString().trim().isLength({ max: 120 }),
  body('addressResolvedAt').optional({ values: 'falsy' }).isISO8601(),
];
