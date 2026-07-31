import { resolveSessionTimeline } from '../modules/business/overtime/overtime.timeline.js';

describe('resolveSessionTimeline', () => {
  const serverStart = new Date('2026-07-30T20:00:00.000Z');
  const serverEnd = new Date('2026-07-30T20:01:00.000Z');

  it('uses server timestamps when client omits offline fields (online workflow)', () => {
    const result = resolveSessionTimeline({
      body: {},
      fallbackStartAt: serverStart,
      fallbackEndAt: serverEnd,
    });

    expect(result.startedAt).toEqual(serverStart);
    expect(result.endedAt).toEqual(serverEnd);
    expect(result.durationSeconds).toBeNull();
    expect(result.usedClientStart).toBe(false);
    expect(result.usedClientEnd).toBe(false);
  });

  it('preserves client offline timeline when provided', () => {
    const startedAt = '2026-07-30T17:00:00.000Z';
    const endedAt = '2026-07-30T17:12:30.000Z';

    const result = resolveSessionTimeline({
      body: {
        startedAt,
        endedAt,
        durationSeconds: '750',
      },
      fallbackStartAt: serverStart,
      fallbackEndAt: serverEnd,
    });

    expect(result.startedAt.toISOString()).toBe(startedAt);
    expect(result.endedAt.toISOString()).toBe(endedAt);
    expect(result.durationSeconds).toBe(750);
    expect(result.usedClientStart).toBe(true);
    expect(result.usedClientEnd).toBe(true);
  });

  it('rejects endedAt before startedAt', () => {
    expect(() =>
      resolveSessionTimeline({
        body: {
          startedAt: '2026-07-30T17:12:30.000Z',
          endedAt: '2026-07-30T17:00:00.000Z',
          durationSeconds: 0,
        },
        fallbackStartAt: serverStart,
        fallbackEndAt: serverEnd,
      })
    ).toThrow(/endedAt must be greater than or equal to startedAt/);
  });

  it('rejects negative durationSeconds', () => {
    expect(() =>
      resolveSessionTimeline({
        body: {
          startedAt: '2026-07-30T17:00:00.000Z',
          endedAt: '2026-07-30T17:12:30.000Z',
          durationSeconds: -1,
        },
        fallbackStartAt: serverStart,
        fallbackEndAt: serverEnd,
      })
    ).toThrow(/durationSeconds must be a number >= 0/);
  });
});
