import AppError from '../../../shared/errors/AppError.js';

function hasClientValue(value) {
  return value !== undefined && value !== null && String(value).trim() !== '';
}

function parseClientDate(value, fieldName) {
  if (!hasClientValue(value)) {
    return null;
  }
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) {
    throw new AppError(
      'INVALID_TIMESTAMP',
      `${fieldName} must be a valid ISO-8601 datetime`,
      422
    );
  }
  return date;
}

function parseClientDurationSeconds(value) {
  if (!hasClientValue(value)) {
    return null;
  }
  const seconds = Number(value);
  if (!Number.isFinite(seconds) || seconds < 0) {
    throw new AppError(
      'INVALID_DURATION',
      'durationSeconds must be a number >= 0',
      422
    );
  }
  return Math.trunc(seconds);
}

/**
 * Prefer client offline timeline when provided; otherwise fall back to server clock.
 * Validates endedAt >= startedAt and durationSeconds >= 0 when present.
 */
export function resolveSessionTimeline({
  body,
  fallbackStartAt,
  fallbackEndAt = null,
}) {
  const startedAt = parseClientDate(body.startedAt, 'startedAt') || fallbackStartAt;
  const endedAt = parseClientDate(body.endedAt, 'endedAt') || fallbackEndAt;
  const durationSeconds = parseClientDurationSeconds(body.durationSeconds);

  if (endedAt && startedAt && endedAt.getTime() < startedAt.getTime()) {
    throw new AppError(
      'INVALID_TIMELINE',
      'endedAt must be greater than or equal to startedAt',
      422
    );
  }

  return {
    startedAt,
    endedAt,
    durationSeconds,
    usedClientStart: hasClientValue(body.startedAt),
    usedClientEnd: hasClientValue(body.endedAt),
  };
}
