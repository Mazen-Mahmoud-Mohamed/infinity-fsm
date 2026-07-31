import AppError from '../errors/AppError.js';

export default function notFoundHandler(req, _res, next) {
  next(new AppError('NOT_FOUND', `Route ${req.method} ${req.originalUrl} not found`, 404));
}
