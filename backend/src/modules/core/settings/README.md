# Settings

Organization and system settings for Infinity FSM.

## Endpoints

Mounted at `/api/v1/settings`

- `GET /organization` — company info, contact, address, working hours, timezone
- `PUT /organization` — update organization settings
- `POST /organization/logo` — upload company logo (`multipart/form-data`, field `logo`)
- `GET /system` — API/DB status, storage availability, versions, uptime

Permissions: `settings:view`, `settings:manage`

Backup/restore and deep cache wipe remain UI-only in Phase 1.
