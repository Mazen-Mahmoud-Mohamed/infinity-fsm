import { sendError } from '../utils/apiResponse.util.js';
import AppError, {
  ValidationError,
  UnauthorizedError,
} from '../errors/AppError.js';
import logger from '../utils/logger.util.js';

function normalizeError(err) {
  if (err instanceof AppError) {
    return err;
  }

  if (err.name === 'ValidationError' && err.errors) {
    const details = Object.entries(err.errors).map(([field, error]) => ({
      field,
      message: error.message,
    }));
    return new ValidationError(details);
  }

  if (err.name === 'CastError') {
    return new AppError('VALIDATION_ERROR', `Invalid ${err.path}`, 400, {
      field: err.path,
      value: err.value,
    });
  }

  if (err.code === 11000) {
    const field = Object.keys(err.keyPattern || {})[0] || 'field';
    return new AppError('CONFLICT', `Duplicate value for ${field}`, 409);
  }

  if (err.name === 'JsonWebTokenError') {
    return new UnauthorizedError('Invalid token');
  }

  if (err.name === 'TokenExpiredError') {
    return new UnauthorizedError('Token expired');
  }

  logger.error({ err }, 'Unhandled error');

  return new AppError('INTERNAL_ERROR', 'An unexpected error occurred', 500);
}

export default function errorHandler(err, req, res, _next) {
  const normalized = normalizeError(err);

  if (normalized.statusCode >= 500) {
    logger.error(
      {
        err: normalized,
        requestId: req.requestId,
        method: req.method,
        url: req.originalUrl,
        code: normalized.code,
      },
      normalized.message
    );
  }

  // TEMP DEBUG: expose 422 AppError identity without request body/PII.
  // Remove after identifying the overtime END rejection.
  if (normalized.statusCode === 422) {
    logger.warn(
      {
        requestId: req.requestId,
        method: req.method,
        url: req.originalUrl,
        code: normalized.code,
        message: normalized.message,
        statusCode: normalized.statusCode,
      },
      'TEMP_DEBUG_422'
    );
  }

  return sendError(res, normalized);
}
