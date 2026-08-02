# REST API Specification

**Product:** Infinity FSM Platform  
**Version:** 2.0.0  
**Base URL:** `/api/v1`  
**Authentication:** Bearer JWT  
**Content-Type:** `application/json`  

---

## Table of Contents

1. [Conventions](#1-conventions)
2. [Platform Endpoints](#2-platform-endpoints)
3. [Authentication](#3-authentication)
4. [Organization](#4-organization)
5. [RBAC](#5-rbac)
6. [Overtime Module](#6-overtime-module)
7. [Work Orders Module (Schema-Ready)](#7-work-orders-module-schema-ready)
8. [Vehicles Module (Schema-Ready)](#8-vehicles-module-schema-ready)
9. [Dashboard](#9-dashboard)
10. [Reports](#10-reports)
11. [Global Search](#11-global-search)
12. [Notifications](#12-notifications)
13. [Maps](#13-maps)
14. [Cloudinary](#14-cloudinary)
15. [Configuration (Settings)](#15-configuration-settings)
16. [Sync](#16-sync)
17. [Audit Log](#17-audit-log)
18. [Error Responses](#18-error-responses)
19. [Endpoint Summary](#19-endpoint-summary)

---

## 1. Conventions

### 1.1 Headers

| Header | Required | Description |
|--------|----------|-------------|
| `Authorization` | Protected routes | `Bearer <accessToken>` |
| `X-Idempotency-Key` | Mutations | Client UUID |
| `X-Request-Id` | Optional | Correlation ID |
| `X-Device-Id` | Mobile | Device identifier |
| `X-App-Version` | Mobile | App semver |
| `Accept-Language` | Optional | `en`, `ar` (future) |

### 1.2 Response Envelope

```json
{
  "success": true,
  "data": { },
  "meta": {
    "requestId": "uuid",
    "timestamp": "2026-07-29T13:00:00.000Z",
    "apiVersion": "2.0.0"
  }
}
```

### 1.3 Hierarchy Filter Parameters

Most list endpoints accept org hierarchy filters:

| Param | Description |
|-------|-------------|
| `companyId` | Company (auto-scoped from JWT) |
| `branchId` | Branch filter |
| `regionId` | Region filter |
| `cityId` | City filter |
| `departmentId` | Department filter |
| `teamId` | Team filter |

---

## 2. Platform Endpoints

### GET `/platform/modules`

List enabled modules for current company.

**Permission:** Authenticated

```json
{
  "success": true,
  "data": {
    "modules": [
      { "id": "overtime", "state": "GA", "version": "1.0.0" },
      { "id": "work_orders", "state": "SCHEMA_READY", "version": "0.1.0" },
      { "id": "vehicles", "state": "SCHEMA_READY", "version": "0.1.0" }
    ]
  }
}
```

### GET `/platform/health`

Public health check.

---

## 3. Authentication

### POST `/auth/login`
### POST `/auth/refresh`
### POST `/auth/logout`
### GET `/auth/me`

`GET /auth/me` response includes permissions array:

```json
{
  "data": {
    "id": "...",
    "email": "tech@company.com",
    "firstName": "Ahmed",
    "lastName": "Hassan",
    "roleIds": ["..."],
    "roles": [{ "slug": "technician", "name": "Technician" }],
    "permissions": ["overtime:view_own", "overtime:start", "overtime:end", ...],
    "organization": {
      "companyId": "...", "branchId": "...", "regionId": "...",
      "cityId": "...", "departmentId": "...", "teamId": "..."
    },
    "hasRunningOvertime": true
  }
}
```

---

## 4. Organization

### Branches

| Method | Path | Permission |
|--------|------|------------|
| GET | `/organization/branches` | `organization:view` |
| POST | `/organization/branches` | `organization:manage_branches` |
| GET | `/organization/branches/:id` | `organization:view` |
| PUT | `/organization/branches/:id` | `organization:manage_branches` |
| DELETE | `/organization/branches/:id` | `organization:manage_branches` |

### Regions

| Method | Path | Permission |
|--------|------|------------|
| GET | `/organization/regions` | `organization:view` |
| POST | `/organization/regions` | `organization:manage_regions` |
| PUT | `/organization/regions/:id` | `organization:manage_regions` |
| DELETE | `/organization/regions/:id` | `organization:manage_regions` |

Query: `branchId` required for list.

### Cities

| Method | Path | Permission |
|--------|------|------------|
| GET | `/organization/cities` | `organization:view` |
| POST | `/organization/cities` | `organization:manage_cities` |
| PUT | `/organization/cities/:id` | `organization:manage_cities` |
| DELETE | `/organization/cities/:id` | `organization:manage_cities` |

Query: `regionId` required for list.

### Departments

| Method | Path | Permission |
|--------|------|------------|
| GET | `/organization/departments` | `organization:view` |
| POST | `/organization/departments` | `organization:manage_departments` |
| PUT | `/organization/departments/:id` | `organization:manage_departments` |
| DELETE | `/organization/departments/:id` | `organization:manage_departments` |

### Teams

| Method | Path | Permission |
|--------|------|------------|
| GET | `/organization/teams` | `organization:view` |
| POST | `/organization/teams` | `organization:manage_teams` |
| PUT | `/organization/teams/:id` | `organization:manage_teams` |
| DELETE | `/organization/teams/:id` | `organization:manage_teams` |

### Users

| Method | Path | Permission |
|--------|------|------------|
| GET | `/organization/users` | `organization:view` |
| POST | `/organization/users` | `organization:manage_users` |
| GET | `/organization/users/:id` | `organization:view` |
| PUT | `/organization/users/:id` | `organization:manage_users` |
| DELETE | `/organization/users/:id` | `organization:manage_users` |

Query params: `page`, `limit`, `search`, `branchId`, `departmentId`, `teamId`, `roleId`, `isActive`

### GET `/organization/hierarchy`

Full org tree for current company (cached).

**Permission:** `organization:view`

---

## 5. RBAC

| Method | Path | Permission |
|--------|------|------------|
| GET | `/rbac/roles` | `organization:view` |
| POST | `/rbac/roles` | `rbac:manage_roles` |
| PUT | `/rbac/roles/:id` | `rbac:manage_roles` |
| DELETE | `/rbac/roles/:id` | `rbac:manage_roles` |
| GET | `/rbac/permissions` | `organization:view` |
| PUT | `/rbac/users/:id/permissions` | `rbac:manage_permissions` |

---

## 6. Overtime Module

### GET `/overtime/running`

Current user's running session.

**Permission:** `overtime:view_own`

### POST `/overtime/start`

**Permission:** `overtime:start`

```json
{
  "type": "TRAVEL",
  "jobDescription": "Emergency server repair — Basra",
  "workOrderId": "6888...",
  "vehicleId": "6888...",
  "startPhoto": {
    "url": "https://res.cloudinary.com/.../start.jpg",
    "publicId": "company/employee/2026/07/record/start"
  },
  "startGps": {
    "latitude": 33.3152,
    "longitude": 44.3661,
    "accuracy": 8.5,
    "altitude": 34.2,
    "heading": 180,
    "speed": 0,
    "timestamp": "2026-07-29T05:00:03.000Z",
    "provider": "fused"
  },
  "startDeviceInfo": {
    "platform": "android",
    "manufacturer": "Samsung",
    "phoneModel": "Galaxy S24",
    "osVersion": "14",
    "appVersion": "1.0.0",
    "deviceIdentifier": "abc-123"
  },
  "travel": {
    "governorate": "Basra",
    "destination": "Basra Tech Center",
    "travelReason": "Emergency server failure",
    "travelDistanceKm": 550,
    "estimatedTravelMinutes": 360
  },
  "clientTimestamp": "2026-07-29T05:00:00.000Z"
}
```

**States created:** `RUNNING` (online) or `DRAFT` → `RUNNING` (offline sync)

### POST `/overtime/:id/end`

**Permission:** `overtime:end`

Transitions: `RUNNING` → `PENDING_REVIEW`

Server calculates overtime and returns all computed fields.

### POST `/overtime/:id/cancel`

**Permission:** `overtime:cancel`

Transitions: `RUNNING` → `DRAFT` (discarded on sync)

### POST `/overtime/:id/approve`

**Permission:** `overtime:approve` + scope

```json
{ "notes": "Verified with site manager" }
```

Transitions: `PENDING_REVIEW` → `APPROVED`

### POST `/overtime/:id/reject`

**Permission:** `overtime:reject` + scope

```json
{ "reason": "Start photo does not show work site." }
```

Transitions: `PENDING_REVIEW` → `REJECTED`

### POST `/overtime/:id/archive`

**Permission:** `overtime:archive`

Transitions: `APPROVED` → `ARCHIVED` or `REJECTED` → `ARCHIVED`

### GET `/overtime`

**Permission:** `overtime:view_own` | `overtime:view_team` | `overtime:view_all`

Query: `page`, `limit`, `status`, `type`, `userId`, `workOrderId`, `vehicleId`, `branchId`, `departmentId`, `startDate`, `endDate`

### GET `/overtime/:id`

Full detail including GPS, device info, travel metadata, map pins, review info.

### GET `/overtime/pending-review`

Review queue for supervisors.

**Permission:** `overtime:view_team`

---

## 7. Work Orders Module (Schema-Ready)

> Endpoints documented but return `501 Not Implemented` until module reaches `IN_DEV` state. Schema and permissions exist.

| Method | Path | Permission |
|--------|------|------------|
| GET | `/work-orders` | `work_orders:view_team` |
| POST | `/work-orders` | `work_orders:create` |
| GET | `/work-orders/:id` | `work_orders:view_own` |
| PUT | `/work-orders/:id` | `work_orders:update` |
| POST | `/work-orders/:id/assign` | `work_orders:assign` |
| POST | `/work-orders/:id/complete` | `work_orders:complete` |
| POST | `/work-orders/:id/cancel` | `work_orders:cancel` |

### GET `/work-orders/my-assignments`

Work orders assigned to current technician (for overtime linking).

**Permission:** `work_orders:view_own`

---

## 8. Vehicles Module (Schema-Ready)

| Method | Path | Permission |
|--------|------|------------|
| GET | `/vehicles` | `vehicles:view` |
| POST | `/vehicles` | `vehicles:manage` |
| GET | `/vehicles/:id` | `vehicles:view` |
| PUT | `/vehicles/:id` | `vehicles:manage` |
| POST | `/vehicles/:id/assign` | `vehicles:assign` |
| POST | `/vehicles/:id/unassign` | `vehicles:assign` |
| GET | `/vehicles/my-assignment` | `vehicles:view` |

---

## 9. Dashboard

### GET `/dashboard`

**Permission:** `dashboard:view`

Query: `branchId`, `departmentId` (scope filters)

```json
{
  "success": true,
  "data": {
    "overtime": {
      "running": 12,
      "pendingReview": 8,
      "approvedToday": 5,
      "rejectedToday": 1,
      "todayHours": 18.5,
      "monthlyRegularHours": 320.0,
      "monthlyTravelHours": 85.5,
      "monthlyTotalHours": 405.5
    },
    "technicians": {
      "online": 45,
      "offline": 12,
      "total": 57
    },
    "organization": {
      "branches": 3,
      "departments": 12,
      "teams": 24,
      "activeUsers": 85
    },
    "scope": {
      "level": "department",
      "departmentId": "6888..."
    },
    "generatedAt": "2026-07-29T13:00:00.000Z"
  }
}
```

### GET `/dashboard/technician-status`

Online/offline technician list.

**Permission:** `dashboard:view`

---

## 10. Reports

### GET `/reports/overtime`

Unified report endpoint.

**Permission:** `reports:view_own` | `reports:view_team` | `reports:view_all`

| Param | Type | Description |
|-------|------|-------------|
| `reportType` | string | `daily`, `weekly`, `monthly`, `yearly`, `travel`, `rejected`, `pending` |
| `dimension` | string | `employee`, `team`, `department`, `city`, `region`, `branch`, `company`, `vehicle` |
| `year` | number | Required for monthly/yearly |
| `month` | number | Required for monthly |
| `week` | number | Required for weekly |
| `date` | ISO date | Required for daily |
| `userId` | string | For employee dimension |
| `branchId` | string | Hierarchy filter |
| `departmentId` | string | Hierarchy filter |
| `vehicleId` | string | Vehicle filter |

Response structure:

```json
{
  "data": {
    "reportType": "monthly",
    "dimension": "employee",
    "period": { "year": 2026, "month": 7 },
    "filters": { "branchId": "..." },
    "rows": [
      {
        "employee": { "id": "...", "name": "Ahmed Hassan", "employeeId": "EMP-042" },
        "organization": { "branch": "Baghdad", "department": "Field Ops" },
        "regular": {
          "approvedMinutes": 480, "approvedHours": 8.0,
          "rejectedMinutes": 60, "rejectedHours": 1.0,
          "pendingMinutes": 120, "pendingHours": 2.0
        },
        "travel": {
          "approvedMinutes": 240, "approvedHours": 4.0,
          "rejectedMinutes": 0, "rejectedHours": 0,
          "pendingMinutes": 0, "pendingHours": 0
        },
        "totals": {
          "approvedHours": 12.0, "rejectedHours": 1.0, "pendingHours": 2.0
        },
        "sessionCounts": { "approved": 5, "rejected": 1, "pending": 2 }
      }
    ],
    "summary": {
      "totalEmployees": 15,
      "totalApprovedHours": 120.5,
      "totalRejectedHours": 8.0,
      "totalPendingHours": 24.0
    }
  }
}
```

### GET `/reports/overtime/export`

**Permission:** `reports:export`

Query: Same as above + `format` (`json`, `csv`, `xlsx`, `pdf`)

| Format | MVP | Phase |
|--------|-----|-------|
| JSON | ✅ | 4 |
| CSV | ✅ | 4 |
| XLSX | ❌ | 5 |
| PDF | ❌ | 5 |

---

## 11. Global Search

### GET `/search`

**Permission:** `search:global`

| Param | Type | Description |
|-------|------|-------------|
| `q` | string | Free text search |
| `entities` | string | Comma-separated: `employees,overtime,work_orders,vehicles,departments` |
| `employeeId` | string | Filter |
| `departmentId` | string | Filter |
| `branchId` | string | Filter |
| `vehicleId` | string | Filter |
| `workOrderId` | string | Filter |
| `jobNumber` | string | Filter |
| `dateFrom` | ISO date | Filter |
| `dateTo` | ISO date | Filter |
| `status` | string | Filter |
| `type` | string | `REGULAR`, `TRAVEL` |
| `page` | number | Pagination |
| `limit` | number | Max 50 |

```json
{
  "data": {
    "results": [
      {
        "entity": "overtime",
        "id": "...",
        "title": "Network Maintenance",
        "subtitle": "Ahmed Hassan — APPROVED — 2.5h",
        "metadata": { "status": "APPROVED", "date": "2026-07-28" },
        "score": 0.95
      },
      {
        "entity": "employee",
        "id": "...",
        "title": "Ahmed Hassan",
        "subtitle": "Field Operations — EMP-042",
        "score": 0.87
      }
    ],
    "total": 42,
    "page": 1,
    "limit": 20
  }
}
```

---

## 12. Notifications

| Method | Path | Permission |
|--------|------|------------|
| GET | `/notifications` | `notifications:view` |
| PUT | `/notifications/:id/read` | `notifications:view` |
| PUT | `/notifications/read-all` | `notifications:view` |
| GET | `/notifications/unread-count` | `notifications:view` |
| GET | `/notifications/templates` | `notifications:manage_templates` |
| PUT | `/notifications/templates/:key` | `notifications:manage_templates` |
| POST | `/notifications/broadcast` | `notifications:broadcast` |

---

## 13. Maps

| Method | Path | Permission |
|--------|------|------------|
| POST | `/maps/reverse-geocode` | Authenticated |
| GET | `/maps/overtime/:id` | `overtime:view_own` / team / all |

Provider configured in company settings (`maps.provider`).

---

## 14. Cloudinary

### POST `/cloudinary/sign-upload`

**Permission:** Authenticated

```json
{
  "recordId": "6888a1b2c3d4e5f6a7b8c9d0",
  "photoType": "start",
  "year": 2026,
  "month": 7
}
```

Backend constructs path: `{companyId}/{employeeId}/{year}/{month}/{recordId}/{photoType}.jpg`

Response includes `signature`, `timestamp`, `apiKey`, `cloudName`, `folder`, `publicId`, `uploadUrl`.

### POST `/cloudinary/verify`

Verify upload completed and path matches expected convention.

---

## 15. Configuration (Settings)

| Method | Path | Permission |
|--------|------|------------|
| GET | `/config` | `settings:view` |
| GET | `/config/:group` | `settings:view` |
| PUT | `/config/:key` | `settings:manage` |
| GET | `/config/working-hours` | Authenticated |
| GET | `/config/holidays` | Authenticated |
| POST | `/config/holidays` | `settings:manage_holidays` |
| PUT | `/config/holidays/:id` | `settings:manage_holidays` |
| DELETE | `/config/holidays/:id` | `settings:manage_holidays` |

### GET `/config/working-hours`

Available to all authenticated users (needed for overtime UI):

```json
{
  "data": {
    "start": "09:00",
    "end": "17:00",
    "timezone": "Africa/Cairo",
    "allowedOvertimeTypes": ["REGULAR", "TRAVEL"]
  }
}
```

---

## 16. Sync

### POST `/sync/batch`

Process ordered offline operations.

```json
{
  "operations": [
    {
      "idempotencyKey": "uuid-1",
      "type": "UPLOAD_PHOTO",
      "payload": { "localPath": "...", "photoType": "start", "recordId": "..." }
    },
    {
      "idempotencyKey": "uuid-2",
      "type": "START_OVERTIME",
      "payload": { "...": "..." },
      "clientTimestamp": "2026-07-29T05:00:00.000Z"
    }
  ]
}
```

### GET `/sync/status`

```json
{
  "data": {
    "hasRunningOvertime": true,
    "runningOvertimeId": "...",
    "lastSyncedAt": "...",
    "serverTime": "...",
    "pendingOperations": 0
  }
}
```

---

## 17. Audit Log

| Method | Path | Permission |
|--------|------|------------|
| GET | `/audit-logs` | `audit:view` |
| GET | `/audit-logs/:id` | `audit:view` |

Query: `page`, `limit`, `action`, `module`, `actorId`, `resourceType`, `resourceId`, `dateFrom`, `dateTo`

---

## 18. Error Responses

### State Transition Error (422)

```json
{
  "success": false,
  "error": {
    "code": "INVALID_STATE_TRANSITION",
    "message": "Cannot transition from APPROVED to RUNNING",
    "details": {
      "currentStatus": "APPROVED",
      "requestedAction": "start",
      "allowedTransitions": ["ARCHIVED"]
    }
  }
}
```

### Permission Denied (403)

```json
{
  "success": false,
  "error": {
    "code": "FORBIDDEN",
    "message": "Missing permission: overtime:approve",
    "details": {
      "requiredPermission": "overtime:approve",
      "userPermissions": ["overtime:view_team"]
    }
  }
}
```

### Module Not Enabled (404)

```json
{
  "success": false,
  "error": {
    "code": "MODULE_NOT_ENABLED",
    "message": "Work Orders module is not enabled for this company"
  }
}
```

---

## 19. Endpoint Summary

| # | Method | Endpoint | Module |
|---|--------|----------|--------|
| 1 | GET | `/platform/modules` | Platform |
| 2 | GET | `/platform/health` | Platform |
| 3 | POST | `/auth/login` | Auth |
| 4 | POST | `/auth/refresh` | Auth |
| 5 | POST | `/auth/logout` | Auth |
| 6 | GET | `/auth/me` | Auth |
| 7-11 | CRUD | `/organization/branches` | Organization |
| 12-16 | CRUD | `/organization/regions` | Organization |
| 17-21 | CRUD | `/organization/cities` | Organization |
| 22-26 | CRUD | `/organization/departments` | Organization |
| 27-31 | CRUD | `/organization/teams` | Organization |
| 32-36 | CRUD | `/organization/users` | Organization |
| 37 | GET | `/organization/hierarchy` | Organization |
| 38-43 | CRUD | `/rbac/roles` | RBAC |
| 44 | GET | `/rbac/permissions` | RBAC |
| 45 | PUT | `/rbac/users/:id/permissions` | RBAC |
| 46 | GET | `/overtime/running` | Overtime |
| 47 | POST | `/overtime/start` | Overtime |
| 48 | POST | `/overtime/:id/end` | Overtime |
| 49 | POST | `/overtime/:id/cancel` | Overtime |
| 50 | POST | `/overtime/:id/approve` | Overtime |
| 51 | POST | `/overtime/:id/reject` | Overtime |
| 52 | POST | `/overtime/:id/archive` | Overtime |
| 53 | GET | `/overtime` | Overtime |
| 54 | GET | `/overtime/:id` | Overtime |
| 55 | GET | `/overtime/pending-review` | Overtime |
| 56-62 | CRUD | `/work-orders` | Work Orders |
| 63 | GET | `/work-orders/my-assignments` | Work Orders |
| 64-70 | CRUD | `/vehicles` | Vehicles |
| 71 | GET | `/dashboard` | Dashboard |
| 72 | GET | `/dashboard/technician-status` | Dashboard |
| 73 | GET | `/reports/overtime` | Reports |
| 74 | GET | `/reports/overtime/export` | Reports |
| 75 | GET | `/search` | Search |
| 76-82 | CRUD | `/notifications` | Notifications |
| 83-84 | POST/GET | `/maps/*` | Maps |
| 85-86 | POST | `/cloudinary/*` | Cloudinary |
| 87-94 | CRUD | `/config/*` | Configuration |
| 95-96 | POST/GET | `/sync/*` | Sync |
| 97-98 | GET | `/audit-logs` | Audit |

**Total: 98 endpoints** (35 implemented in MVP; remainder schema-ready or Phase 4+)
