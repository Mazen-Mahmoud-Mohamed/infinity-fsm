# Backend — Infinity FSM Platform

Node.js + Express + MongoDB + Socket.IO.

## Status

Architecture v2.0 — production backend for Infinity FSM.

## Module Architecture

```
backend/src/modules/
├── core/                   # Platform core (always enabled)
│   ├── auth/
│   ├── rbac/
│   ├── organization/
│   ├── settings/
│   ├── sync/
│   ├── search/
│   ├── dashboard/
│   ├── notifications/
│   ├── audit/
│   ├── cloudinary/
│   └── maps/
└── business/               # Pluggable business modules
    ├── overtime/           # MVP — full implementation
    ├── work-orders/
    ├── inventory/
    ├── assets/
    ├── preventive-maintenance/
    ├── service-reports/
    └── ...
```

**Attendance** is not a backend module. Employee time presence is handled by the
external fingerprint / biometric attendance system; this API does not mount
`/attendance` routes or store clock-in/out records.

## Tech Stack

Node.js 20 LTS · Express 4 · MongoDB 7 · Mongoose 8 · Socket.IO 4 · Jest · Pino · Joi

## Key Documents

- [Architecture](../docs/ARCHITECTURE.md)
- [API Specification](../docs/API.md)
- [Database Schema](../docs/DATABASE.md)
- [RBAC](../docs/RBAC.md)
- [Testing](../docs/TESTING.md)
