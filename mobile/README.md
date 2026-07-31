# Mobile — Infinity FSM Platform

Flutter application for Android, iOS, and Windows Desktop.

## Feature Architecture

```
mobile/lib/
├── app/                        # Bootstrap, DI, routing, theme
├── core/                       # Infrastructure (network, storage, services)
├── features/
│   ├── core/                   # Platform features
│   │   ├── auth/
│   │   ├── dashboard/
│   │   ├── search/
│   │   ├── notifications/
│   │   ├── settings/
│   │   └── organization/       # Admin org management
│   └── business/               # Business module features
│       ├── overtime/           # MVP
│       ├── work_orders/        # SCHEMA_READY
│       └── vehicles/           # SCHEMA_READY
└── platform/                   # Platform-specific adapters
```

## Module Enablement

App reads `/platform/modules` on login to determine visible features. Disabled modules hidden from navigation.

## Key Documents

- [Architecture](../docs/ARCHITECTURE.md)
- [Testing](../docs/TESTING.md)
- [RBAC](../docs/RBAC.md)
