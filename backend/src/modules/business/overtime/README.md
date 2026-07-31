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

## Domain Services

- `overtime-calculator.service.js` — Server-side calculation
- `overtime-state-machine.service.js` — Transition validation
- `working-hours.policy.js` — Official hours + holiday exclusion

## Extended Data

- **GPS:** latitude, longitude, accuracy, altitude, heading, speed, timestamp, provider
- **Device:** platform, manufacturer, phoneModel, osVersion, appVersion, deviceIdentifier
- **Travel:** governorate, destination, reason, distance, estimated/actual travel time
- **Links:** optional workOrderId, vehicleId

## Module Registrations

Registers: 10 permissions, 6 audit actions, 4 notification templates, 1 search entity, 8 dashboard KPIs, 7 report types, 2 sync operations, 6 socket events.

**Implementation:** Phase 2
