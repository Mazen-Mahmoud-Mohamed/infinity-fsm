import {
  CALCULATION_VERSION,
  calculateOvertimeDurations,
  zonedLocalToUtc,
} from '../modules/business/overtime/overtime.calculation.js';
import { OFFICIAL_WORKING_HOURS } from '../modules/business/overtime/working-hours.policy.js';

const TZ = OFFICIAL_WORKING_HOURS.timeZone;

/** Wall-clock in company timezone → absolute Date. */
function at(year, month, day, hour, minute = 0) {
  return zonedLocalToUtc(TZ, year, month, day, hour, minute, 0);
}

describe('calculateOvertimeDurations (official 09:00–17:00)', () => {
  it('exposes calculation version', () => {
    const result = calculateOvertimeDurations(
      at(2026, 8, 1, 4, 0),
      at(2026, 8, 1, 12, 0)
    );
    expect(result.calculationVersion).toBe(CALCULATION_VERSION);
  });

  it('Example A: 04:00 → 12:00 → working 3h, eligible 5h', () => {
    const result = calculateOvertimeDurations(
      at(2026, 8, 1, 4, 0),
      at(2026, 8, 1, 12, 0)
    );
    expect(result.totalDurationMinutes).toBe(8 * 60);
    expect(result.workingDurationMinutes).toBe(3 * 60);
    expect(result.eligibleOvertimeMinutes).toBe(5 * 60);
  });

  it('Example B: 14:00 → 18:00 → working 3h, eligible 1h', () => {
    const result = calculateOvertimeDurations(
      at(2026, 8, 1, 14, 0),
      at(2026, 8, 1, 18, 0)
    );
    expect(result.totalDurationMinutes).toBe(4 * 60);
    expect(result.workingDurationMinutes).toBe(3 * 60);
    expect(result.eligibleOvertimeMinutes).toBe(1 * 60);
  });

  it('Example C: 18:00 → 23:00 → working 0, eligible 5h', () => {
    const result = calculateOvertimeDurations(
      at(2026, 8, 1, 18, 0),
      at(2026, 8, 1, 23, 0)
    );
    expect(result.totalDurationMinutes).toBe(5 * 60);
    expect(result.workingDurationMinutes).toBe(0);
    expect(result.eligibleOvertimeMinutes).toBe(5 * 60);
  });

  it('Example D: 07:00 → 08:30 → working 0, eligible 1h30m', () => {
    const result = calculateOvertimeDurations(
      at(2026, 8, 1, 7, 0),
      at(2026, 8, 1, 8, 30)
    );
    expect(result.totalDurationMinutes).toBe(90);
    expect(result.workingDurationMinutes).toBe(0);
    expect(result.eligibleOvertimeMinutes).toBe(90);
  });

  it('Example E: 08:00 → 20:00 → working 8h, eligible 4h', () => {
    const result = calculateOvertimeDurations(
      at(2026, 8, 1, 8, 0),
      at(2026, 8, 1, 20, 0)
    );
    expect(result.totalDurationMinutes).toBe(12 * 60);
    expect(result.workingDurationMinutes).toBe(8 * 60);
    expect(result.eligibleOvertimeMinutes).toBe(4 * 60);
  });

  it('midnight crossing: 22:00 → 04:00 → 6h eligible, 0 working', () => {
    const result = calculateOvertimeDurations(
      at(2026, 8, 1, 22, 0),
      at(2026, 8, 2, 4, 0)
    );
    expect(result.totalDurationMinutes).toBe(6 * 60);
    expect(result.workingDurationMinutes).toBe(0);
    expect(result.eligibleOvertimeMinutes).toBe(6 * 60);
  });

  it('fully inside official hours: 10:00 → 16:00 → eligible 0', () => {
    const result = calculateOvertimeDurations(
      at(2026, 8, 1, 10, 0),
      at(2026, 8, 1, 16, 0)
    );
    expect(result.totalDurationMinutes).toBe(6 * 60);
    expect(result.workingDurationMinutes).toBe(6 * 60);
    expect(result.eligibleOvertimeMinutes).toBe(0);
  });

  it('exactly official window: 09:00 → 17:00 → eligible 0', () => {
    const result = calculateOvertimeDurations(
      at(2026, 8, 1, 9, 0),
      at(2026, 8, 1, 17, 0)
    );
    expect(result.totalDurationMinutes).toBe(8 * 60);
    expect(result.workingDurationMinutes).toBe(8 * 60);
    expect(result.eligibleOvertimeMinutes).toBe(0);
  });

  it('starts at 17:00 → all eligible', () => {
    const result = calculateOvertimeDurations(
      at(2026, 8, 1, 17, 0),
      at(2026, 8, 1, 19, 0)
    );
    expect(result.totalDurationMinutes).toBe(2 * 60);
    expect(result.workingDurationMinutes).toBe(0);
    expect(result.eligibleOvertimeMinutes).toBe(2 * 60);
  });

  it('multi-day: 20:00 day1 → 10:00 day2', () => {
    const result = calculateOvertimeDurations(
      at(2026, 8, 1, 20, 0),
      at(2026, 8, 2, 10, 0)
    );
    // 14h total; working = 09:00–10:00 = 1h; eligible = 13h
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
      [at(2026, 8, 1, 9, 0), at(2026, 8, 3, 9, 0)],
      [at(2026, 8, 1, 23, 30), at(2026, 8, 2, 0, 15)],
    ];
    for (const [start, end] of cases) {
      const result = calculateOvertimeDurations(start, end);
      expect(result.eligibleOvertimeMinutes).toBe(
        result.totalDurationMinutes - result.workingDurationMinutes
      );
    }
  });
});
