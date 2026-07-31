/**
 * Official working hours: 09:00 → 17:00 (local wall-clock of the timestamps).
 * Eligible overtime = session time outside that window.
 */
export const OFFICIAL_START_MINUTES = 9 * 60;
export const OFFICIAL_END_MINUTES = 17 * 60;
export const CALCULATION_VERSION = 'ot-v1-official-0900-1700';

function startOfLocalDay(date) {
  return new Date(date.getFullYear(), date.getMonth(), date.getDate());
}

function addDays(date, days) {
  const next = new Date(date);
  next.setDate(next.getDate() + days);
  return next;
}

/**
 * @param {Date} startAt
 * @param {Date} endAt
 */
export function calculateOvertimeDurations(startAt, endAt) {
  if (!(startAt instanceof Date) || !(endAt instanceof Date) || endAt <= startAt) {
    return {
      totalDurationMinutes: 0,
      workingDurationMinutes: 0,
      eligibleOvertimeMinutes: 0,
      calculationVersion: CALCULATION_VERSION,
      calculatedAt: new Date(),
    };
  }

  const totalMs = endAt.getTime() - startAt.getTime();
  const totalDurationMinutes = Math.max(0, Math.round(totalMs / 60000));

  let workingMinutesExact = 0;
  let cursor = startOfLocalDay(startAt);
  const lastDay = startOfLocalDay(endAt);

  while (cursor <= lastDay) {
    const dayStart = cursor;
    const dayEnd = addDays(dayStart, 1);
    const segmentStart = startAt > dayStart ? startAt : dayStart;
    const segmentEnd = endAt < dayEnd ? endAt : dayEnd;

    if (segmentEnd > segmentStart) {
      const officialStart = new Date(dayStart.getTime() + OFFICIAL_START_MINUTES * 60000);
      const officialEnd = new Date(dayStart.getTime() + OFFICIAL_END_MINUTES * 60000);
      const overlapStart = segmentStart > officialStart ? segmentStart : officialStart;
      const overlapEnd = segmentEnd < officialEnd ? segmentEnd : officialEnd;
      if (overlapEnd > overlapStart) {
        workingMinutesExact += (overlapEnd.getTime() - overlapStart.getTime()) / 60000;
      }
    }

    cursor = addDays(cursor, 1);
  }

  const workingDurationMinutes = Math.max(0, Math.round(workingMinutesExact));
  const eligibleOvertimeMinutes = Math.max(
    0,
    totalDurationMinutes - workingDurationMinutes
  );

  return {
    totalDurationMinutes,
    workingDurationMinutes,
    eligibleOvertimeMinutes,
    calculationVersion: CALCULATION_VERSION,
    calculatedAt: new Date(),
  };
}

export function assertReasonableSessionLength(startAt, endAt, maxHours = 16) {
  const hours = (endAt.getTime() - startAt.getTime()) / 3600000;
  return hours >= 0 && hours <= maxHours;
}
