# Module Registry

**Product:** Infinity FSM Platform  
**Version:** 2.0.0  

Official catalog of all platform modules — current and planned.

---

## Module Lifecycle States

| State | Code | Description |
|-------|------|-------------|
| Planned | `PLANNED` | Documented, no schema or code |
| Schema Ready | `SCHEMA_READY` | DB collections exist, APIs documented, folder scaffolded |
| In Development | `IN_DEV` | Active implementation |
| Beta | `BETA` | Feature-complete, limited rollout |
| General Availability | `GA` | Production-ready, fully supported |
| Deprecated | `DEPRECATED` | Maintained, no new features |

---

## Platform Core Modules

These modules form the stable foundation. They are always enabled.

| Module | State | MVP | Description |
|--------|-------|-----|-------------|
| **Identity & Access** | `IN_DEV` | ✅ | JWT auth, refresh tokens, login/logout |
| **RBAC** | `IN_DEV` | ✅ | Roles, permissions, scope enforcement |
| **Organization** | `IN_DEV` | ✅ | Company → Branch → Region → City → Dept → Team |
| **Configuration** | `IN_DEV` | ✅ | Company settings, holidays, policies |
| **Sync Engine** | `PLANNED` | ✅ | Offline queue, idempotency, batch sync |
| **Search** | `PLANNED` | ✅ | Global cross-module search |
| **Dashboard** | `PLANNED` | ✅ | Aggregated KPIs |
| **Notifications** | `PLANNED` | ✅ | In-app + Socket.IO (push future) |
| **Audit Log** | `IN_DEV` | ✅ | Immutable action trail |
| **File Storage** | `PLANNED` | ✅ | Cloudinary integration |
| **Maps** | `PLANNED` | ✅ | Geocoding abstraction |

---

## Business Modules

| Module | State | MVP Scope | Schema | API | UI |
|--------|-------|-----------|--------|-----|-----|
| **Overtime** | `IN_DEV` | Full implementation | ✅ | ✅ | ✅ |
| **Work Orders** | `SCHEMA_READY` | Optional link from overtime | ✅ | Documented | ❌ |
| **Vehicles** | `SCHEMA_READY` | Assignment tracking only | ✅ | Documented | ❌ |
| **Attendance** | `PLANNED` | — | ❌ | ❌ | ❌ |
| **Customers** | `PLANNED` | Via Work Orders schema | ✅ | ❌ | ❌ |
| **Assets** | `PLANNED` | — | ❌ | ❌ | ❌ |
| **Inventory** | `PLANNED` | — | ❌ | ❌ | ❌ |
| **Scheduling** | `PLANNED` | — | ❌ | ❌ | ❌ |
| **Maintenance** | `PLANNED` | — | ❌ | ❌ | ❌ |
| **Payroll Integration** | `PLANNED` | — | ❌ | ❌ | ❌ |
| **Analytics** | `PLANNED` | Dashboard KPIs only in MVP | ❌ | ❌ | Partial |

---

## Module Interface Contract

Every module registering with the platform must provide:

### Required Registrations

```javascript
// Example: Overtime module registration
{
  moduleId: 'overtime',
  version: '1.0.0',
  state: 'IN_DEV',

  // Routes mounted at /api/v1/overtime
  routes: './overtime.routes.js',

  // Permissions this module defines
  permissions: [
    'overtime:view_own', 'overtime:start', 'overtime:approve', ...
  ],

  // Audit actions this module produces
  auditActions: [
    'overtime.started', 'overtime.ended', 'overtime.approved', ...
  ],

  // Notification templates
  notificationTemplates: [
    { key: 'overtime.approved', channels: ['in_app'] }, ...
  ],

  // Searchable entity config
  searchEntities: [
    { collection: 'overtime_records', textFields: ['jobDescription'], filters: ['status', 'type'] }
  ],

  // Dashboard KPI providers
  dashboardKpis: [
    'running_overtime', 'pending_reviews', 'approved_today', ...
  ],

  // Report types
  reportTypes: [
    'daily', 'weekly', 'monthly', 'yearly', 'travel', 'rejected', 'pending'
  ],

  // Offline sync operation handlers
  syncOperations: [
    'START_OVERTIME', 'END_OVERTIME'
  ],

  // Socket events
  socketEvents: [
    'overtime:started', 'overtime:ended', 'overtime:approved', ...
  ]
}
```

---

## Module Dependency Map

```
                    ┌─────────────────┐
                    │  Platform Core   │
                    └────────┬────────┘
                             │
         ┌───────────────────┼───────────────────┐
         │                   │                   │
    ┌────▼────┐        ┌────▼────┐        ┌────▼────┐
    │Overtime │        │  Work   │        │Vehicle  │
    │ (MVP)   │◄──────│ Orders  │        │         │
    └────┬────┘ optional└────┬────┘        └────┬────┘
         │                   │                   │
         │              ┌────▼────┐              │
         │              │Customer │              │
         │              └─────────┘              │
         │                                       │
    ┌────▼───────────────────────────────────────▼────┐
    │              Reports & Dashboard                  │
    └──────────────────────────────────────────────────┘
         │
    ┌────▼────┐  ┌──────────┐  ┌───────────┐  ┌─────────┐
    │Attendance│  │Scheduling│  │Inventory  │  │Payroll  │
    │ (future) │  │ (future) │  │ (future)  │  │(future) │
    └─────────┘  └──────────┘  └───────────┘  └─────────┘
```

**Dependency rules:**
- Business modules depend on Platform Core — never the reverse.
- Business modules may reference each other via service interfaces — never direct model access.
- Overtime optionally links to Work Orders and Vehicles — loose coupling via IDs.

---

## Enabling/Disabling Modules

Companies enable modules via `companies.enabledModules[]`:

```javascript
{
  enabledModules: ['overtime', 'work_orders', 'vehicles']
}
```

- Disabled module routes return 404.
- Disabled module UI hidden on client.
- Schema exists regardless — data may be pre-populated for future activation.

---

## Adding a New Module (Process)

1. **Register** in this document with state `PLANNED`.
2. **Design** schema in DATABASE.md.
3. **Document** API endpoints in API.md.
4. **Scaffold** folder structure with README.
5. **Define** permissions in RBAC.md.
6. **Add** audit actions, notification templates, search config.
7. **Write** tests before implementation (TESTING.md).
8. **Implement** following module interface contract.
9. **Update** state to `BETA` → `GA`.

Estimated effort per module (after platform core exists): 2–4 weeks.
