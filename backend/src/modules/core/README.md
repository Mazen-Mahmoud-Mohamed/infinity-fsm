# Platform Core Modules

Stable foundation services. Always enabled for every company. Must remain module-agnostic — no imports from `business/` modules.

## Core Modules

| Module | Path | Phase | Description |
|--------|------|-------|-------------|
| Auth | `auth/` | 1 | JWT login, refresh, logout |
| RBAC | `rbac/` | 1 | Roles, permissions, authorization middleware |
| Organization | `organization/` | 1 | 6-level hierarchy + users |
| Settings | `settings/` | 1 | Company configuration, holidays |
| Sync | `sync/` | 3 | Offline batch sync, idempotency |
| Search | `search/` | 4 | Global cross-module search |
| Dashboard | `dashboard/` | 4 | KPI aggregation from all modules |
| Notifications | `notifications/` | 2 | Multi-channel notification framework |
| Audit | `audit/` | 1 | Immutable audit trail |
| Cloudinary | `cloudinary/` | 2 | Image upload signing, path convention |
| Maps | `maps/` | 2 | Geocoding abstraction (provider-swappable) |

## Module Interface

Core modules expose services consumed by business modules via dependency injection — never via direct model imports across module boundaries.
