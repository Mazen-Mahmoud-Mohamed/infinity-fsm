import {
  splitSessionMinutesAcrossCalendarDays,
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

describe('splitSessionMinutesAcrossCalendarDays', () => {
  it('assigns a same-day session to a single calendar bucket', () => {
    const start = at(2026, 8, 12, 10, 0);
    const end = at(2026, 8, 12, 14, 0);
    const totalMinutes = 240;

    const buckets = splitSessionMinutesAcrossCalendarDays(
      start,
      end,
      totalMinutes,
      TZ
    );

    expect(bucketKeys(buckets)).toEqual(['2026-08-12']);
    expect(sumMinutes(buckets)).toBe(totalMinutes);
    expect(buckets['2026-08-12']).toBe(totalMinutes);
  });

  it('splits a two-day session across both calendar days', () => {
    const start = at(2026, 8, 12, 22, 0);
    const end = at(2026, 8, 13, 2, 0);
    const totalMinutes = 240;

    const buckets = splitSessionMinutesAcrossCalendarDays(
      start,
      end,
      totalMinutes,
      TZ
    );

    expect(bucketKeys(buckets)).toEqual(['2026-08-12', '2026-08-13']);
    expect(sumMinutes(buckets)).toBe(totalMinutes);
    expect(buckets['2026-08-12']).toBe(120);
    expect(buckets['2026-08-13']).toBe(120);
    expect(buckets['2026-08-12']).toBeLessThan(totalMinutes);
  });

  it('splits a midnight-crossing session by actual overlap, not evenly', () => {
    const start = at(2026, 8, 12, 23, 30);
    const end = at(2026, 8, 13, 0, 30);
    const totalMinutes = 60;

    const buckets = splitSessionMinutesAcrossCalendarDays(
      start,
      end,
      totalMinutes,
      TZ
    );

    expect(bucketKeys(buckets)).toEqual(['2026-08-12', '2026-08-13']);
    expect(sumMinutes(buckets)).toBe(totalMinutes);
    expect(buckets['2026-08-12']).toBe(30);
    expect(buckets['2026-08-13']).toBe(30);
  });

  it('splits a 5+ day session across every touched calendar day', () => {
    const start = at(2026, 8, 12, 10, 0);
    const end = at(2026, 8, 17, 14, 0);
    const totalMinutes = 5280; // 88 hours

    const buckets = splitSessionMinutesAcrossCalendarDays(
      start,
      end,
      totalMinutes,
      TZ
    );

    expect(bucketKeys(buckets)).toEqual([
      '2026-08-12',
      '2026-08-13',
      '2026-08-14',
      '2026-08-15',
      '2026-08-16',
      '2026-08-17',
    ]);
    expect(sumMinutes(buckets)).toBe(totalMinutes);
    expect(buckets['2026-08-12']).toBeLessThan(totalMinutes);
    expect(buckets['2026-08-17']).toBeGreaterThan(0);
    expect(buckets['2026-08-13']).toBeGreaterThan(buckets['2026-08-12']);
  });

  it('matches the Aug 12 → Aug 17 long-session regression (88+ hours)', () => {
    const start = at(2026, 8, 12, 10, 0);
    const end = at(2026, 8, 17, 14, 0);
    const totalMinutes = 5292; // 88h 12m

    const buckets = splitSessionMinutesAcrossCalendarDays(
      start,
      end,
      totalMinutes,
      TZ
    );

    expect(bucketKeys(buckets)).toHaveLength(6);
    expect(sumMinutes(buckets)).toBe(totalMinutes);
    expect(buckets['2026-08-12']).not.toBe(totalMinutes);
    expect(buckets['2026-08-12']).toBeLessThan(900); // ~14h of 124h wall span
    expect(buckets['2026-08-13']).toBeGreaterThan(1000);
    expect(buckets['2026-08-17']).toBeGreaterThan(0);
    expect(buckets['2026-08-17']).toBeLessThan(buckets['2026-08-13']);
  });
});
