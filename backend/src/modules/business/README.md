# Business Modules

Pluggable domain modules. Enabled per company via `companies.enabledModules[]`.

## Module Status

| Module | State | MVP | Folder |
|--------|-------|-----|--------|
| **Overtime** | IN_DEV | Full | `overtime/` |
| **Work Orders** | SCHEMA_READY | Optional link | `work-orders/` |
| **Vehicles** | SCHEMA_READY | Assignment only | `vehicles/` |
| **Attendance** | PLANNED | — | `attendance/` |
| **Customers** | PLANNED | — | `customers/` |

## Rules

1. Business modules depend on core — never the reverse.
2. Cross-module communication via service interfaces or domain events.
3. Each module registers with the Module Registry (permissions, audit, search, dashboard, sync, socket).
4. Disabled modules: routes return 404, UI hidden.

See [MODULE_REGISTRY.md](../../../../docs/MODULE_REGISTRY.md).
