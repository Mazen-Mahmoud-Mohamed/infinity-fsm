# Audit Log Module

Immutable audit trail for compliance and debugging.

## Endpoints

| Method | Path | Access |
|--------|------|--------|
| GET | `/api/v1/audit-logs` | Admin |
| GET | `/api/v1/audit-logs/:id` | Admin |

## Logged Events

- Authentication (login success/failure, logout)
- Overtime lifecycle (start, end, approve, reject)
- User management (create, update, delete)
- Settings changes
- Admin actions

## Rules

- **Append-only** — no updates or deletes
- Includes actor, role, IP, user agent, timestamp
- Filterable by action, actor, resource, date range

**Implementation:** Phase 1 (basic), Phase 4 (full)
