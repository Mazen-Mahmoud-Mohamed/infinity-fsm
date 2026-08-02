# Overtime Module (MVP)

First business module — full implementation.

## State Machine

```
DRAFT → RUNNING → PENDING_REVIEW → APPROVED → ARCHIVED
                                 → REJECTED → ARCHIVED
```

See [ARCHITECTURE.md](../../../../docs/ARCHITECTURE.md) Section 13 for transition permissions.

## Endpoints

| Method | Path | Permission |
|--------|------|------------|
| GET | `/overtime/running` | `overtime:view_own` |
| POST | `/overtime/start` | `overtime:start` |
| POST | `/overtime/:id/end` | `overtime:end` |
| POST | `/overtime/:id/cancel` | `overtime:cancel` |
| POST | `/overtime/:id/approve` | `overtime:approve` |
| POST | `/overtime/:id/reject` | `overtime:reject` |
| POST | `/overtime/:id/archive` | `overtime:archive` |
| GET | `/overtime` | `overtime:view_*` |
| GET | `/overtime/:id` | `overtime:view_*` |
| GET | `/overtime/pending-review` | `overtime:view_team` |

## Duration calculation

Authoritative implementation:

- `working-hours.policy.js` — official window `09:00→17:00` (`Africa/Cairo`)
- `overtime.calculation.js` — `calculateOvertimeDurations(startAt, endAt)`

Rules:

- **Working days:** Saturday–Thursday
- **Friday:** full overtime day (working duration = 0 for Friday segments)
- **Working duration** = overlap with official hours `[09:00, 17:00)` on working days only
- **Eligible overtime** = total duration − working duration (never negative)
- Same formula for **NORMAL** and **TRAVEL**
- Absolute timestamps stored in UTC; overlap uses company timezone wall-clock
- Applied on session **end**; Flutter offline uses the mirrored `OvertimeCalculator`

### Historical recalculation

One-time script (not auto-run):

```bash
npm run migrate:overtime-durations          # dry-run
npm run migrate:overtime-durations:apply    # write
```

## Domain Services

- `overtime.calculation.js` — Server-side eligible OT calculation
- `working-hours.policy.js` — Official hours + Friday rule (central config)
- `overtime.timeline.js` — Online vs offline start/end resolution

## Extended Data

- **GPS:** latitude, longitude, accuracy, altitude, heading, speed, timestamp, provider
- **Device:** platform, manufacturer, phoneModel, osVersion, appVersion, deviceIdentifier
- **Travel:** governorate, destination, reason, distance, estimated/actual travel time
- **Links:** optional workOrderId, vehicleId

## Module Registrations

Registers: 10 permissions, 6 audit actions, 4 notification templates, 1 search entity, 8 dashboard KPIs, 7 report types, 2 sync operations, 6 socket events.

**Implementation:** Phase 2
