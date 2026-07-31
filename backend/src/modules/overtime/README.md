# Overtime Module

Core business module — overtime session lifecycle, approval, and calculation.

## Endpoints

| Method | Path | Access |
|--------|------|--------|
| GET | `/api/v1/overtime/running` | Technician (own) |
| GET | `/api/v1/overtime/mine` | Technician (own history) |
| GET | `/api/v1/overtime/stats` | Admin (`overtime:view_all`) |
| GET | `/api/v1/overtime` | Admin (`overtime:view_all`) |
| POST | `/api/v1/overtime/start` | Technician |
| GET | `/api/v1/overtime/:id` | Own or Admin |
| POST | `/api/v1/overtime/:id/end` | Technician (own) |
| POST | `/api/v1/overtime/:id/approve` | Admin (`overtime:approve`) |
| POST | `/api/v1/overtime/:id/reject` | Admin (`overtime:reject`) |

## State Machine

```
RUNNING → PENDING_REVIEW → APPROVED
                         → REJECTED
```

## Critical Rules

- Only one RUNNING session per technician (partial unique index)
- Overtime calculation runs ONLY on server at end submission
- Approve / reject restricted to Admin permissions
- Technicians can only view their own sessions via `/mine` and own `:id`
