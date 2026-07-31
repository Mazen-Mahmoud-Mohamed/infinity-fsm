export function sendSuccess(res, data, statusCode = 200, meta = {}) {
  return res.status(statusCode).json({
    success: true,
    data,
    meta: {
      requestId: res.locals.requestId,
      timestamp: new Date().toISOString(),
      apiVersion: res.app.locals.apiVersion,
      ...meta,
    },
  });
}

export function sendPaginated(res, data, pagination, statusCode = 200) {
  return sendSuccess(res, data, statusCode, { pagination });
}

export function sendError(res, error) {
  const statusCode = error.statusCode || 500;
  const isOperational = error.isOperational === true;

  return res.status(statusCode).json({
    success: false,
    error: {
      code: error.code || 'INTERNAL_ERROR',
      message: isOperational ? error.message : 'An unexpected error occurred',
      ...(error.details && { details: error.details }),
    },
    meta: {
      requestId: res.locals.requestId,
      timestamp: new Date().toISOString(),
      apiVersion: res.app.locals.apiVersion,
    },
  });
}
