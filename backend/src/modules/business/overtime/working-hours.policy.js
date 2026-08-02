/**
 * Official company working hours — single source of truth for overtime overlap.
 *
 * Change start/end / non-working weekdays here (and later wire to organization
 * settings) without scattering magic numbers across services.
 *
 * Window is half-open: [start, end) so 17:00 is outside working hours.
 *
 * Working days: Saturday–Thursday.
 * Friday is NOT a working day — all Friday time counts as eligible overtime.
 */
export const OFFICIAL_WORKING_HOURS = Object.freeze({
  /** Inclusive start hour (0–23). */
  startHour: 9,
  startMinute: 0,
  /** Exclusive end hour (0–23). 17:00 = 5:00 PM. */
  endHour: 17,
  endMinute: 0,
  /**
   * IANA timezone used to interpret wall-clock for overlap.
   * Absolute session instants are stored in UTC; overlap uses Africa/Cairo
   * wall-clock so Render (UTC), Windows, and Android agree on eligible OT.
   */
  timeZone: 'Africa/Cairo',
  /**
   * Short English weekday names (en-US) with no official working hours.
   * Friday is a full overtime day.
   */
  nonWorkingWeekdays: Object.freeze(['Fri']),
});

export function officialStartMinutesOfDay(
  hours = OFFICIAL_WORKING_HOURS
) {
  return hours.startHour * 60 + hours.startMinute;
}

export function officialEndMinutesOfDay(
  hours = OFFICIAL_WORKING_HOURS
) {
  return hours.endHour * 60 + hours.endMinute;
}
