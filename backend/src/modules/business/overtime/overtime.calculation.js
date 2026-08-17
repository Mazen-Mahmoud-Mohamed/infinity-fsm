import {
  OFFICIAL_WORKING_HOURS,
  officialEndMinutesOfDay,
  officialStartMinutesOfDay,
} from './working-hours.policy.js';

/**
 * Overtime duration calculator (authoritative).
 *
 * Eligible overtime = any session time OUTSIDE official working hours.
 * Working duration = session overlap with official hours on working days.
 * Eligible = Total − Working (never negative).
 *
 * Friday has no official hours — the entire Friday segment is eligible OT.
 * Working days: Saturday–Thursday with window [09:00, 17:00) in Africa/Cairo.
 *
 * Calendar days and weekdays are always resolved in Africa/Cairo — never via
 * Node process timezone, Render host TZ, or raw UTC calendar days.
 *
 * Same algorithm for NORMAL and TRAVEL overtime.
 */
export const CALCULATION_VERSION = 'ot-v4-africa-cairo';

/**
 * @typedef {object} OvertimeDurationResult
 * @property {number} totalDurationMinutes
 * @property {number} workingDurationMinutes
 * @property {number} eligibleOvertimeMinutes
 * @property {string} calculationVersion
 * @property {Date} calculatedAt
 */

/**
 * Read calendar + clock parts of an absolute instant in a given IANA zone.
 * @param {Date} date
 * @param {string} timeZone
 */
export function getZonedParts(date, timeZone) {
  const formatter = new Intl.DateTimeFormat('en-US', {
    timeZone,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
    hourCycle: 'h23',
  });

  const map = Object.create(null);
  for (const part of formatter.formatToParts(date)) {
    if (part.type !== 'literal') {
      map[part.type] = part.value;
    }
  }

  return {
    year: Number(map.year),
    month: Number(map.month),
    day: Number(map.day),
    hour: Number(map.hour),
    minute: Number(map.minute),
    second: Number(map.second),
  };
}

/**
 * Short English weekday for a calendar day in `timeZone` (e.g. "Fri").
 * @param {{ year: number, month: number, day: number }} ymd
 * @param {string} timeZone
 */
export function getZonedWeekdayShort(ymd, timeZone) {
  const noon = zonedLocalToUtc(timeZone, ymd.year, ymd.month, ymd.day, 12, 0, 0);
  return new Intl.DateTimeFormat('en-US', {
    timeZone,
    weekday: 'short',
  }).format(noon);
}

/**
 * Whether the calendar day has official working hours.
 * Friday is never a working day.
 */
export function isOfficialWorkingDay(ymd, hours = OFFICIAL_WORKING_HOURS) {
  const weekday = getZonedWeekdayShort(ymd, hours.timeZone);
  return !hours.nonWorkingWeekdays.includes(weekday);
}

/**
 * Convert a wall-clock datetime in `timeZone` to a UTC Date.
 * Iterative correction handles DST transitions safely.
 *
 * @param {string} timeZone
 * @param {number} year
 * @param {number} month 1–12
 * @param {number} day
 * @param {number} hour
 * @param {number} minute
 * @param {number} [second=0]
 * @returns {Date}
 */
export function zonedLocalToUtc(
  timeZone,
  year,
  month,
  day,
  hour,
  minute,
  second = 0
) {
  const wantedAsUtc = Date.UTC(year, month - 1, day, hour, minute, second);
  let guess = wantedAsUtc;

  for (let i = 0; i < 4; i += 1) {
    const parts = getZonedParts(new Date(guess), timeZone);
    const asUtc = Date.UTC(
      parts.year,
      parts.month - 1,
      parts.day,
      parts.hour,
      parts.minute,
      parts.second
    );
    const delta = wantedAsUtc - asUtc;
    if (delta === 0) {
      break;
    }
    guess += delta;
  }

  return new Date(guess);
}

function addCalendarDays(year, month, day, daysToAdd) {
  // Noon UTC avoids DST edge ambiguity when stepping calendar days.
  const utc = new Date(Date.UTC(year, month - 1, day, 12, 0, 0));
  utc.setUTCDate(utc.getUTCDate() + daysToAdd);
  return {
    year: utc.getUTCFullYear(),
    month: utc.getUTCMonth() + 1,
    day: utc.getUTCDate(),
  };
}

function compareYmd(a, b) {
  if (a.year !== b.year) return a.year - b.year;
  if (a.month !== b.month) return a.month - b.month;
  return a.day - b.day;
}

function formatDateKeyYmd(ymd) {
  return `${ymd.year}-${String(ymd.month).padStart(2, '0')}-${String(ymd.day).padStart(2, '0')}`;
}

/**
 * Overlap of [sessionStart, sessionEnd) with one calendar day in `timeZone`.
 * @param {Date} sessionStart
 * @param {Date} sessionEnd
 * @param {{ year: number, month: number, day: number }} ymd
 * @param {string} timeZone
 * @returns {number} milliseconds
 */
function sessionOverlapMsForDay(sessionStart, sessionEnd, ymd, timeZone) {
  const dayStart = zonedLocalToUtc(
    timeZone,
    ymd.year,
    ymd.month,
    ymd.day,
    0,
    0,
    0
  );
  const next = addCalendarDays(ymd.year, ymd.month, ymd.day, 1);
  const dayEnd = zonedLocalToUtc(
    timeZone,
    next.year,
    next.month,
    next.day,
    0,
    0,
    0
  );

  const segmentStartMs = Math.max(sessionStart.getTime(), dayStart.getTime());
  const segmentEndMs = Math.min(sessionEnd.getTime(), dayEnd.getTime());
  if (segmentEndMs <= segmentStartMs) {
    return 0;
  }
  return segmentEndMs - segmentStartMs;
}

/**
 * Split session minutes across calendar days using actual [startAt, endAt) overlap
 * per day in the company timezone. Each day's share is proportional to the time
 * spent on that calendar day; the last day absorbs rounding remainder so the sum
 * equals `totalMinutes` exactly.
 *
 * @param {Date} startAt
 * @param {Date} endAt
 * @param {number} totalMinutes approved / eligible minutes for the session
 * @param {string} [timeZone]
 * @returns {Record<string, number>} `YYYY-MM-DD` → whole minutes
 */
export function splitSessionMinutesAcrossCalendarDays(
  startAt,
  endAt,
  totalMinutes,
  timeZone = OFFICIAL_WORKING_HOURS.timeZone
) {
  /** @type {Record<string, number>} */
  const result = {};

  if (
    !(startAt instanceof Date) ||
    !(endAt instanceof Date) ||
    Number.isNaN(startAt.getTime()) ||
    Number.isNaN(endAt.getTime()) ||
    endAt.getTime() <= startAt.getTime()
  ) {
    return result;
  }

  const safeTotal = Math.max(0, Math.floor(Number(totalMinutes) || 0));
  if (safeTotal === 0) {
    return result;
  }

  /** @type {{ key: string, ms: number }[]} */
  const overlaps = [];
  let totalMs = 0;

  const startParts = getZonedParts(startAt, timeZone);
  const endParts = getZonedParts(endAt, timeZone);

  let cursor = {
    year: startParts.year,
    month: startParts.month,
    day: startParts.day,
  };
  const last = {
    year: endParts.year,
    month: endParts.month,
    day: endParts.day,
  };

  let guard = 0;
  while (compareYmd(cursor, last) <= 0 && guard < 400) {
    const ms = sessionOverlapMsForDay(startAt, endAt, cursor, timeZone);
    if (ms > 0) {
      overlaps.push({ key: formatDateKeyYmd(cursor), ms });
      totalMs += ms;
    }
    cursor = addCalendarDays(cursor.year, cursor.month, cursor.day, 1);
    guard += 1;
  }

  if (!overlaps.length || totalMs <= 0) {
    return result;
  }

  if (overlaps.length === 1) {
    result[overlaps[0].key] = safeTotal;
    return result;
  }

  let assigned = 0;
  for (let i = 0; i < overlaps.length; i += 1) {
    const { key, ms } = overlaps[i];
    let minutes;
    if (i === overlaps.length - 1) {
      minutes = safeTotal - assigned;
    } else {
      minutes = Math.floor((safeTotal * ms) / totalMs);
      assigned += minutes;
    }
    if (minutes > 0) {
      result[key] = (result[key] || 0) + minutes;
    }
  }

  return result;
}

/**
 * Overlap of [sessionStart, sessionEnd) with official hours for one calendar day
 * in the company timezone. Returns exact milliseconds.
 * Non-working days (Friday) contribute 0 working minutes.
 *
 * @param {Date} sessionStart
 * @param {Date} sessionEnd
 * @param {{ year: number, month: number, day: number }} ymd
 * @param {typeof OFFICIAL_WORKING_HOURS} hours
 */
function workingOverlapMsForDay(sessionStart, sessionEnd, ymd, hours) {
  if (!isOfficialWorkingDay(ymd, hours)) {
    return 0;
  }

  const startMin = officialStartMinutesOfDay(hours);
  const endMin = officialEndMinutesOfDay(hours);
  const startH = Math.floor(startMin / 60);
  const startM = startMin % 60;
  const endH = Math.floor(endMin / 60);
  const endM = endMin % 60;

  const officialStart = zonedLocalToUtc(
    hours.timeZone,
    ymd.year,
    ymd.month,
    ymd.day,
    startH,
    startM,
    0
  );
  const officialEnd = zonedLocalToUtc(
    hours.timeZone,
    ymd.year,
    ymd.month,
    ymd.day,
    endH,
    endM,
    0
  );

  const dayStart = zonedLocalToUtc(
    hours.timeZone,
    ymd.year,
    ymd.month,
    ymd.day,
    0,
    0,
    0
  );
  const next = addCalendarDays(ymd.year, ymd.month, ymd.day, 1);
  const dayEnd = zonedLocalToUtc(
    hours.timeZone,
    next.year,
    next.month,
    next.day,
    0,
    0,
    0
  );

  const segmentStartMs = Math.max(sessionStart.getTime(), dayStart.getTime());
  const segmentEndMs = Math.min(sessionEnd.getTime(), dayEnd.getTime());
  if (segmentEndMs <= segmentStartMs) {
    return 0;
  }

  const overlapStart = Math.max(segmentStartMs, officialStart.getTime());
  const overlapEnd = Math.min(segmentEndMs, officialEnd.getTime());
  if (overlapEnd <= overlapStart) {
    return 0;
  }

  return overlapEnd - overlapStart;
}

/**
 * Calculate total, working (inside official hours), and eligible overtime minutes.
 *
 * @param {Date} startAt absolute instant
 * @param {Date} endAt absolute instant
 * @param {typeof OFFICIAL_WORKING_HOURS} [hours]
 * @returns {OvertimeDurationResult}
 */
export function calculateOvertimeDurations(
  startAt,
  endAt,
  hours = OFFICIAL_WORKING_HOURS
) {
  const calculatedAt = new Date();

  if (
    !(startAt instanceof Date) ||
    !(endAt instanceof Date) ||
    Number.isNaN(startAt.getTime()) ||
    Number.isNaN(endAt.getTime()) ||
    endAt.getTime() <= startAt.getTime()
  ) {
    return {
      totalDurationMinutes: 0,
      workingDurationMinutes: 0,
      eligibleOvertimeMinutes: 0,
      calculationVersion: CALCULATION_VERSION,
      calculatedAt,
    };
  }

  const totalMs = endAt.getTime() - startAt.getTime();
  // Whole minutes via truncation — deterministic across platforms.
  const totalDurationMinutes = Math.max(0, Math.floor(totalMs / 60000));

  let workingMs = 0;
  const startParts = getZonedParts(startAt, hours.timeZone);
  const endParts = getZonedParts(endAt, hours.timeZone);

  let cursor = {
    year: startParts.year,
    month: startParts.month,
    day: startParts.day,
  };
  const last = {
    year: endParts.year,
    month: endParts.month,
    day: endParts.day,
  };

  let guard = 0;
  while (compareYmd(cursor, last) <= 0 && guard < 400) {
    workingMs += workingOverlapMsForDay(startAt, endAt, cursor, hours);
    cursor = addCalendarDays(cursor.year, cursor.month, cursor.day, 1);
    guard += 1;
  }

  const workingDurationMinutes = Math.max(0, Math.floor(workingMs / 60000));
  const eligibleOvertimeMinutes = Math.max(
    0,
    totalDurationMinutes - workingDurationMinutes
  );

  return {
    totalDurationMinutes,
    workingDurationMinutes,
    eligibleOvertimeMinutes,
    calculationVersion: CALCULATION_VERSION,
    calculatedAt,
  };
}

export function assertReasonableSessionLength(startAt, endAt, maxHours = 16) {
  if (!(startAt instanceof Date) || !(endAt instanceof Date)) {
    return false;
  }
  const hours = (endAt.getTime() - startAt.getTime()) / 3600000;
  return hours >= 0 && hours <= maxHours;
}

// Re-export policy constants for callers / tests.
export {
  OFFICIAL_WORKING_HOURS,
  officialStartMinutesOfDay,
  officialEndMinutesOfDay,
} from './working-hours.policy.js';
