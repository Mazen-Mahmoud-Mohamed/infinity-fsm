# Infinity FSM — Software Architecture Document

**Product:** Infinity Field Service Management Platform  
**Version:** 2.0.0  
**Status:** Architecture — Planning Phase  
**Last Updated:** 2026-07-29  
**Classification:** Enterprise Commercial Product  

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Platform Vision & Module Strategy](#2-platform-vision--module-strategy)
3. [System Context](#3-system-context)
4. [Architectural Principles](#4-architectural-principles)
5. [Platform Core vs Business Modules](#5-platform-core-vs-business-modules)
6. [High-Level Architecture](#6-high-level-architecture)
7. [Organization Hierarchy](#7-organization-hierarchy)
8. [Backend Architecture](#8-backend-architecture)
9. [Mobile Architecture (Flutter)](#9-mobile-architecture-flutter)
10. [Overtime Module (MVP)](#10-overtime-module-mvp)
11. [Work Orders Module (Schema-Ready)](#11-work-orders-module-schema-ready)
12. [Overtime Calculation Engine](#12-overtime-calculation-engine)
13. [Overtime Lifecycle State Machine](#13-overtime-lifecycle-state-machine)
14. [Travel Overtime Extensions](#14-travel-overtime-extensions)
15. [GPS & Device Capture Model](#15-gps--device-capture-model)
16. [Photo Storage Architecture](#16-photo-storage-architecture)
17. [Company Configuration Module](#17-company-configuration-module)
18. [Dashboard Architecture](#18-dashboard-architecture)
19. [Reporting Architecture](#19-reporting-architecture)
20. [Global Search Architecture](#20-global-search-architecture)
21. [Notification Architecture](#21-notification-architecture)
22. [RBAC & Authorization](#22-rbac--authorization)
23. [Offline-First Sync Architecture](#23-offline-first-sync-architecture)
24. [Audit Log Architecture](#24-audit-log-architecture)
25. [Security Architecture](#25-security-architecture)
26. [Integration Architecture](#26-integration-architecture)
27. [Testing Architecture](#27-testing-architecture)
28. [Deployment & Operations](#28-deployment--operations)
29. [Architectural Decision Records](#29-architectural-decision-records)
30. [Related Documents](#30-related-documents)

---

## 1. Executive Summary

**Infinity FSM** is an enterprise Field Service Management platform designed for multi-year scalability. Overtime Tracking is the **first business module** shipped in MVP, but the platform core is built to support Attendance, Work Orders, Customers, Assets, Inventory, Vehicles, Scheduling, Maintenance, Payroll Integration, and Analytics — without restructuring the foundation.

### Product Positioning

| Dimension | Decision |
|-----------|----------|
| **Product type** | Commercial enterprise SaaS-ready platform |
| **MVP module** | Overtime Tracking |
| **Platform strategy** | Stable core + pluggable business modules |
| **Client platforms** | Android, iOS, Windows Desktop (Flutter) |
| **Backend** | Node.js + Express + MongoDB + Socket.IO |
| **Architecture style** | Modular Monolith → Microservices-ready |
| **Authorization** | Full RBAC (roles + granular permissions) |
| **Data authority** | Server-side for all business calculations |
| **Offline** | Offline-first for field technicians |
| **Image storage** | Cloudinary (URLs only in MongoDB) |
| **Maps** | Configurable provider (Google Maps default) |

### Repository Layout (Monorepo)

```
infinity-fsm/
├── backend/              # Node.js API + Socket.IO
├── mobile/               # Flutter (Android, iOS, Windows)
├── docs/                 # Architecture & specifications
├── infra/                # Docker, CI/CD, monitoring
├── scripts/              # Seed, migration, ops utilities
└── tests/                # Cross-cutting E2E & load test assets
    ├── e2e/
    ├── load/
    └── security/
```

---

## 2. Platform Vision & Module Strategy

### 2.1 Module Registry

The platform maintains a formal **Module Registry** — every business capability is a registered module with a lifecycle state. See [MODULE_REGISTRY.md](./MODULE_REGISTRY.md).

```
┌─────────────────────────────────────────────────────────────────────┐
│                     INFINITY FSM PLATFORM CORE                       │
│  (Never changes structurally — only extends via configuration)       │
├─────────────────────────────────────────────────────────────────────┤
│  Auth & RBAC │ Organization │ Settings │ Audit │ Notifications      │
│  Sync Engine │ Search │ Dashboard │ File Storage │ Maps │ Versioning │
└───────────────────────────────┬─────────────────────────────────────┘
                                │ Module Interface (events, permissions, routes)
        ┌───────────────────────┼───────────────────────┐
        │           │           │           │           │
   ┌────▼────┐ ┌───▼────┐ ┌───▼────┐ ┌───▼────┐ ┌───▼────┐
   │Overtime │ │Work    │ │Attend- │ │Custom- │ │Vehicle │
   │ (MVP)   │ │Orders  │ │ance    │ │ers     │ │        │
   └─────────┘ └────────┘ └────────┘ └────────┘ └────────┘
        ... more modules added over years without core changes ...
```

### 2.2 Module Interface Contract

Every business module must implement:

| Contract Element | Purpose |
|------------------|---------|
| **Routes namespace** | `/api/v1/{module}/...` |
| **Permission declarations** | Register permissions in `permissions` collection |
| **Audit event types** | Register auditable actions |
| **Notification templates** | Register notification types |
| **Search index fields** | Register searchable entities |
| **Dashboard widgets** | Register KPI contributions |
| **Report definitions** | Register report types and dimensions |
| **Offline sync operation types** | Register queue operation handlers |
| **Socket event catalog** | Register real-time events |

Modules **must not** directly access another module's Mongoose models. Cross-module communication goes through **service interfaces** or **domain events**.

### 2.3 Module Lifecycle States

| State | Meaning |
|-------|---------|
| `PLANNED` | Documented, schema reserved, no code |
| `SCHEMA_READY` | Database collections exist, APIs stubbed |
| `BETA` | Feature-complete, limited rollout |
| `GA` | General availability |
| `DEPRECATED` | Maintained, no new features |

| Module | Current State | MVP Scope |
|--------|---------------|-----------|
| Overtime | `BETA` → GA in MVP | Full implementation |
| Work Orders | `SCHEMA_READY` | Optional link from overtime |
| Organization | `BETA` | Full hierarchy |
| Vehicles | `SCHEMA_READY` | Schema + assignment only |
| Attendance | `PLANNED` | — |
| Customers | `PLANNED` | Via Work Orders schema |
| Assets | `PLANNED` | — |
| Inventory | `PLANNED` | — |
| Scheduling | `PLANNED` | — |
| Maintenance | `PLANNED` | — |
| Payroll | `PLANNED` | — |
| Analytics | `PLANNED` | Dashboard KPIs in MVP |

---

## 3. System Context

### 3.1 Actor Model

```
┌──────────────────────────────────────────────────────────────────────────┐
│                        Infinity FSM Ecosystem                             │
├──────────────────────────────────────────────────────────────────────────┤
│                                                                           │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐  ┌────────────┐         │
│  │ Technician │  │ Supervisor │  │   Admin    │  │  HR (future)│         │
│  │  Flutter   │  │  Flutter   │  │  Flutter   │  │  Web future │         │
│  └─────┬──────┘  └─────┬──────┘  └─────┬──────┘  └─────┬──────┘         │
│        └───────────────┼───────────────┼───────────────┘                  │
│                        │               │                                   │
│                 ┌──────▼───────────────▼──────┐                           │
│                 │   Infinity FSM Backend       │                           │
│                 │   REST API + Socket.IO         │                           │
│                 │   RBAC │ Sync │ Search        │                           │
│                 └──────┬───────────────────────┘                           │
│        ┌───────────────┼───────────────┬──────────────┐                   │
│        │               │               │              │                   │
│  ┌─────▼─────┐  ┌─────▼─────┐  ┌─────▼─────┐  ┌────▼────┐                 │
│  │  MongoDB  │  │Cloudinary │  │Google Maps│  │  FCM    │                 │
│  │  Atlas    │  │           │  │(configurable)│(future)│                 │
│  └───────────┘  └───────────┘  └───────────┘  └─────────┘                 │
│                                                                           │
└──────────────────────────────────────────────────────────────────────────┘
```

### 3.2 Tenant Isolation

Every request is scoped to `companyId` extracted from JWT. Cross-tenant access is architecturally impossible — enforced at repository layer, not just controller layer.

---

## 4. Architectural Principles

1. **Platform first, modules second** — Core services are module-agnostic. Business logic lives in modules.
2. **Server is the source of truth** — Calculations, state transitions, authorization on server.
3. **Permission-based, not role-only** — Roles are permission bundles; authorization checks permissions.
4. **Schema ahead of features** — Future modules have collections designed now; APIs come later.
5. **Offline-first for field users** — Technicians never lose data due to connectivity.
6. **Idempotent everything** — All mutations accept idempotency keys.
7. **Immutable audit** — Audit records are append-only; no UPDATE or DELETE ever.
8. **Denormalize for reads, normalize for writes** — Hierarchy IDs denormalized on records for fast filtering.
9. **Test from day one** — Testing architecture is not deferred; see [TESTING.md](./TESTING.md).
10. **Version everything** — API versioning, calculation versioning, schema migration versioning.

---

## 5. Platform Core vs Business Modules

### 5.1 Platform Core (Stable Foundation)

| Core Service | Responsibility | Module-Agnostic |
|--------------|----------------|-----------------|
| **Identity & Access** | JWT, refresh tokens, RBAC enforcement | ✅ |
| **Organization** | Company → Branch → Region → City → Dept → Team | ✅ |
| **Configuration** | Company settings, holidays, policies | ✅ |
| **Sync Engine** | Offline queue processing, idempotency | ✅ |
| **Search** | Global cross-module search | ✅ |
| **Dashboard** | Aggregated KPIs from all modules | ✅ |
| **Notifications** | Multi-channel delivery framework | ✅ |
| **Audit** | Immutable action logging | ✅ |
| **File Storage** | Cloudinary signing, folder conventions | ✅ |
| **Maps** | Geocoding abstraction (provider-swappable) | ✅ |

### 5.2 Business Modules (Pluggable)

Each module owns: routes, controllers, services, repositories, models, validators, domain logic, tests, permissions, audit events, search fields.

```
backend/src/modules/
├── core/                    # Platform core services
│   ├── auth/
│   ├── organization/
│   ├── settings/
│   ├── sync/
│   ├── search/
│   ├── dashboard/
│   ├── notifications/
│   ├── audit/
│   ├── cloudinary/
│   └── maps/
└── business/                # Pluggable business modules
    ├── overtime/            # MVP — full implementation
    ├── work-orders/         # SCHEMA_READY — optional MVP link
    ├── vehicles/            # SCHEMA_READY — assignment tracking
    ├── attendance/          # PLANNED
    ├── customers/           # PLANNED
    ├── assets/              # PLANNED
    ├── inventory/           # PLANNED
    ├── scheduling/          # PLANNED
    ├── maintenance/         # PLANNED
    ├── payroll/             # PLANNED
    └── analytics/           # PLANNED
```

---

## 6. High-Level Architecture

### 6.1 Layered Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                            │
│  REST Routes │ Controllers │ Socket Handlers │ Middleware        │
├─────────────────────────────────────────────────────────────────┤
│                    APPLICATION LAYER                               │
│  Use Cases │ DTOs │ Validators │ Event Publishers │ Orchestrators│
├─────────────────────────────────────────────────────────────────┤
│                      DOMAIN LAYER                                │
│  Entities │ Value Objects │ Domain Services │ State Machines     │
│  Policies │ Domain Events                                        │
├─────────────────────────────────────────────────────────────────┤
│                   INFRASTRUCTURE LAYER                           │
│  Repositories │ Mongoose │ Cloudinary │ Maps │ FCM │ Redis      │
└─────────────────────────────────────────────────────────────────┘
```

### 6.2 Cross-Cutting Request Pipeline

```
Request
  │
  ▼
┌──────────────┐   ┌──────────────┐   ┌──────────────┐   ┌──────────────┐
│ Rate Limiter │──▶│ JWT Auth     │──▶│ Tenant Scope │──▶│ RBAC Guard   │
└──────────────┘   └──────────────┘   └──────────────┘   └──────┬───────┘
                                                               │
  ┌────────────────────────────────────────────────────────────┘
  ▼
┌──────────────┐   ┌──────────────┐   ┌──────────────┐   ┌──────────────┐
│ Validation   │──▶│ Idempotency  │──▶│ Controller   │──▶│ Service      │
└──────────────┘   └──────────────┘   └──────────────┘   └──────┬───────┘
                                                                │
  ┌─────────────────────────────────────────────────────────────┘
  ▼
┌──────────────┐   ┌──────────────┐   ┌──────────────┐   ┌──────────────┐
│ Repository   │──▶│ Domain Logic │──▶│ Audit Log    │──▶│ Response DTO │
└──────────────┘   └──────────────┘   └──────────────┘   └──────────────┘
```

---

## 7. Organization Hierarchy

### 7.1 Hierarchy Model

```
Company
 └── Branch
      └── Region
           └── City
                └── Department
                     └── Team
                          └── Employee (User)
```

### 7.2 Design Rules

| Rule | Rationale |
|------|-----------|
| Every org unit belongs to exactly one parent (except Company) | Clear ownership chain |
| Users store full hierarchy path as denormalized IDs | O(1) filter queries without joins |
| Soft-delete only | Preserve historical report integrity |
| Hierarchy changes do not retroactively alter closed records | Records snapshot hierarchy at creation time |
| Reports filter at any hierarchy level | Business requirement |

### 7.3 Denormalized Hierarchy Snapshot

Every business record (overtime, work order, etc.) stores:

```javascript
organizationSnapshot: {
  companyId, branchId, regionId, cityId,
  departmentId, teamId
}
```

This snapshot is captured at record creation and never updated, ensuring historical reports remain accurate even if employee transfers departments.

See [DATABASE.md](./DATABASE.md) for collection schemas.

---

## 8. Backend Architecture

### 8.1 Directory Structure

```
backend/src/
├── app.js
├── server.js
├── config/
├── shared/
│   ├── middleware/         # auth, rbac, idempotency, tenant, validation
│   ├── errors/
│   ├── events/             # Domain event bus (in-process, future message queue)
│   ├── utils/
│   └── constants/
├── modules/
│   ├── core/               # Platform core (see Section 5.2)
│   └── business/           # Business modules (see Section 5.2)
└── __tests__/              # Integration test suites
```

Each module follows identical internal structure — see module README files.

---

## 9. Mobile Architecture (Flutter)

### 9.1 Feature-Based Clean Architecture

```
mobile/lib/
├── app/                    # Bootstrap, DI, routing, theme
├── core/                   # Platform-agnostic infrastructure
├── features/
│   ├── core/               # Platform feature UIs (dashboard, search, settings)
│   └── business/           # Business module UIs
│       ├── overtime/       # MVP
│       ├── work_orders/    # SCHEMA_READY
│       └── ...
└── platform/               # Platform-specific adapters
```

### 9.2 Module Enablement

Mobile reads `/api/v1/platform/modules` to determine which UI modules to render. Disabled modules are hidden, not compiled out — allowing runtime feature flags per company.

---

## 10. Overtime Module (MVP)

### 10.1 Scope

Full implementation in MVP. Optional link to Work Order (`workOrderId` nullable).

### 10.2 Overtime Types

| Type | Enum | Description |
|------|------|-------------|
| Regular | `REGULAR` | Standard after-hours field work |
| Travel | `TRAVEL` | Missions outside city/governorate — extended metadata |

---

## 11. Work Orders Module (Schema-Ready)

Work Orders are **not implemented in MVP** but the database, permissions, and module folder exist.

### 11.1 Work Order Entity (Future)

| Field | Type | Description |
|-------|------|-------------|
| `jobNumber` | String | Unique per company |
| `jobTitle` | String | |
| `customerId` | ObjectId | FK → customers (future) |
| `customerAddress` | Object | Denormalized address |
| `assignedTechnicianId` | ObjectId | FK → users |
| `supervisorId` | ObjectId | FK → users |
| `priority` | Enum | `LOW`, `MEDIUM`, `HIGH`, `CRITICAL` |
| `status` | Enum | `DRAFT`, `ASSIGNED`, `IN_PROGRESS`, `ON_HOLD`, `COMPLETED`, `CANCELLED` |
| `description` | String | |
| `notes` | String | |
| `attachments` | [Object] | Cloudinary URLs |
| `location` | GeoPoint | GPS |
| `estimatedDurationMinutes` | Number | |
| `actualDurationMinutes` | Number | Calculated on completion |
| `createdAt` | Date | |
| `completedAt` | Date | |

### 11.2 Overtime ↔ Work Order Link

```javascript
// In overtime_records
workOrderId: { type: ObjectId, ref: 'WorkOrder', required: false }
```

Technician can optionally select an assigned Work Order when starting overtime. If linked, job description can pre-fill from work order.

---

## 12. Overtime Calculation Engine

Unchanged in logic from v1.0 — server-side only.

| Parameter | Default |
|-----------|---------|
| Official start | 09:00 |
| Official end | 17:00 |
| Timezone | Company-configurable |
| Excluded | Official working hours + holidays (from settings) |

Output fields: `rawDurationMinutes`, `excludedMinutes`, `overtimeMinutes`, `calculationVersion`.

All examples from business requirements remain valid. Multi-day and holiday exclusion documented in domain README.

---

## 13. Overtime Lifecycle State Machine

### 13.1 States

| State | Enum | Description |
|-------|------|-------------|
| Draft | `DRAFT` | Saved locally, not yet submitted to server |
| Running | `RUNNING` | Active overtime session in progress |
| Pending Review | `PENDING_REVIEW` | Ended, awaiting supervisor decision |
| Approved | `APPROVED` | Accepted by supervisor/admin |
| Rejected | `REJECTED` | Declined with mandatory reason |
| Archived | `ARCHIVED` | Closed record, removed from active views |

> **Migration from v1.0:** `ACTIVE` → `RUNNING`, no `DRAFT` or `ARCHIVED` previously.

### 13.2 State Transition Matrix

```
                    ┌─────────────────────────────────────────────────────┐
                    │                  STATE TRANSITIONS                   │
                    └─────────────────────────────────────────────────────┘

  ┌───────┐  start   ┌─────────┐   end    ┌────────────────┐
  │ DRAFT │─────────▶│ RUNNING │─────────▶│ PENDING_REVIEW │
  └───────┘          └────┬────┘          └───┬────────┬───┘
       ▲                  │                    │        │
       │                  │ cancel             │        │
       │                  ▼                    │        │
       │             ┌─────────┐               │        │
       └─────────────│ DRAFT   │               │        │
         (discard)   └─────────┘               │        │
                                               │        │
                              approve          │ reject │
                                  ▼            │        ▼
                           ┌──────────┐        │   ┌──────────┐
                           │ APPROVED │        │   │ REJECTED │
                           └────┬─────┘        │   └────┬─────┘
                                │              │        │
                                │  archive       │  archive
                                ▼              │        ▼
                           ┌──────────┐◀───────┴──▶┌──────────┐
                           │ ARCHIVED │            │ ARCHIVED │
                           └──────────┘            └──────────┘
```

### 13.3 Transition Permissions

| Transition | Actor | Permission Required | Conditions |
|------------|-------|---------------------|------------|
| → `DRAFT` | Technician | `overtime:create` | Offline save |
| `DRAFT` → `RUNNING` | Technician | `overtime:start` | Valid start data, no other RUNNING session |
| → `RUNNING` (direct) | Technician | `overtime:start` | Online start (skips DRAFT) |
| `RUNNING` → `PENDING_REVIEW` | Technician | `overtime:end` | Valid end photo + location |
| `RUNNING` → `DRAFT` | Technician | `overtime:cancel` | Cancel before end |
| `PENDING_REVIEW` → `APPROVED` | Supervisor/Admin | `overtime:approve` | Within scope (dept/branch) |
| `PENDING_REVIEW` → `REJECTED` | Supervisor/Admin | `overtime:reject` | Reason min 10 chars |
| `APPROVED` → `ARCHIVED` | Admin | `overtime:archive` | Auto after configurable period OR manual |
| `REJECTED` → `ARCHIVED` | Admin | `overtime:archive` | Auto after configurable period OR manual |
| Any → Any | — | — | **Forbidden** — no other transitions |

### 13.4 Enforcement

- State transitions validated in domain service — not in controller.
- Invalid transition throws `InvalidStateTransitionError` (422).
- Every transition logged to audit with `{ from, to, actor, reason }`.

---

## 14. Travel Overtime Extensions

When `type = TRAVEL`, additional fields are required:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `governorate` | String | ✅ | Destination governorate |
| `destination` | String | ✅ | Destination address/name |
| `travelReason` | String | ✅ | Purpose of travel |
| `travelDistanceKm` | Number | ✅ | Distance in kilometers |
| `estimatedTravelMinutes` | Number | ✅ | Pre-trip estimate |
| `actualTravelMinutes` | Number | ❌ | Set on end (optional) |
| `reimbursementAmount` | Number | ❌ | Future — calculated from company travel rules |
| `reimbursementCurrency` | String | ❌ | Future — ISO 4217 |
| `reimbursementStatus` | Enum | ❌ | Future — `PENDING`, `APPROVED`, `PAID` |

Travel rules configured in Settings module (rate per km, max reimbursement, etc.).

---

## 15. GPS & Device Capture Model

### 15.1 GPS Point Schema (Extended)

Every GPS capture (start, end, or future tracking points) stores:

```javascript
{
  latitude:     { type: Number, required: true },
  longitude:    { type: Number, required: true },
  accuracy:     { type: Number, required: true },   // meters
  altitude:     { type: Number, required: false },  // meters above sea level
  heading:      { type: Number, required: false },  // degrees 0-360
  speed:        { type: Number, required: false },  // m/s
  timestamp:    { type: Date, required: true },    // device capture time
  provider:     { type: String, required: true },   // 'gps', 'network', 'fused'
  address:      { type: String, required: false }  // reverse-geocoded server-side
}
```

Start GPS and End GPS are stored as independent embedded documents on the overtime record.

### 15.2 GPS Validation Rules

| Rule | Action |
|------|--------|
| Accuracy > configured limit (default 100m) | Flag record `gpsQuality: 'LOW'` for review |
| Missing altitude/heading/speed | Accepted — not all devices provide |
| Zero coordinates (0,0) | Reject — `INVALID_GPS` |
| Timestamp > 5 min drift from server | Log warning, use server time as authoritative |

### 15.3 Device Metadata Schema

Captured at start and end independently:

```javascript
{
  platform:         { type: String, required: true },  // 'android', 'ios', 'windows'
  manufacturer:     { type: String, required: true },  // 'Samsung', 'Apple', 'Dell'
  phoneModel:       { type: String, required: true },  // 'Galaxy S24', 'iPhone 15'
  osVersion:        { type: String, required: true },  // '14', '17.5', '10.0.26200'
  appVersion:       { type: String, required: true },  // '1.2.3'
  deviceIdentifier: { type: String, required: true }   // Unique device ID (not IMEI)
}
```

---

## 16. Photo Storage Architecture

### 16.1 Cloudinary Folder Convention

```
{company_id}/{employee_id}/{year}/{month}/{record_id}/{photo_type}.jpg
```

**Example:**
```
6888a1b2c3d4e5f6a7b8c000/6888a1b2c3d4e5f6a7b8c001/2026/07/6888a1b2c3d4e5f6a7b8c9d0/start.jpg
6888a1b2c3d4e5f6a7b8c000/6888a1b2c3d4e5f6a7b8c001/2026/07/6888a1b2c3d4e5f6a7b8c9d0/end.jpg
```

### 16.2 Naming Rules

| Rule | Detail |
|------|--------|
| `photo_type` | `start`, `end`, or `{index}` for attachments |
| Format | JPEG (.jpg) — converted server-side if needed |
| Max size | Configurable (default 5 MB) |
| Quality | Configurable (default 80%) |
| Public ID | Full path above; no random suffix |
| Versioning | Overwrites not allowed — new record_id for retakes |
| MongoDB storage | Only `secure_url` and `public_id` stored |

### 16.3 Upload Flow

1. Client requests signed upload params specifying target folder path.
2. Backend validates user permissions and constructs path.
3. Client uploads directly to Cloudinary.
4. Client submits overtime with `photoUrl` + `publicId`.
5. Backend verifies URL matches expected path pattern.

---

## 17. Company Configuration Module

Settings is expanded to a full **Company Configuration** system. See [DATABASE.md](./DATABASE.md) `company_settings` collection.

### 17.1 Configuration Categories

| Category | Keys (examples) |
|----------|-----------------|
| **Company Profile** | name, logo, slug |
| **Working Hours** | start, end, timezone |
| **Overtime Policy** | allowed types, max session hours, GPS accuracy limit |
| **Travel Rules** | rate per km, max reimbursement, required fields |
| **Media** | camera quality, max image size |
| **Offline** | retention days, max queue size, retry interval |
| **Notifications** | channels enabled, templates, quiet hours |
| **Holidays** | holiday calendar (array of dates) |
| **Maps** | provider (`google`, `mapbox`), API key reference |
| **Cloudinary** | folder prefix, transformation presets |
| **Archive Policy** | auto-archive after N days |
| **Modules** | enabled modules per company |

All changes audit-logged. Settings cached in Redis (future) with TTL.

---

## 18. Dashboard Architecture

Dashboard is a **core platform service** that aggregates KPIs from all enabled modules.

### 18.1 KPI Catalog (MVP)

| KPI | Source Module | Scope |
|-----|---------------|-------|
| Running Overtime | Overtime | Company/Branch/Dept |
| Pending Reviews | Overtime | Company/Branch/Dept |
| Approved Today | Overtime | Company/Branch/Dept |
| Rejected Today | Overtime | Company/Branch/Dept |
| Today's Overtime Hours | Overtime | Company/Branch/Dept |
| Monthly Overtime Hours | Overtime | Company/Branch/Dept |
| Travel Hours (monthly) | Overtime | Company/Branch/Dept |
| Regular Hours (monthly) | Overtime | Company/Branch/Dept |
| Online Technicians | Platform | Company |
| Offline Technicians | Platform | Company |
| Active Users | Platform | Company |
| Companies / Branches / Departments | Organization | Platform Admin |

### 18.2 Dashboard API

`GET /api/v1/dashboard` — returns KPI object filtered by user's scope and requested hierarchy level.

Each module registers KPI providers via the module interface. Dashboard service calls all registered providers in parallel.

---

## 19. Reporting Architecture

### 19.1 Report Dimensions

| Dimension | Filter Parameter |
|-----------|-----------------|
| Employee | `userId` |
| Team | `teamId` |
| Department | `departmentId` |
| City | `cityId` |
| Region | `regionId` |
| Branch | `branchId` |
| Company | `companyId` |
| Vehicle | `vehicleId` (future) |

### 19.2 Report Types

| Report | Period | Module |
|--------|--------|--------|
| Daily | Single day | Overtime |
| Weekly | ISO week | Overtime |
| Monthly | Calendar month | Overtime |
| Yearly | Calendar year | Overtime |
| Travel | Any period | Overtime (type=TRAVEL) |
| Rejected | Any period | Overtime (status=REJECTED) |
| Pending | Any period | Overtime (status=PENDING_REVIEW) |
| Employee | Any period | Cross-module |
| Department | Any period | Cross-module |
| Branch | Any period | Cross-module |
| Region | Any period | Cross-module |
| Company | Any period | Cross-module |
| Vehicle | Any period | Overtime + Vehicles (future) |

### 19.3 Export Formats

| Format | MVP | Library |
|--------|-----|---------|
| JSON | ✅ | Native |
| CSV | ✅ | `csv-stringify` |
| Excel (XLSX) | Phase 4 | `exceljs` |
| PDF | Phase 5 | `pdfkit` or Puppeteer |

Reports use MongoDB aggregation pipelines with pre-computed indexes. Large reports run async with job queue (future).

---

## 20. Global Search Architecture

### 20.1 Searchable Entities (MVP + Planned)

| Entity | Module | MVP |
|--------|--------|-----|
| Employee | Organization | ✅ |
| Department / Branch / Region | Organization | ✅ |
| Overtime Record | Overtime | ✅ |
| Work Order | Work Orders | Schema only |
| Vehicle | Vehicles | Schema only |

### 20.2 Search Filters

Combined query supports: `q` (text), `employeeId`, `departmentId`, `branchId`, `vehicleId`, `workOrderId`, `jobNumber`, `dateFrom`, `dateTo`, `status`, `type` (including TRAVEL).

### 20.3 Implementation Strategy

**Phase 1 (MVP):** MongoDB text indexes + compound filters on each collection.  
**Phase 2:** MongoDB Atlas Search or Elasticsearch for fuzzy matching and relevance scoring.

Search service queries all registered module search providers in parallel, merges and ranks results.

---

## 21. Notification Architecture

### 21.1 Delivery Channels

| Channel | MVP | Phase |
|---------|-----|-------|
| In-App | ✅ | MVP |
| Socket.IO (real-time) | ✅ | MVP |
| Push (FCM/APNs) | ❌ | Phase 5 |
| Email | ❌ | Phase 6 |
| SMS | ❌ | Future |

### 21.2 Notification Framework

```
Event (e.g., overtime.approved)
     │
     ▼
┌─────────────────┐
│ Notification    │
│ Service         │
└────────┬────────┘
         │
    ┌────┼────┬────────┐
    ▼    ▼    ▼        ▼
 In-App Push Email   SMS
         (future channels)
```

### 21.3 Templates

Stored in `notification_templates` collection:

```javascript
{
  key: 'overtime.approved',
  channels: ['in_app', 'push'],
  title: '{{employeeName}} — Overtime Approved',
  body: 'Your {{hours}}h overtime on {{date}} has been approved.',
  variables: ['employeeName', 'hours', 'date']
}
```

### 21.4 History

All sent notifications stored in `notifications` collection with delivery status per channel.

---

## 22. RBAC & Authorization

Full RBAC replaces simple role checks. See [RBAC.md](./RBAC.md) for complete permission matrix.

### 22.1 Model

```
User → has → Role(s) → grants → Permission(s)
User → may have → direct Permission overrides (grant/deny)
```

### 22.2 Authorization Flow

```javascript
// Middleware pseudocode
const hasPermission = await rbacService.check(userId, 'overtime:approve', {
  scope: { departmentId: record.departmentId }
});
if (!hasPermission) throw ForbiddenError();
```

### 22.3 Scope Rules

Supervisors are scoped to their branch/department. Admins are scoped to company. Platform admins (future SaaS) scoped globally.

---

## 23. Offline-First Sync Architecture

Enhanced from v1.0. See dedicated section in [TESTING.md](./TESTING.md) for sync test requirements.

### 23.1 Capabilities

| Capability | Description |
|------------|-------------|
| **Queued Requests** | All mutations saved to SQLite queue |
| **Queued Photos** | Photos stored locally; uploaded before API call |
| **Background Sync** | workmanager (mobile), scheduler (Windows) |
| **Automatic Retry** | Exponential backoff: 5s, 30s, 2m, 10m, 1h |
| **Conflict Resolution** | Server wins on state; client retries with merge |
| **Idempotent Requests** | UUID idempotency key per operation |
| **Crash Recovery** | Hive persists active RUNNING session |
| **Session Recovery** | On launch: restore RUNNING state from local + server sync |

### 23.2 Sync Queue Priority

```
1. UPLOAD_PHOTO (start)
2. START_OVERTIME
3. UPLOAD_PHOTO (end)
4. END_OVERTIME
5. Other operations
```

### 23.3 Offline Retention

Configurable via settings (`offline.retention_days`, default 30). Queued items older than retention are flagged for manual review, not silently deleted.

---

## 24. Audit Log Architecture

### 24.1 Principles

- **Append-only** — MongoDB collection with no update/delete methods exposed.
- **Tamper-evident** — Each entry includes hash of previous entry (future blockchain-style chain).
- **Complete** — Every state change, login, settings change, and permission change logged.

### 24.2 Audited Actions (MVP)

| Action | Module |
|--------|--------|
| `auth.login` | Auth |
| `auth.logout` | Auth |
| `auth.login_failed` | Auth |
| `overtime.started` | Overtime |
| `overtime.ended` | Overtime |
| `overtime.approved` | Overtime |
| `overtime.rejected` | Overtime |
| `overtime.archived` | Overtime |
| `user.created` | Organization |
| `user.updated` | Organization |
| `user.deactivated` | Organization |
| `settings.updated` | Settings |
| `role.assigned` | RBAC |
| `permission.granted` | RBAC |

---

## 25. Security Architecture

See [NFR.md](./NFR.md) for complete security requirements.

Key controls: JWT + refresh rotation, bcrypt passwords, RBAC on every endpoint, rate limiting, CORS whitelist, Helmet headers, input sanitization, Cloudinary path validation, tenant isolation at repository layer, no secrets in client code.

---

## 26. Integration Architecture

| Integration | Purpose | Swappable |
|-------------|---------|-----------|
| Cloudinary | Image storage | Yes (S3 adapter future) |
| Google Maps | Geocoding + display | Yes (Mapbox adapter) |
| FCM/APNs | Push notifications | Yes |
| SendGrid/SES | Email | Yes |
| Twilio | SMS | Yes |
| Redis | Socket.IO adapter, cache | Optional |
| Elasticsearch | Global search | Phase 2 |

All integrations accessed through **adapter interfaces** in infrastructure layer.

---

## 27. Testing Architecture

Testing is **not deferred**. Full strategy documented in [TESTING.md](./TESTING.md).

Summary:
- Unit tests: domain logic, calculators, validators (80%+ coverage target)
- Integration tests: API endpoints, repository queries
- Flutter widget tests: critical screens
- E2E tests: full overtime lifecycle per platform
- Load tests: 500+ concurrent users
- Security tests: OWASP top 10, JWT tampering, RBAC bypass attempts
- GPS validation tests: accuracy thresholds, invalid coordinates
- Offline sync tests: airplane mode, crash recovery, idempotency
- Overtime calculation tests: all business rule examples + edge cases

CI pipeline fails on coverage drop below threshold.

---

## 28. Deployment & Operations

See [NFR.md](./NFR.md) for performance targets, backup, DR, monitoring, and versioning strategy.

---

## 29. Architectural Decision Records

### ADR-001: Platform Core + Business Modules
**Status:** Accepted  
**Decision:** Separate stable platform core from pluggable business modules.  
**Consequence:** Module interface contract required; slightly more upfront design.

### ADR-002: Modular Monolith
**Status:** Accepted  
**Decision:** Single deployable with strict module boundaries.  
**Consequence:** Simpler ops now; extractable later.

### ADR-003: Full RBAC over Simple Roles
**Status:** Accepted  
**Decision:** Permission-based authorization with role bundles.  
**Consequence:** More complex auth middleware; unlimited role flexibility.

### ADR-004: Organization Hierarchy with Snapshot
**Status:** Accepted  
**Decision:** 6-level hierarchy with denormalized snapshot on records.  
**Consequence:** Slightly larger documents; fast filtered queries.

### ADR-005: Schema-Ready Future Modules
**Status:** Accepted  
**Decision:** Work Orders, Vehicles collections exist before feature implementation.  
**Consequence:** Larger initial schema design; zero migration pain later.

### ADR-006: Extended GPS & Device Metadata
**Status:** Accepted  
**Decision:** Capture full GPS + device info at start and end.  
**Consequence:** Larger documents; invaluable for debugging and disputes.

### ADR-007: Overtime State Machine with DRAFT and ARCHIVED
**Status:** Accepted  
**Decision:** Six states with strict transition rules.  
**Consequence:** Offline DRAFT support; clean archival for reporting.

### ADR-008: Cloudinary Hierarchical Folder Structure
**Status:** Accepted  
**Decision:** `{company}/{employee}/{year}/{month}/{record}/{type}.jpg`  
**Consequence:** Predictable URLs; easy per-company retention policies.

### ADR-009: Server-Only Overtime Calculation
**Status:** Accepted (carried from v1.0)  
**Decision:** All business calculations on server.  
**Consequence:** Offline end saves locally; calculated on sync.

### ADR-010: Testing from Day One
**Status:** Accepted  
**Decision:** Testing architecture designed now; CI enforces coverage.  
**Consequence:** Slower initial velocity; stable long-term velocity.

### ADR-011: MongoDB Text Search → Elasticsearch Migration Path
**Status:** Accepted  
**Decision:** Start with MongoDB indexes; migrate to Atlas Search/ES when needed.  
**Consequence:** Good enough for MVP; clear upgrade path.

### ADR-012: Notification Channel Abstraction
**Status:** Accepted  
**Decision:** Template-based multi-channel notification framework.  
**Consequence:** In-app only in MVP; channels added without refactoring.

---

## 30. Related Documents

| Document | Description |
|----------|-------------|
| [DATABASE.md](./DATABASE.md) | Complete MongoDB schema |
| [API.md](./API.md) | REST API specification |
| [SOCKET_EVENTS.md](./SOCKET_EVENTS.md) | Real-time events |
| [RBAC.md](./RBAC.md) | Roles & permissions matrix |
| [TESTING.md](./TESTING.md) | Testing strategy |
| [NFR.md](./NFR.md) | Non-functional requirements |
| [MODULE_REGISTRY.md](./MODULE_REGISTRY.md) | Module catalog & lifecycle |
| [ROADMAP.md](./ROADMAP.md) | Development phases |
| [FUTURE_IMPROVEMENTS.md](./FUTURE_IMPROVEMENTS.md) | Post-MVP enhancements |
