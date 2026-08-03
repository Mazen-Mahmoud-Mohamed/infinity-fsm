import { body, query, param } from 'express-validator';

const gpsFields = [
  body('latitude')
    .isFloat({ min: -90, max: 90 })
    .withMessage('GPS_REQUIRED'),
  body('longitude')
    .isFloat({ min: -180, max: 180 })
    .withMessage('GPS_REQUIRED'),
  body('accuracy')
    .isFloat({ min: 0 })
    .withMessage('GPS_REQUIRED'),
  body('heading').optional().isFloat(),
  body('speed').optional().isFloat(),
  body('altitude').optional({ values: 'falsy' }).isFloat(),
  body('provider').optional().isString(),
  body('recordedAt')
    .isISO8601()
    .withMessage('INVALID_TIMESTAMP'),
  body('fullAddress').optional().isString().trim().isLength({ max: 500 }),
  body('street').optional().isString().trim().isLength({ max: 200 }),
  body('area').optional().isString().trim().isLength({ max: 200 }),
  body('city').optional().isString().trim().isLength({ max: 120 }),
  body('country').optional().isString().trim().isLength({ max: 120 }),
  body('addressResolvedAt').optional().isISO8601(),
];

export const updateGpsAddressValidator = [
  body('clientEventId').isString().trim().notEmpty(),
  body('fullAddress').optional().isString().trim().isLength({ max: 500 }),
  body('street').optional().isString().trim().isLength({ max: 200 }),
  body('area').optional().isString().trim().isLength({ max: 200 }),
  body('city').optional().isString().trim().isLength({ max: 120 }),
  body('country').optional().isString().trim().isLength({ max: 120 }),
  body('addressResolvedAt').optional().isISO8601(),
];

const eventFields = [
  body('clientEventId')
    .isString()
    .notEmpty()
    .withMessage('CLIENT_REQUEST_REQUIRED'),
  body('deviceId').isString().notEmpty().withMessage('DEVICE_REQUIRED'),
  body('clientRecordedAt').optional().isISO8601(),
];

export const clockInValidator = [...gpsFields, ...eventFields];
export const clockOutValidator = [...gpsFields, ...eventFields];
export const breakStartValidator = [...gpsFields, ...eventFields];
export const breakEndValidator = [...gpsFields, ...eventFields];

export const historyValidator = [
  query('page').optional().isInt({ min: 1 }).toInt(),
  query('limit').optional().isInt({ min: 1, max: 100 }).toInt(),
  query('startDate').optional().isISO8601(),
  query('endDate').optional().isISO8601(),
];

export const listAttendanceValidator = [
  query('page').optional().isInt({ min: 1 }).toInt(),
  query('limit').optional().isInt({ min: 1, max: 100 }).toInt(),
  query('status')
    .optional()
    .isString()
    .trim()
    .isIn(['CLOCKED_IN', 'ON_BREAK', 'CLOCKED_OUT', 'clocked_in', 'on_break', 'clocked_out']),
  query('search').optional().isString().trim().isLength({ max: 120 }),
  query('startDate').optional().isISO8601(),
  query('endDate').optional().isISO8601(),
  query('userId').optional().isMongoId(),
  query('role').optional().isString().trim().isLength({ max: 40 }),
];

export const attendanceIdValidator = [
  param('id').isMongoId().withMessage('Invalid attendance id'),
];
