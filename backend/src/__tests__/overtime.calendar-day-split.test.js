import {
  allocateOvertimeTrendMinutesByCalendarDay,
  calculateOvertimeDurations,
  eligibleOvertimeMinutesByCalendarDay,
  zonedLocalToUtc,
} from '../modules/business/overtime/overtime.calculation.js';
import { OFFICIAL_WORKING_HOURS } from '../modules/business/overtime/working-hours.policy.js';

const TZ = OFFICIAL_WORKING_HOURS.timeZone;

/** Wall-clock in company timezone → absolute Date. */
function at(year, month, day, hour, minute = 0) {
  return zonedLocalToUtc(TZ, year, month, day, hour, minute, 0);
}

function sumMinutes(map) {
  return Object.values(map).reduce((total, minutes) => total + minutes, 0);
}

function bucketKeys(map) {
  return Object.keys(map).sort();
}

describe('eligibleOvertimeMinutesByCalendarDay (official overtime rules)', () => {
  it('assigns a same-day weekday session using overtime rules, not raw duration', () => {
    // Sat 04:00 → 12:00: 5h eligible (04:00–09:00), 3h working
    const start = at(2026, 8, 1, 4, 0);
    const end = at(2026, 8, 1, 12, 0);
    const session = calculateOvertimeDurations(start, end);
    const buckets = eligibleOvertimeMinutesByCalendarDay(start, end);

    expect(bucketKeys(buckets)).toEqual(['2026-08-01']);
    expect(buckets['2026-08-01']).toBe(5 * 60);
    expect(sumMinutes(buckets)).toBe(session.eligibleOvertimeMinutes);
    expect(buckets['2026-08-01']).not.toBe(session.totalDurationMinutes);
  });

  it('treats a full weekday 09:00–17:00 window as 8 working hours and 0 eligible', () => {
    const start = at(2026, 8, 1, 9, 0);
    const end = at(2026, 8, 1, 17, 0);
    const session = calculateOvertimeDurations(start, end);
    const buckets = eligibleOvertimeMinutesByCalendarDay(start, end);

    expect(session.workingDurationMinutes).toBe(8 * 60);
    expect(session.eligibleOvertimeMinutes).toBe(0);
    expect(buckets).toEqual({});
  });

  it('counts a full weekday calendar day as 16 eligible hours (24h − 8h official window)', () => {
    const start = at(2026, 8, 1, 0, 0);
    const end = at(2026, 8, 2, 0, 0);
    const session = calculateOvertimeDurations(start, end);
    const buckets = eligibleOvertimeMinutesByCalendarDay(start, end);

    expect(session.workingDurationMinutes).toBe(8 * 60);
    expect(session.eligibleOvertimeMinutes).toBe(16 * 60);
    expect(buckets['2026-08-01']).toBe(16 * 60);
    expect(sumMinutes(buckets)).toBe(session.eligibleOvertimeMinutes);
  });

  it('counts a full Friday as 24 eligible hours', () => {
    const start = at(2026, 8, 14, 0, 0);
    const end = at(2026, 8, 15, 0, 0);
    const session = calculateOvertimeDurations(start, end);
    const buckets = eligibleOvertimeMinutesByCalendarDay(start, end);

    expect(session.workingDurationMinutes).toBe(0);
    expect(session.eligibleOvertimeMinutes).toBe(24 * 60);
    expect(bucketKeys(buckets)).toEqual(['2026-08-14']);
    expect(buckets['2026-08-14']).toBe(24 * 60);
  });

  it('splits a multi-day session containing Friday using overtime rules', () => {
    const start = at(2026, 8, 13, 0, 0);
    const end = at(2026, 8, 15, 0, 0);
    const session = calculateOvertimeDurations(start, end);
    const buckets = eligibleOvertimeMinutesByCalendarDay(start, end);

    expect(bucketKeys(buckets)).toEqual(['2026-08-13', '2026-08-14']);
    expect(buckets['2026-08-13']).toBe(16 * 60); // Thursday full day
    expect(buckets['2026-08-14']).toBe(24 * 60); // Friday full day
    expect(sumMinutes(buckets)).toBe(session.eligibleOvertimeMinutes);
    expect(buckets['2026-08-14']).not.toBe(
      Math.floor(session.eligibleOvertimeMinutes / 2)
    );
  });

  it('splits a Saturday–Thursday span without inflating weekdays to 24h', () => {
    // Sat 8/8 00:00 → Thu 8/13 00:00 = Sat, Sun, Mon, Tue, Wed
    const start = at(2026, 8, 8, 0, 0);
    const end = at(2026, 8, 13, 0, 0);
    const session = calculateOvertimeDurations(start, end);
    const buckets = eligibleOvertimeMinutesByCalendarDay(start, end);

    expect(bucketKeys(buckets)).toEqual([
      '2026-08-08',
      '2026-08-09',
      '2026-08-10',
      '2026-08-11',
      '2026-08-12',
    ]);
    for (const key of bucketKeys(buckets)) {
      expect(buckets[key]).toBe(16 * 60);
    }
    expect(sumMinutes(buckets)).toBe(session.eligibleOvertimeMinutes);
    expect(session.eligibleOvertimeMinutes).toBe(5 * 16 * 60);
  });

  it('uses the real start timestamp on a partial first day', () => {
    const start = at(2026, 8, 12, 10, 0);
    const end = at(2026, 8, 13, 0, 0);
    const session = calculateOvertimeDurations(start, end);
    const buckets = eligibleOvertimeMinutesByCalendarDay(start, end);

    // Wed 10:00 → midnight: 14h total, 7h working (10:00–17:00), 7h eligible
    expect(buckets['2026-08-12']).toBe(7 * 60);
    expect(sumMinutes(buckets)).toBe(session.eligibleOvertimeMinutes);
  });

  it('uses the real end timestamp on a partial last day', () => {
    const start = at(2026, 8, 16, 0, 0);
    const end = at(2026, 8, 17, 14, 0);
    const session = calculateOvertimeDurations(start, end);
    const buckets = eligibleOvertimeMinutesByCalendarDay(start, end);

    expect(buckets['2026-08-16']).toBe(16 * 60);
    // Mon 00:00 → 14:00: 14h total, 5h working (09:00–14:00), 9h eligible
    expect(buckets['2026-08-17']).toBe(9 * 60);
    expect(sumMinutes(buckets)).toBe(session.eligibleOvertimeMinutes);
  });

  it('matches Aug 12 10:00 → Aug 17 14:00 with Friday at 24 hours, not an equal share', () => {
    const start = at(2026, 8, 12, 10, 0);
    const end = at(2026, 8, 17, 14, 0);
    const session = calculateOvertimeDurations(start, end);
    const buckets = eligibleOvertimeMinutesByCalendarDay(start, end);
    const equalShare = Math.floor(session.eligibleOvertimeMinutes / 6);

    expect(bucketKeys(buckets)).toEqual([
      '2026-08-12',
      '2026-08-13',
      '2026-08-14',
      '2026-08-15',
      '2026-08-16',
      '2026-08-17',
    ]);
    expect(buckets['2026-08-12']).toBe(7 * 60);
    expect(buckets['2026-08-13']).toBe(16 * 60);
    expect(buckets['2026-08-14']).toBe(24 * 60);
    expect(buckets['2026-08-15']).toBe(16 * 60);
    expect(buckets['2026-08-16']).toBe(16 * 60);
    expect(buckets['2026-08-17']).toBe(9 * 60);
    expect(sumMinutes(buckets)).toBe(session.eligibleOvertimeMinutes);
    expect(session.eligibleOvertimeMinutes).toBe(88 * 60);
    expect(buckets['2026-08-14']).not.toBe(equalShare);
    expect(buckets['2026-08-14']).toBeGreaterThan(buckets['2026-08-13']);
  });
});

describe('allocateOvertimeTrendMinutesByCalendarDay', () => {
  it('keeps a same-day target on that calendar day even inside official hours', () => {
    const start = at(2026, 8, 1, 9, 0);
    const end = at(2026, 8, 1, 17, 0);
    const buckets = allocateOvertimeTrendMinutesByCalendarDay(
      start,
      end,
      8 * 60
    );

    expect(buckets['2026-08-01']).toBe(8 * 60);
    expect(sumMinutes(buckets)).toBe(8 * 60);
  });

  it('does not change eligible-shaped buckets when target equals eligible total', () => {
    const start = at(2026, 8, 12, 10, 0);
    const end = at(2026, 8, 17, 14, 0);
    const eligible = calculateOvertimeDurations(start, end).eligibleOvertimeMinutes;
    const buckets = allocateOvertimeTrendMinutesByCalendarDay(
      start,
      end,
      eligible
    );

    expect(buckets['2026-08-14']).toBe(24 * 60);
    expect(sumMinutes(buckets)).toBe(eligible);
  });
});
