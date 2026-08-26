# Notifications Module

Recipient-targeted in-app notifications with Socket.IO realtime and FCM push.

## Endpoints

| Method | Path | Access |
|--------|------|--------|
| GET | `/api/v1/notifications` | Authenticated (own inbox) |
| GET | `/api/v1/notifications/unread-count` | Authenticated |
| PUT | `/api/v1/notifications/:id/read` | Owner |
| PUT | `/api/v1/notifications/read-all` | Authenticated |
| POST | `/api/v1/notifications/device-tokens` | Authenticated (token bound to JWT user) |
| DELETE | `/api/v1/notifications/device-tokens` | Authenticated (deactivate own token) |

## Delivery pipeline

1. Business event (work order / overtime)
2. Persist `notifications` document (dedupeKey prevents duplicates)
3. Emit `notification:new` via Socket.IO to `user:{userId}`
4. Send FCM to active device tokens for that user (Android)
5. Flutter shows OS / desktop notification and updates unread badge

Push failures never fail the business operation.

## Environment

See backend `.env.example`:

- `FCM_ENABLED`
- `FIREBASE_SERVICE_ACCOUNT_JSON` or `FIREBASE_SERVICE_ACCOUNT_PATH`
