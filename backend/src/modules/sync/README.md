# Sync Module

Offline sync support — batch processing and status.

## Endpoints

| Method | Path | Access |
|--------|------|--------|
| POST | `/api/v1/sync/batch` | Authenticated |
| GET | `/api/v1/sync/status` | Authenticated |

## Batch Processing

Accepts ordered array of operations (START_OVERTIME, END_OVERTIME).
Each operation has its own idempotency key.
Processes sequentially — if one fails, subsequent ops are queued for retry.

## Idempotency

Uses `idempotency_records` collection with 72-hour TTL.
Duplicate keys return cached response without re-processing.

**Implementation:** Phase 3
