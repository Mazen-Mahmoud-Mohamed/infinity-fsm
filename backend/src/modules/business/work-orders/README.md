# Work Orders Module

Online MVP + Field Execution (Phase 2) implemented. Offline sync is prepared on the mobile repository interface only.

## Status Enum

`PENDING` | `ASSIGNED` | `ACCEPTED` | `REJECTED` | `IN_PROGRESS` | `COMPLETED` | `CANCELLED`

## Endpoints

| Method | Path | Permission |
|--------|------|------------|
| GET/POST | `/work-orders` | `view_team`/`view_all` / `create` |
| GET | `/work-orders/my-assignments` | `view_own` |
| GET/PUT/DELETE | `/work-orders/:id` | scoped view / `update` |
| POST | `/work-orders/:id/assign` | `assign` |
| POST | `/work-orders/:id/accept` | assignee + `view_own` |
| POST | `/work-orders/:id/reject` | assignee + `view_own` |
| POST | `/work-orders/:id/before-work` | assignee + `view_own` (multipart `photos`) |
| POST | `/work-orders/:id/start` | assignee + `view_own` (requires GPS body) |
| POST | `/work-orders/:id/progress-notes` | assignee + `view_own` |
| POST | `/work-orders/:id/progress-photos` | assignee + `view_own` |
| POST | `/work-orders/:id/after-photos` | assignee + `view_own` |
| DELETE | `/work-orders/:id/photos` | assignee + `view_own` (`category`, `url`) |
| POST | `/work-orders/:id/complete` | `complete` (requires GPS + ≥1 after photo) |
| POST | `/work-orders/:id/cancel` | `cancel` |

## Field execution fields

`beforePhotos`, `afterPhotos`, `progressPhotos`, `beforeNotes`, `progressNotes`, `completionNotes`, `startedLocation`, `completedLocation`, `timeline[]`
