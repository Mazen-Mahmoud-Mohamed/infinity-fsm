# RBAC / Roles & Permissions

Dynamic role management extending the existing static RBAC constants.

## Endpoints

Mounted at `/api/v1/roles`

- `GET /dashboard` — role analytics
- `GET /permissions` — permission catalog
- `GET /` — list roles (search, pagination, filters)
- `POST /` — create custom role
- `GET /:id` — role details
- `PUT /:id` — update role
- `PATCH /:id/status` — activate / deactivate
- `DELETE /:id` — soft-delete custom role
- `POST /:id/clone` — clone role
- `GET /:id/users` — users assigned to role
- `POST /:id/assign-users` — assign role to users

System roles (`ADMIN`, `SUPERVISOR`, `TECHNICIAN`, `WAREHOUSE`, `VIEWER`, `HR`) are seeded automatically and cannot be deleted.
