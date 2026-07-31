# Organization Module

6-level company hierarchy and user management.

## Hierarchy

```
Company → Branch → Region → City → Department → Team → User
```

## Endpoints

| Entity | CRUD Path | Manage Permission |
|--------|-----------|-------------------|
| Branches | `/organization/branches` | `organization:manage_branches` |
| Regions | `/organization/regions` | `organization:manage_regions` |
| Cities | `/organization/cities` | `organization:manage_cities` |
| Departments | `/organization/departments` | `organization:manage_departments` |
| Teams | `/organization/teams` | `organization:manage_teams` |
| Users | `/organization/users` | `organization:manage_users` |
| Tree | `/organization/hierarchy` | `organization:view` |

## Models

- `branches`, `regions`, `cities`, `departments`, `teams`, `users`

Each level stores denormalized parent IDs for efficient querying.

**Implementation:** Phase 1
