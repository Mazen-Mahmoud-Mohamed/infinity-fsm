# Notifications Module

In-app notification creation and delivery.

## Endpoints

| Method | Path | Access |
|--------|------|--------|
| GET | `/api/v1/notifications` | Authenticated |
| PUT | `/api/v1/notifications/:id/read` | Owner |
| PUT | `/api/v1/notifications/read-all` | Authenticated |
| GET | `/api/v1/notifications/unread-count` | Authenticated |

## Notification Types

- `OVERTIME_APPROVED`
- `OVERTIME_REJECTED`
- `OVERTIME_PENDING_REVIEW`
- `SYSTEM_ANNOUNCEMENT`

## Delivery

1. Persist to `notifications` collection
2. Emit `notification:new` via Socket.IO to user room
3. (Future) Push via Firebase Cloud Messaging

**Implementation:** Phase 2 (basic), Phase 6 (push)
