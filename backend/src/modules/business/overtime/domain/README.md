# Overtime Domain (business module)

## Authoritative calculation

| File | Purpose |
|------|---------|
| `../working-hours.policy.js` | Official hours `09:00–17:00`, timezone `Africa/Cairo`, Friday = full OT |
| `../overtime.calculation.js` | Single shared `calculateOvertimeDurations(startAt, endAt)` |
| `../overtime.timeline.js` | Online vs offline start/end resolution |
| `../overtime.service.js` | Applies calculator on session **end**; list/approve return stored fields |

## Rules

- Eligible OT = total − working (never negative)
- Working = overlap with `[09:00, 17:00)` on Saturday–Thursday (Cairo)
- Friday segments: working = 0 (full overtime day)
- Multi-day / midnight: split by Cairo calendar day

## Tests

See `backend/src/__tests__/overtime.calculation.test.js`.

Historical recalculation: `npm run migrate:overtime-durations:apply`
