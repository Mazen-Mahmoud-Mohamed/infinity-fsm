import dashboardService, {
  buildOvertimeTrendDayMap,
  overtimeRecordTrendMinutes,
  mergeOvertimeTrendFacetToDayMap,
  resolveTrendWindow,
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

describe('dashboard overtime trend window + merge', () => {
  it('caps chart buckets at 31 days for long/custom periods', () => {
    const from = at(2026, 1, 1, 0, 0);
    const to = at(2026, 12, 31, 23, 59);
    const { buckets, trendFrom, trendTo } = resolveTrendWindow(from, to);

    expect(buckets.length).toBe(31);
    expect(buckets[0].key).toBe('2026-12-01');
    expect(buckets[buckets.length - 1].key).toBe('2026-12-31');
    expect(trendFrom).toEqual(buckets[0].from);
    expect(trendTo).toEqual(buckets[buckets.length - 1].to);
  });

  it('preserves short-period bucket count (today / week)', () => {
    const from = at(2026, 8, 10, 0, 0);
    const to = at(2026, 8, 12, 23, 59);
    const { buckets } = resolveTrendWindow(from, to);

    expect(buckets.length).toBe(3);
    expect(buckets.map((b) => b.key)).toEqual([
      '2026-08-10',
      '2026-08-11',
      '2026-08-12',
    ]);
  });

  it('returns chart series with Flutter-compatible point shape when empty', () => {
    const from = at(2026, 8, 12, 0, 0);
    const to = at(2026, 8, 12, 23, 59);
    const charts = dashboardService._mapTrendCharts({
      from,
      to,
      otMinutesMap: {},
      woRows: [],
      pmRows: [],
    });

    expect(charts.overtime).toHaveLength(1);
    expect(charts.overtime[0]).toEqual({ label: '8/12', value: 0 });
    expect(charts.workOrders[0]).toEqual({ label: '8/12', value: 0 });
    expect(charts.preventiveMaintenance[0]).toEqual({
      label: '8/12',
      value: 0,
    });
  });

  it('merges Mongo same-day groups with Node multi-day allocation', () => {
    const multiDay = [
      {
        startAt: at(2026, 8, 12, 22, 0),
        endAt: at(2026, 8, 13, 2, 0),
        eligibleOvertimeMinutes: 240,
      },
    ];
    const merged = mergeOvertimeTrendFacetToDayMap({
      sameDay: [{ _id: '2026-08-12', minutes: 120 }],
      multiDay,
    });

    expect(merged['2026-08-12']).toBe(120 + 120);
    expect(merged['2026-08-13']).toBe(120);
    expect(sumMinutes(merged)).toBe(120 + totalTrendMinutes(multiDay));
  });

  it('handles empty aggregation facet (no overtime in window)', () => {
    expect(mergeOvertimeTrendFacetToDayMap(undefined)).toEqual({});
    expect(mergeOvertimeTrendFacetToDayMap({ sameDay: [], multiDay: [] })).toEqual(
      {}
    );
  });

  it('_mapTrendCharts response shape matches Flutter chart DTO', () => {
    const from = at(2026, 8, 11, 0, 0);
    const to = at(2026, 8, 12, 23, 59);
    const records = [
      {
        startAt: at(2026, 8, 12, 10, 0),
        endAt: at(2026, 8, 12, 14, 0),
        approvedHours: 4,
      },
    ];
    const fromRecords = dashboardService._mapTrendCharts({
      from,
      to,
      overtimeRecords: records,
      woRows: [{ _id: '2026-08-12', count: 2 }],
      pmRows: [],
    });
    const fromMap = dashboardService._mapTrendCharts({
      from,
      to,
      otMinutesMap: buildOvertimeTrendDayMap(records),
      woRows: [{ _id: '2026-08-12', count: 2 }],
      pmRows: [],
    });

    expect(fromMap).toEqual(fromRecords);
    expect(fromMap.overtime).toEqual(
      expect.arrayContaining([
        expect.objectContaining({ label: expect.any(String), value: 4 }),
      ])
    );
    expect(fromMap.workOrders.find((p) => p.value === 2)).toBeTruthy();
  });

  it('scopes multi-user day minutes additively (technician filter contract)', () => {
    const records = [
      {
        startAt: at(2026, 8, 12, 8, 0),
        endAt: at(2026, 8, 12, 10, 0),
        eligibleOvertimeMinutes: 120,
      },
      {
        startAt: at(2026, 8, 12, 18, 0),
        endAt: at(2026, 8, 12, 20, 0),
        eligibleOvertimeMinutes: 90,
      },
    ];
    const merged = mergeOvertimeTrendFacetToDayMap({
      sameDay: [
        { _id: '2026-08-12', minutes: 120 },
        { _id: '2026-08-12', minutes: 90 },
      ],
      multiDay: [],
    });

    expect(merged['2026-08-12']).toBe(210);
    expect(sumMinutes(merged)).toBe(totalTrendMinutes(records));
  });
});
