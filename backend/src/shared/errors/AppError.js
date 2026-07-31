export default class AppError extends Error {
  constructor(code, message, statusCode = 500, details = null) {
    super(message);
    this.name = 'AppError';
    this.code = code;
    this.statusCode = statusCode;
    this.details = details;
    this.isOperational = true;
    Error.captureStackTrace(this, this.constructor);
  }
}

function isStableErrorCode(value) {
  return typeof value === 'string' && /^[A-Z][A-Z0-9_]*$/.test(value);
}

function inferNotFoundCode(resource) {
  const base = String(resource || 'Resource')
    .replace(/\s+not found$/i, '')
    .trim()
    .toUpperCase()
    .replace(/[^A-Z0-9]+/g, '_')
    .replace(/^_+|_+$/g, '');

  const aliases = {
    WORK_ORDER: 'WORK_ORDER_NOT_FOUND',
    WORKORDER: 'WORK_ORDER_NOT_FOUND',
    USER: 'USER_NOT_FOUND',
    ROLE: 'ROLE_NOT_FOUND',
    OVERTIME_SESSION: 'OVERTIME_NOT_FOUND',
    ATTENDANCE_EVENT: 'ATTENDANCE_NOT_FOUND',
    BREAKSESSION: 'BREAK_NOT_FOUND',
    BREAK_SESSION: 'BREAK_NOT_FOUND',
    PHOTO: 'PHOTO_NOT_FOUND',
    TECHNICIAN: 'TECHNICIAN_NOT_FOUND',
    COMPANY: 'COMPANY_NOT_FOUND',
    WAREHOUSE: 'WAREHOUSE_NOT_FOUND',
    SPARE_PART: 'SPARE_PART_NOT_FOUND',
    ASSET: 'ASSET_NOT_FOUND',
    ASSET_CATEGORY: 'ASSET_CATEGORY_NOT_FOUND',
    MAINTENANCE_PLAN: 'PM_PLAN_NOT_FOUND',
    MAINTENANCE_SCHEDULE: 'PM_SCHEDULE_NOT_FOUND',
    SERVICE_REPORT: 'REPORT_NOT_FOUND',
    CUSTOMER_SIGNATURE: 'SIGNATURE_NOT_FOUND',
  };

  if (!base) return 'NOT_FOUND';
  if (aliases[base]) return aliases[base];
  if (base.endsWith('_NOT_FOUND')) return base;
  return `${base}_NOT_FOUND`;
}

export class ValidationError extends AppError {
  constructor(details) {
    const primaryFromDetails = Array.isArray(details)
      ? details.find((item) => isStableErrorCode(item?.code || item?.message))
      : null;
    const code =
      primaryFromDetails?.code ||
      (isStableErrorCode(primaryFromDetails?.message)
        ? primaryFromDetails.message
        : 'VALIDATION_ERROR');

    super(code, 'Request validation failed', 400, details);
    this.name = 'ValidationError';
  }
}

export class UnauthorizedError extends AppError {
  constructor(
    message = 'Invalid or expired token',
    code = 'UNAUTHORIZED'
  ) {
    super(code, message, 401);
    this.name = 'UnauthorizedError';
  }
}

export class ForbiddenError extends AppError {
  constructor(message = 'You do not have permission to perform this action', details = null) {
    super('FORBIDDEN', message, 403, details);
    this.name = 'ForbiddenError';
  }
}

export class NotFoundError extends AppError {
  /**
   * @param {string} resource Resource label (kept for logs / compatibility)
   * @param {string} [code] Optional stable code (e.g. WORK_ORDER_NOT_FOUND)
   */
  constructor(resource = 'Resource', code) {
    const message = /not found/i.test(String(resource))
      ? String(resource)
      : `${resource} not found`;
    super(code || inferNotFoundCode(resource), message, 404);
    this.name = 'NotFoundError';
  }
}

export class ConflictError extends AppError {
  constructor(message, details = null) {
    super('CONFLICT', message, 409, details);
    this.name = 'ConflictError';
  }
}
