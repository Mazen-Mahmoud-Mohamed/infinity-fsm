/**
 * Partial-approval helpers for overtime.
 *
 * workedHours  = eligibleOvertimeMinutes / 60
 * approvedHours (stored) null → treat as workedHours (legacy compatible)
 */

export function minutesToHours(minutes) {
  if (minutes === null || minutes === undefined || minutes === '') return null;
  const n = Number(minutes);
  if (!Number.isFinite(n)) return null;
  return Math.round((n / 60) * 100) / 100;
}

/** Submitted / calculated OT hours for a session. */
export function workedHoursFromRecord(record) {
  return minutesToHours(record?.eligibleOvertimeMinutes);
}

/**
 * Effective approved hours for display, Excel, and statistics.
 * Fallback: approvedHours ?? workedHours
 */
export function resolveApprovedHours(record) {
  if (record == null) return null;
  const stored = record.approvedHours;
  if (stored !== null && stored !== undefined && stored !== '') {
    const n = Number(stored);
    if (Number.isFinite(n)) {
      return Math.round(n * 100) / 100;
    }
  }
  return workedHoursFromRecord(record);
}

/** Minutes equivalent of [resolveApprovedHours] for aggregations. */
export function resolveApprovedMinutes(record) {
  const hours = resolveApprovedHours(record);
  if (hours === null) return 0;
  return Math.round(hours * 60);
}

/**
 * Mongo aggregation expression: preferred OT minutes for totals.
 * approvedHours (hours) × 60, else eligibleOvertimeMinutes.
 */
export function approvedOtMinutesExpr() {
  return {
    $cond: [
      {
        $and: [
          { $ne: [{ $ifNull: ['$approvedHours', null] }, null] },
          { $ne: ['$approvedHours', ''] },
        ],
      },
      {
        $multiply: [{ $toDouble: { $ifNull: ['$approvedHours', 0] } }, 60],
      },
      { $ifNull: ['$eligibleOvertimeMinutes', 0] },
    ],
  };
}

/**
 * Normalize and validate optional approvedHours against worked hours.
 * @returns {{ ok: true, value: number } | { ok: false, message: string }}
 */
export function normalizeApprovedHoursInput(raw, workedHours) {
  const worked =
    workedHours === null || workedHours === undefined
      ? null
      : Math.round(Number(workedHours) * 100) / 100;

  if (raw === undefined || raw === null || raw === '') {
    if (worked === null || !Number.isFinite(worked)) {
      return { ok: true, value: null };
    }
    return { ok: true, value: worked };
  }

  const n = Number(raw);
  if (!Number.isFinite(n)) {
    return { ok: false, message: 'approvedHours must be a valid number.' };
  }
  if (n < 0) {
    return { ok: false, message: 'approvedHours cannot be negative.' };
  }
  const rounded = Math.round(n * 100) / 100;
  if (worked !== null && Number.isFinite(worked) && rounded > worked) {
    return {
      ok: false,
      message: 'approvedHours cannot exceed worked hours.',
    };
  }
  return { ok: true, value: rounded };
}
