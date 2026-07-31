import { query } from 'express-validator';

export const summaryValidator = [
  query('period')
    .optional()
    .isIn(['today', 'week', 'month', 'year', 'custom'])
    .withMessage('period must be today, week, month, year, or custom'),
  query('from')
    .optional()
    .isISO8601()
    .withMessage('from must be an ISO 8601 date'),
  query('to')
    .optional()
    .isISO8601()
    .withMessage('to must be an ISO 8601 date'),
];
