import {
  buildOvertimeTrendDayMap,
  overtimeRecordTrendMinutes,
} from '../modules/core/dashboard/dashboard.service.js';
import {
  calculateOvertimeDurations,
  zonedLocalToUtc,
} from '../modules/business/overtime/overtime.calculation.js';
import { OFFICIAL_WORKING_HOURS } from '../modules/business/overtime/working-hours.policy.js';

const TZ = OFFICIAL_WORKING_HOURS.timeZone;

function at(year, month, day, hour, minute = 0) {
  return zonedLocalToUtc(TZ, year, month, day, hour, minute, 0);
}

function sumMinutes(map) {
  return Object.values(map).reduce((total, minutes) => total + minutes, 0);
}

function totalTrendMinutes(records) {
  return records.reduce(
    (total, record) => total + overtimeRecordTrendMinutes(record),
    0
  );
}

describe('dashboard overtime trend day aggregation', () => {
  it('uses approvedHours for trend minutes without changing record totals', () => {
    const record = {
      startAt: at(2026, 8, 12, 10, 0),
      endAt: at(2026, 8, 12, 14, 0),
      approvedHours: 4,
      eligibleOvertimeMinutes: 500,
    };

    expect(overtimeRecordTrendMinutes(record)).toBe(240);
  });

  it('falls back to eligibleOvertimeMinutes when approvedHours is absent', () => {
    const record = {
      startAt: at(2026, 8, 12, 10, 0),
      endAt: at(2026, 8, 12, 14, 0),
      eligibleOvertimeMinutes: 180,
    };

    expect(overtimeRecordTrendMinutes(record)).toBe(180);
  });

  it('keeps chart bucket totals equal to approved/eligible minutes', () => {
    const records = [
      {
        startAt: at(2026, 8, 12, 10, 0),
        endAt: at(2026, 8, 12, 14, 0),
        approvedHours: 4,
      },
      {
        startAt: at(2026, 8, 12, 22, 0),
        endAt: at(2026, 8, 13, 2, 0),
        eligibleOvertimeMinutes: 240,
      },
    ];

    const dayMap = buildOvertimeTrendDayMap(records);

    expect(sumMinutes(dayMap)).toBe(totalTrendMinutes(records));
  });

  it('does not attribute an entire multi-day session to its start date', () => {
    const records = [
      {
        startAt: at(2026, 8, 12, 10, 0),
        endAt: at(2026, 8, 17, 14, 0),
        approvedHours: 88,
      },
    ];

    const dayMap = buildOvertimeTrendDayMap(records);
    const total = totalTrendMinutes(records);

    expect(Object.keys(dayMap).sort()).toEqual([
      '2026-08-12',
      '2026-08-13',
      '2026-08-14',
      '2026-08-15',
      '2026-08-16',
      '2026-08-17',
    ]);
    expect(sumMinutes(dayMap)).toBe(total);
    expect(dayMap['2026-08-12']).toBeLessThan(total);
    expect(dayMap['2026-08-14']).toBe(24 * 60);
  });

  it('assigns Friday 24h and weekday eligible hours for the Aug 12 → Aug 17 session', () => {
    const startAt = at(2026, 8, 12, 10, 0);
    const endAt = at(2026, 8, 17, 14, 0);
    const eligible = calculateOvertimeDurations(startAt, endAt)
      .eligibleOvertimeMinutes;
    const records = [
      {
        startAt,
        endAt,
        approvedHours: 88,
        eligibleOvertimeMinutes: eligible,
      },
    ];

    const dayMap = buildOvertimeTrendDayMap(records);
    const equalShare = Math.floor(eligible / 6);

    expect(dayMap['2026-08-12']).toBe(7 * 60);
    expect(dayMap['2026-08-13']).toBe(16 * 60);
    expect(dayMap['2026-08-14']).toBe(24 * 60);
    expect(dayMap['2026-08-15']).toBe(16 * 60);
    expect(dayMap['2026-08-16']).toBe(16 * 60);
    expect(dayMap['2026-08-17']).toBe(9 * 60);
    expect(sumMinutes(dayMap)).toBe(eligible);
    expect(sumMinutes(dayMap)).toBe(totalTrendMinutes(records));
    expect(dayMap['2026-08-14']).not.toBe(equalShare);
  });

  it('sums multiple sessions on the same calendar day', () => {
    const records = [
      {
        startAt: at(2026, 8, 12, 8, 0),
        endAt: at(2026, 8, 12, 10, 0),
        eligibleOvertimeMinutes: 120,
      },
      {
        startAt: at(2026, 8, 12, 18, 0),
        endAt: at(2026, 8, 12, 20, 0),
        eligibleOvertimeMinutes: 120,
      },
    ];

    const dayMap = buildOvertimeTrendDayMap(records);

    expect(dayMap['2026-08-12']).toBe(240);
    expect(sumMinutes(dayMap)).toBe(totalTrendMinutes(records));
  });

  it('ignores open sessions without endAt', () => {
    const records = [
      {
        startAt: at(2026, 8, 12, 10, 0),
        endAt: null,
        approvedHours: 88,
      },
    ];

    expect(buildOvertimeTrendDayMap(records)).toEqual({});
  });
});
