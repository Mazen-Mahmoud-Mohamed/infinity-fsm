import {
  CALCULATION_VERSION,
  allocateOvertimeTrendMinutesByCalendarDay,
  calculateOvertimeDurations,
  eligibleOvertimeMinutesByCalendarDay,
  isNonWorkingCalendarDay,
  isOfficialWorkingDay,
  withCustomHolidayDates,
  zonedLocalToUtc,
} from '../modules/business/overtime/overtime.calculation.js';
import { countedVacationDayKeysForRecord as excelVacationKeys } from '../modules/business/overtime/overtime.excel.export.js';
import { OFFICIAL_WORKING_HOURS } from '../modules/business/overtime/working-hours.policy.js';
import {
  isValidYmdDate,
  normalizeYmdDate,
  normalizeYmdDateList,
} from '../modules/core/settings/holiday.date.js';

const TZ = OFFICIAL_WORKING_HOURS.timeZone;

/** Wall-clock in company timezone → absolute Date. */
function at(year, month, day, hour, minute = 0) {
  return zonedLocalToUtc(TZ, year, month, day, hour, minute, 0);
}

describe('holiday date helpers', () => {
  it('accepts valid Gregorian YYYY-MM-DD', () => {
    expect(isValidYmdDate('2026-01-01')).toBe(true);
    expect(normalizeYmdDate('2026-02-28')).toBe('2026-02-28');
  });

  it('rejects impossible dates', () => {
    expect(isValidYmdDate('2026-02-30')).toBe(false);
    expect(isValidYmdDate('2026-13-01')).toBe(false);
    expect(isValidYmdDate('26-01-01')).toBe(false);
  });

  it('deduplicates date lists', () => {
    const { dates, invalid } = normalizeYmdDateList([
      '2026-01-01',
      '2026-01-01',
      '2026-01-02',
      'bad',
    ]);
    expect(dates).toEqual(['2026-01-01', '2026-01-02']);
    expect(invalid).toEqual(['bad']);
  });
});

describe('full-day non-working semantics (Friday = custom holiday)', () => {
  // 2026-09-18 Friday; 2026-09-19 Saturday holiday; 2026-09-20 Sunday working

  it('1. Friday 00:00–24:00 => 24h eligible', () => {
    const result = calculateOvertimeDurations(
      at(2026, 9, 18, 0, 0),
      at(2026, 9, 19, 0, 0)
    );
    expect(result.workingDurationMinutes).toBe(0);
    expect(result.eligibleOvertimeMinutes).toBe(24 * 60);
  });

  it('2. Custom holiday 00:00–24:00 => 24h eligible', () => {
    const hours = withCustomHolidayDates(['2026-09-19']);
    const result = calculateOvertimeDurations(
      at(2026, 9, 19, 0, 0),
      at(2026, 9, 20, 0, 0),
      hours
    );
    expect(result.workingDurationMinutes).toBe(0);
    expect(result.eligibleOvertimeMinutes).toBe(24 * 60);
  });

  it('3. Custom holiday 08:00–18:00 => 10h eligible (not 2h)', () => {
    const hours = withCustomHolidayDates(['2026-09-19']);
    const result = calculateOvertimeDurations(
      at(2026, 9, 19, 8, 0),
      at(2026, 9, 19, 18, 0),
      hours
    );
    expect(result.totalDurationMinutes).toBe(10 * 60);
    expect(result.workingDurationMinutes).toBe(0);
    expect(result.eligibleOvertimeMinutes).toBe(10 * 60);
  });

  it('4. Custom holiday 09:00–17:00 => 8h eligible', () => {
    const hours = withCustomHolidayDates(['2026-09-19']);
    const result = calculateOvertimeDurations(
      at(2026, 9, 19, 9, 0),
      at(2026, 9, 19, 17, 0),
      hours
    );
    expect(result.eligibleOvertimeMinutes).toBe(8 * 60);
    expect(result.workingDurationMinutes).toBe(0);
  });

  it('5. Custom holiday 12:00–14:00 => 2h eligible', () => {
    const hours = withCustomHolidayDates(['2026-09-19']);
    const result = calculateOvertimeDurations(
      at(2026, 9, 19, 12, 0),
      at(2026, 9, 19, 14, 0),
      hours
    );
    expect(result.eligibleOvertimeMinutes).toBe(2 * 60);
    expect(result.workingDurationMinutes).toBe(0);
  });

  it('6. Normal weekday 08:00–18:00 => 2h eligible', () => {
    // Saturday without holiday
    const result = calculateOvertimeDurations(
      at(2026, 9, 19, 8, 0),
      at(2026, 9, 19, 18, 0)
    );
    expect(result.workingDurationMinutes).toBe(8 * 60);
    expect(result.eligibleOvertimeMinutes).toBe(2 * 60);
  });

  it('7. Normal weekday 09:00–17:00 => 0h eligible', () => {
    const result = calculateOvertimeDurations(
      at(2026, 9, 19, 9, 0),
      at(2026, 9, 19, 17, 0)
    );
    expect(result.eligibleOvertimeMinutes).toBe(0);
    expect(result.workingDurationMinutes).toBe(8 * 60);
  });

  it('8. Normal weekday 12:00–14:00 => 0h eligible', () => {
    const result = calculateOvertimeDurations(
      at(2026, 9, 19, 12, 0),
      at(2026, 9, 19, 14, 0)
    );
    expect(result.eligibleOvertimeMinutes).toBe(0);
    expect(result.workingDurationMinutes).toBe(2 * 60);
  });

  it('9. Friday + custom holiday => no double counting', () => {
    const hours = withCustomHolidayDates(['2026-09-18']);
    const result = calculateOvertimeDurations(
      at(2026, 9, 18, 0, 0),
      at(2026, 9, 19, 0, 0),
      hours
    );
    expect(result.totalDurationMinutes).toBe(24 * 60);
    expect(result.workingDurationMinutes).toBe(0);
    expect(result.eligibleOvertimeMinutes).toBe(24 * 60);
    expect(
      isNonWorkingCalendarDay({ year: 2026, month: 9, day: 18 }, hours)
    ).toBe(true);
  });

  it('10. Multi-day: holiday full overlap + next normal day before/after only', () => {
    // Sat 2026-09-19 holiday, Sun 2026-09-20 normal
    // Session: Sat 20:00 → Sun 10:00
    // Holiday: 4h (20:00–24:00) all eligible
    // Sunday: 00:00–09:00 = 9h eligible, 09:00–10:00 = 1h working → 9h eligible
    const hours = withCustomHolidayDates(['2026-09-19']);
    const result = calculateOvertimeDurations(
      at(2026, 9, 19, 20, 0),
      at(2026, 9, 20, 10, 0),
      hours
    );
    expect(result.totalDurationMinutes).toBe(14 * 60);
    expect(result.workingDurationMinutes).toBe(60);
    expect(result.eligibleOvertimeMinutes).toBe(13 * 60);

    const byDay = eligibleOvertimeMinutesByCalendarDay(
      at(2026, 9, 19, 20, 0),
      at(2026, 9, 20, 10, 0),
      hours
    );
    expect(byDay['2026-09-19']).toBe(4 * 60);
    expect(byDay['2026-09-20']).toBe(9 * 60);
  });
});

describe('Excel / calendar-day allocation match shared calc', () => {
  it('11. Excel vacation keys + eligible match holiday-aware calc', () => {
    const hours = withCustomHolidayDates(['2026-09-19']);
    const startAt = at(2026, 9, 19, 8, 0);
    const endAt = at(2026, 9, 19, 18, 0);
    const calc = calculateOvertimeDurations(startAt, endAt, hours);
    expect(calc.eligibleOvertimeMinutes).toBe(10 * 60);

    const record = { startAt, endAt };
    expect(excelVacationKeys(record, hours)).toEqual(['2026-09-19']);
    expect(excelVacationKeys(record)).toEqual([]); // without holiday set: Sat is working
  });

  it('dashboard multi-day trend allocation uses holiday full-day share', () => {
    const hours = withCustomHolidayDates(['2026-09-19']);
    const startAt = at(2026, 9, 19, 20, 0);
    const endAt = at(2026, 9, 20, 10, 0);
    const eligible = calculateOvertimeDurations(
      startAt,
      endAt,
      hours
    ).eligibleOvertimeMinutes;
    const buckets = allocateOvertimeTrendMinutesByCalendarDay(
      startAt,
      endAt,
      eligible,
      hours
    );
    expect(buckets['2026-09-19']).toBe(4 * 60);
    expect(buckets['2026-09-20']).toBe(9 * 60);
  });
});

describe('isOfficialWorkingDay / isNonWorkingCalendarDay', () => {
  it('Friday remains non-working without custom holidays', () => {
    expect(isOfficialWorkingDay({ year: 2026, month: 9, day: 18 })).toBe(false);
    expect(isNonWorkingCalendarDay({ year: 2026, month: 9, day: 18 })).toBe(
      true
    );
  });

  it('custom weekday holiday becomes non-working', () => {
    const hours = withCustomHolidayDates(['2026-09-19']);
    expect(isOfficialWorkingDay({ year: 2026, month: 9, day: 19 }, hours)).toBe(
      false
    );
  });

  it('removing a holiday restores working-day behavior', () => {
    expect(
      isOfficialWorkingDay(
        { year: 2026, month: 9, day: 19 },
        withCustomHolidayDates([])
      )
    ).toBe(true);
  });
});

describe('calculation version', () => {
  it('keeps ot-v4-africa-cairo', () => {
    expect(CALCULATION_VERSION).toBe('ot-v4-africa-cairo');
  });
});
