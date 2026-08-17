import {
  CALCULATION_VERSION,
  assertReasonableSessionLength,
  calculateOvertimeDurations,
  zonedLocalToUtc,
} from '../modules/business/overtime/overtime.calculation.js';
import { OFFICIAL_WORKING_HOURS } from '../modules/business/overtime/working-hours.policy.js';

const TZ = OFFICIAL_WORKING_HOURS.timeZone;

/** Wall-clock in company timezone → absolute Date. */
function at(year, month, day, hour, minute = 0) {
  return zonedLocalToUtc(TZ, year, month, day, hour, minute, 0);
}

describe('calculateOvertimeDurations (official 09:00–17:00, Fri = full OT)', () => {
  it('exposes calculation version', () => {
    const result = calculateOvertimeDurations(
      at(2026, 8, 1, 4, 0),
      at(2026, 8, 1, 12, 0)
    );
    expect(result.calculationVersion).toBe(CALCULATION_VERSION);
  });

  // 2026-08-01 is Saturday (working day)
  it('Example A: Sat 04:00 → 12:00 → working 3h, eligible 5h', () => {
    const result = calculateOvertimeDurations(
      at(2026, 8, 1, 4, 0),
      at(2026, 8, 1, 12, 0)
    );
    expect(result.totalDurationMinutes).toBe(8 * 60);
    expect(result.workingDurationMinutes).toBe(3 * 60);
    expect(result.eligibleOvertimeMinutes).toBe(5 * 60);
  });

  it('Example B: Sat 14:00 → 18:00 → working 3h, eligible 1h', () => {
    const result = calculateOvertimeDurations(
      at(2026, 8, 1, 14, 0),
      at(2026, 8, 1, 18, 0)
    );
    expect(result.totalDurationMinutes).toBe(4 * 60);
    expect(result.workingDurationMinutes).toBe(3 * 60);
    expect(result.eligibleOvertimeMinutes).toBe(1 * 60);
  });

  it('Example C: Sat 18:00 → 23:00 → working 0, eligible 5h', () => {
    const result = calculateOvertimeDurations(
      at(2026, 8, 1, 18, 0),
      at(2026, 8, 1, 23, 0)
    );
    expect(result.totalDurationMinutes).toBe(5 * 60);
    expect(result.workingDurationMinutes).toBe(0);
    expect(result.eligibleOvertimeMinutes).toBe(5 * 60);
  });

  it('Example D: Sat 07:00 → 08:30 → working 0, eligible 1h30m', () => {
    const result = calculateOvertimeDurations(
      at(2026, 8, 1, 7, 0),
      at(2026, 8, 1, 8, 30)
    );
    expect(result.totalDurationMinutes).toBe(90);
    expect(result.workingDurationMinutes).toBe(0);
    expect(result.eligibleOvertimeMinutes).toBe(90);
  });

  it('Example E: Sat 08:00 → 20:00 → working 8h, eligible 4h', () => {
    const result = calculateOvertimeDurations(
      at(2026, 8, 1, 8, 0),
      at(2026, 8, 1, 20, 0)
    );
    expect(result.totalDurationMinutes).toBe(12 * 60);
    expect(result.workingDurationMinutes).toBe(8 * 60);
    expect(result.eligibleOvertimeMinutes).toBe(4 * 60);
  });

  it('midnight crossing Sat→Sun: 22:00 → 04:00 → 6h eligible', () => {
    const result = calculateOvertimeDurations(
      at(2026, 8, 1, 22, 0),
      at(2026, 8, 2, 4, 0)
    );
    expect(result.totalDurationMinutes).toBe(6 * 60);
    expect(result.workingDurationMinutes).toBe(0);
    expect(result.eligibleOvertimeMinutes).toBe(6 * 60);
  });

  // 2026-07-31 is Friday
  it('Friday full day: all eligible, working 0', () => {
    const result = calculateOvertimeDurations(
      at(2026, 7, 31, 0, 0),
      at(2026, 7, 31, 23, 59)
    );
    expect(result.totalDurationMinutes).toBe(23 * 60 + 59);
    expect(result.workingDurationMinutes).toBe(0);
    expect(result.eligibleOvertimeMinutes).toBe(23 * 60 + 59);
  });

  it('Friday during former office hours still counts as OT', () => {
    const result = calculateOvertimeDurations(
      at(2026, 7, 31, 9, 0),
      at(2026, 7, 31, 17, 0)
    );
    expect(result.totalDurationMinutes).toBe(8 * 60);
    expect(result.workingDurationMinutes).toBe(0);
    expect(result.eligibleOvertimeMinutes).toBe(8 * 60);
  });

  // Thursday 2026-07-30 → Friday 2026-07-31
  it('Thu 22:00 → Fri 08:00 → working 0, eligible 10h', () => {
    const result = calculateOvertimeDurations(
      at(2026, 7, 30, 22, 0),
      at(2026, 7, 31, 8, 0)
    );
    expect(result.totalDurationMinutes).toBe(10 * 60);
    expect(result.workingDurationMinutes).toBe(0);
    expect(result.eligibleOvertimeMinutes).toBe(10 * 60);
  });

  it('fully inside official hours on working day: eligible 0', () => {
    const result = calculateOvertimeDurations(
      at(2026, 8, 1, 10, 0),
      at(2026, 8, 1, 16, 0)
    );
    expect(result.totalDurationMinutes).toBe(6 * 60);
    expect(result.workingDurationMinutes).toBe(6 * 60);
    expect(result.eligibleOvertimeMinutes).toBe(0);
  });

  it('exactly official window on working day: eligible 0', () => {
    const result = calculateOvertimeDurations(
      at(2026, 8, 1, 9, 0),
      at(2026, 8, 1, 17, 0)
    );
    expect(result.totalDurationMinutes).toBe(8 * 60);
    expect(result.workingDurationMinutes).toBe(8 * 60);
    expect(result.eligibleOvertimeMinutes).toBe(0);
  });

  it('multi-day Sat 20:00 → Sun 10:00', () => {
    const result = calculateOvertimeDurations(
      at(2026, 8, 1, 20, 0),
      at(2026, 8, 2, 10, 0)
    );
    // 14h total; working = Sun 09:00–10:00 = 1h; eligible = 13h
    expect(result.totalDurationMinutes).toBe(14 * 60);
    expect(result.workingDurationMinutes).toBe(1 * 60);
    expect(result.eligibleOvertimeMinutes).toBe(13 * 60);
  });

  it('never returns negatives for inverted range', () => {
    const result = calculateOvertimeDurations(
      at(2026, 8, 1, 12, 0),
      at(2026, 8, 1, 10, 0)
    );
    expect(result.totalDurationMinutes).toBe(0);
    expect(result.workingDurationMinutes).toBe(0);
    expect(result.eligibleOvertimeMinutes).toBe(0);
  });

  it('eligible always equals total − working', () => {
    const cases = [
      [at(2026, 8, 1, 3, 15), at(2026, 8, 1, 21, 45)],
      [at(2026, 7, 31, 8, 0), at(2026, 7, 31, 18, 0)],
      [at(2026, 7, 30, 22, 0), at(2026, 7, 31, 10, 0)],
      [at(2026, 8, 1, 23, 30), at(2026, 8, 2, 0, 15)],
    ];
    for (const [start, end] of cases) {
      const result = calculateOvertimeDurations(start, end);
      expect(result.eligibleOvertimeMinutes).toBe(
        result.totalDurationMinutes - result.workingDurationMinutes
      );
    }
  });

  it('calculates a session longer than 48 hours without rejecting', () => {
    const result = calculateOvertimeDurations(
      at(2026, 8, 1, 8, 0),
      at(2026, 8, 4, 10, 0)
    );
    expect(result.totalDurationMinutes).toBe(74 * 60);
    expect(result.eligibleOvertimeMinutes).toBe(
      result.totalDurationMinutes - result.workingDurationMinutes
    );
  });
});

describe('assertReasonableSessionLength (soft 16h policy helper)', () => {
  it('treats a 72-hour span as exceeding the 16-hour review threshold', () => {
    const start = at(2026, 8, 1, 8, 0);
    const end = at(2026, 8, 4, 8, 0);
    expect(assertReasonableSessionLength(start, end, 16)).toBe(false);
  });

  it('does not treat a 4-hour span as exceeding the 16-hour review threshold', () => {
    const start = at(2026, 8, 1, 8, 0);
    const end = at(2026, 8, 1, 12, 0);
    expect(assertReasonableSessionLength(start, end, 16)).toBe(true);
  });
});
