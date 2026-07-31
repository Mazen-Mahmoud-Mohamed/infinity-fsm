import { validationResult } from 'express-validator';
import { ValidationError } from '../errors/AppError.js';

function isStableErrorCode(value) {
  return typeof value === 'string' && /^[A-Z][A-Z0-9_]*$/.test(value);
}

export function validate(validations) {
  return async (req, _res, next) => {
    await Promise.all(validations.map((validation) => validation.run(req)));

    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      const details = errors.array().map((error) => {
        const msg = error.msg;
        return {
          field: error.path,
          message: msg,
          ...(isStableErrorCode(msg) ? { code: msg } : {}),
          value: error.value,
        };
      });
      return next(new ValidationError(details));
    }

    return next();
  };
}

export default validate;
