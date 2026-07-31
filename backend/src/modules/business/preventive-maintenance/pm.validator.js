import { body, query, param } from 'express-validator';
import {
  PM_FREQUENCIES,
  PM_TRIGGERS,
  PM_PRIORITIES,
  PM_PLAN_STATUSES,
} from './models/maintenancePlan.model.js';
import { PM_SCHEDULE_STATUSES } from './models/maintenanceSchedule.model.js';

const freqValues = [
  ...PM_FREQUENCIES,
  ...PM_FREQUENCIES.map((v) => v.toLowerCase()),
  'semi annual',
  'SEMI ANNUAL',
];
const triggerValues = [
  ...PM_TRIGGERS,
  ...PM_TRIGGERS.map((v) => v.toLowerCase()),
  'time based',
  'meter based',
];
const priorityValues = [...PM_PRIORITIES, ...PM_PRIORITIES.map((v) => v.toLowerCase())];
const planStatusValues = [
  'ALL',
  ...PM_PLAN_STATUSES,
  'all',
  ...PM_PLAN_STATUSES.map((v) => v.toLowerCase()),
];
const scheduleStatusValues = [
  'ALL',
  ...PM_SCHEDULE_STATUSES,
  'all',
  ...PM_SCHEDULE_STATUSES.map((v) => v.toLowerCase()),
];

export const listPaginationValidator = [
  query('page').optional().isInt({ min: 1 }).toInt(),
  query('limit').optional().isInt({ min: 1, max: 100 }).toInt(),
  query('search').optional().isString().trim().isLength({ max: 120 }),
];

export const listPlansValidator = [
  ...listPaginationValidator,
  query('status').optional().isString().trim().isIn(planStatusValues),
  query('frequency').optional().isString().trim(),
  query('priority').optional().isString().trim().isIn(priorityValues),
];

export const listSchedulesValidator = [
  ...listPaginationValidator,
  query('status').optional().isString().trim().isIn(scheduleStatusValues),
  query('planId').optional().isMongoId(),
  query('from').optional().isISO8601(),
  query('to').optional().isISO8601(),
];

export const listHistoryValidator = [
  ...listPaginationValidator,
  query('planId').optional().isMongoId(),
];

export const idValidator = [
  param('id').isMongoId().withMessage('id must be a valid MongoDB ObjectId'),
];

export const createPlanValidator = [
  body('name').isString().trim().notEmpty().isLength({ max: 200 }),
  body('code').isString().trim().notEmpty().isLength({ max: 50 }),
  body('description')
    .optional({ values: 'falsy' })
    .isString()
    .trim()
    .isLength({ max: 5000 }),
  body('frequency').optional().isString().trim(),
  body('trigger').optional().isString().trim(),
  body('nextDueDate').optional({ values: 'falsy' }).isISO8601(),
  body('priority').optional().isString().trim(),
  body('estimatedDurationMinutes').optional({ values: 'falsy' }).isInt({ min: 0 }).toInt(),
  body('assignedTeamId').optional({ values: 'falsy' }).isMongoId(),
  body('assignedTechnicianId').optional({ values: 'falsy' }).isMongoId(),
  body('assetId').optional({ values: 'falsy' }).isMongoId(),
  body('meterThreshold').optional({ values: 'falsy' }).isFloat({ min: 0 }).toFloat(),
  body('currentMeterReading').optional({ values: 'falsy' }).isFloat({ min: 0 }).toFloat(),
  body('status').optional().isString().trim(),
  body('checklistItems').optional(),
];

export const updatePlanValidator = [
  ...idValidator,
  body('name').optional().isString().trim().notEmpty().isLength({ max: 200 }),
  body('code').optional().isString().trim().notEmpty().isLength({ max: 50 }),
  body('description')
    .optional({ values: 'falsy' })
    .isString()
    .trim()
    .isLength({ max: 5000 }),
  body('frequency').optional().isString().trim(),
  body('trigger').optional().isString().trim(),
  body('nextDueDate').optional({ values: 'falsy' }).isISO8601(),
  body('priority').optional().isString().trim(),
  body('estimatedDurationMinutes').optional({ values: 'falsy' }).isInt({ min: 0 }).toInt(),
  body('assignedTeamId').optional({ values: 'falsy' }).isMongoId(),
  body('assignedTechnicianId').optional({ values: 'falsy' }).isMongoId(),
  body('assetId').optional({ values: 'falsy' }).isMongoId(),
  body('meterThreshold').optional({ values: 'falsy' }).isFloat({ min: 0 }).toFloat(),
  body('currentMeterReading').optional({ values: 'falsy' }).isFloat({ min: 0 }).toFloat(),
  body('status').optional().isString().trim(),
  body('checklistItems').optional(),
];

export const updateChecklistValidator = [
  ...idValidator,
  body('checklistItems').exists().withMessage('checklistItems is required'),
];

export const generateSchedulesValidator = [
  ...idValidator,
  body('count').optional().isInt({ min: 1, max: 24 }).toInt(),
];

export const completeScheduleValidator = [
  ...idValidator,
  body('completedDate').optional({ values: 'falsy' }).isISO8601(),
  body('notes').optional({ values: 'falsy' }).isString().trim().isLength({ max: 2000 }),
  body('checklistResults').optional(),
];

export const cancelScheduleValidator = [
  ...idValidator,
  body('notes').optional({ values: 'falsy' }).isString().trim().isLength({ max: 2000 }),
];

// silence unused in case tree-shaking tools warn
void freqValues;
void triggerValues;
