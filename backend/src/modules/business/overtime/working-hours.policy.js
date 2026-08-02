/**
 * Official company working hours — single source of truth for overtime overlap.
 *
 * Change start/end here (and later wire to organization settings) without
 * scattering magic numbers across services.
 *
 * Window is half-open: [start, end) so 17:00 is outside working hours.
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
   * Absolute session instants are stored in UTC; overlap uses this zone so
   * Render (UTC), Windows, and Android agree on the same eligible OT.
   */
  timeZone: 'Asia/Baghdad',
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
