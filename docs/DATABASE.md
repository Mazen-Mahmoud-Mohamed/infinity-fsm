# MongoDB Database Schema Design

**Product:** Infinity FSM Platform  
**Version:** 2.0.0  
**Database:** MongoDB 7.x  
**ODM:** Mongoose 8.x  

---

## Table of Contents

1. [Design Principles](#1-design-principles)
2. [Entity Relationship Overview](#2-entity-relationship-overview)
3. [Organization Collections](#3-organization-collections)
4. [Identity & Access Collections](#4-identity--access-collections)
5. [Overtime Collections](#5-overtime-collections)
6. [Work Orders Collections (Schema-Ready)](#6-work-orders-collections-schema-ready)
7. [Vehicle Collections (Schema-Ready)](#7-vehicle-collections-schema-ready)
8. [Platform Collections](#8-platform-collections)
9. [Shared Sub-Schemas](#9-shared-sub-schemas)
10. [Indexes](#10-indexes)
11. [Aggregation Patterns](#11-aggregation-patterns)
12. [Sample Documents](#12-sample-documents)

---

## 1. Design Principles

1. **Multi-tenant isolation** — Every business collection includes `companyId`.
2. **Hierarchy denormalization** — Records snapshot org path at creation time.
3. **Schema-ready future modules** — Work Orders, Vehicles exist before feature code.
4. **Immutable audit** — Audit logs have no update/delete operations.
5. **Soft deletes** — Org units and users use `deletedAt`.
6. **Server authority** — Calculated fields set only by domain services.
7. **Extensible enums** — String enums with validation, not MongoDB enum type (allows future values).
8. **Version tracking** — Calculation and schema versions stored for migration safety.

---

## 2. Entity Relationship Overview

```
┌──────────┐
│ companies│
└────┬─────┘
     │ 1:N
     ├── branches ── regions ── cities ── departments ── teams
     │                                                      │
     │                                                      │ N:1
     ├── users ◀────────────────────────────────────────────┘
     │     │
     │     ├── roles ── permissions (RBAC)
     │     │
     │     ├── overtime_records ── (optional) ── work_orders
     │     │                                        │
     │     └── vehicle_assignments ── vehicles      └── customers (future)
     │
     ├── company_settings
     ├── notification_templates
     ├── holidays
     ├── audit_logs
     ├── notifications
     └── idempotency_records
```

---

## 3. Organization Collections

### 3.1 `companies`

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `_id` | ObjectId | ✅ | Primary key |
| `name` | String | ✅ | Company name |
| `slug` | String | ✅ | URL-safe identifier (unique globally) |
| `logoUrl` | String | ❌ | Cloudinary URL |
| `isActive` | Boolean | ✅ | Default: `true` |
| `enabledModules` | [String] | ✅ | `['overtime', 'work_orders', ...]` |
| `createdAt` | Date | ✅ | Auto |
| `updatedAt` | Date | ✅ | Auto |

> Working hours, timezone, and policies moved to `company_settings`.

---

### 3.2 `branches`

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `_id` | ObjectId | ✅ | |
| `companyId` | ObjectId | ✅ | FK → companies |
| `name` | String | ✅ | |
| `code` | String | ✅ | Unique per company |
| `address` | Object | ❌ | `{ street, city, governorate, country }` |
| `isActive` | Boolean | ✅ | Default: `true` |
| `deletedAt` | Date | ❌ | Soft delete |
| `createdAt` | Date | ✅ | |
| `updatedAt` | Date | ✅ | |

**Index:** `{ companyId: 1, code: 1 }` unique

---

### 3.3 `regions`

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `_id` | ObjectId | ✅ | |
| `companyId` | ObjectId | ✅ | |
| `branchId` | ObjectId | ✅ | FK → branches |
| `name` | String | ✅ | |
| `code` | String | ✅ | Unique per branch |
| `isActive` | Boolean | ✅ | |
| `deletedAt` | Date | ❌ | |
| `createdAt` | Date | ✅ | |
| `updatedAt` | Date | ✅ | |

**Index:** `{ branchId: 1, code: 1 }` unique

---

### 3.4 `cities`

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `_id` | ObjectId | ✅ | |
| `companyId` | ObjectId | ✅ | |
| `branchId` | ObjectId | ✅ | Denormalized |
| `regionId` | ObjectId | ✅ | FK → regions |
| `name` | String | ✅ | |
| `code` | String | ✅ | Unique per region |
| `isActive` | Boolean | ✅ | |
| `deletedAt` | Date | ❌ | |
| `createdAt` | Date | ✅ | |
| `updatedAt` | Date | ✅ | |

**Index:** `{ regionId: 1, code: 1 }` unique

---

### 3.5 `departments`

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `_id` | ObjectId | ✅ | |
| `companyId` | ObjectId | ✅ | |
| `branchId` | ObjectId | ✅ | Denormalized |
| `regionId` | ObjectId | ✅ | Denormalized |
| `cityId` | ObjectId | ✅ | FK → cities |
| `name` | String | ✅ | |
| `code` | String | ✅ | Unique per city |
| `supervisorIds` | [ObjectId] | ❌ | FK → users |
| `isActive` | Boolean | ✅ | |
| `deletedAt` | Date | ❌ | |
| `createdAt` | Date | ✅ | |
| `updatedAt` | Date | ✅ | |

**Index:** `{ cityId: 1, code: 1 }` unique

---

### 3.6 `teams`

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `_id` | ObjectId | ✅ | |
| `companyId` | ObjectId | ✅ | |
| `branchId` | ObjectId | ✅ | Denormalized |
| `regionId` | ObjectId | ✅ | Denormalized |
| `cityId` | ObjectId | ✅ | Denormalized |
| `departmentId` | ObjectId | ✅ | FK → departments |
| `name` | String | ✅ | |
| `code` | String | ✅ | Unique per department |
| `leadId` | ObjectId | ❌ | FK → users (team lead) |
| `isActive` | Boolean | ✅ | |
| `deletedAt` | Date | ❌ | |
| `createdAt` | Date | ✅ | |
| `updatedAt` | Date | ✅ | |

**Index:** `{ departmentId: 1, code: 1 }` unique

---

## 4. Identity & Access Collections

### 4.1 `users`

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `_id` | ObjectId | ✅ | |
| `companyId` | ObjectId | ✅ | |
| `employeeId` | String | ✅ | Unique per company |
| `email` | String | ✅ | Unique globally |
| `passwordHash` | String | ✅ | bcrypt |
| `firstName` | String | ✅ | |
| `lastName` | String | ✅ | |
| `phone` | String | ❌ | |
| `avatarUrl` | String | ❌ | |
| **Hierarchy placement** | | | |
| `branchId` | ObjectId | ✅ | |
| `regionId` | ObjectId | ✅ | |
| `cityId` | ObjectId | ✅ | |
| `departmentId` | ObjectId | ✅ | |
| `teamId` | ObjectId | ❌ | |
| **RBAC** | | | |
| `roleIds` | [ObjectId] | ✅ | FK → roles |
| `permissionOverrides` | [Object] | ❌ | `{ permission, type: 'grant'\|'deny' }` |
| **Status** | | | |
| `isActive` | Boolean | ✅ | |
| `lastLoginAt` | Date | ❌ | |
| `lastSeenAt` | Date | ❌ | For online/offline dashboard |
| `deletedAt` | Date | ❌ | |
| `createdAt` | Date | ✅ | |
| `updatedAt` | Date | ✅ | |

---

### 4.2 `roles`

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `_id` | ObjectId | ✅ | |
| `companyId` | ObjectId | ❌ | Null = system role (global) |
| `name` | String | ✅ | `Admin`, `Supervisor`, `Technician`, `HR` |
| `slug` | String | ✅ | `admin`, `supervisor`, `technician`, `hr` |
| `description` | String | ❌ | |
| `permissionIds` | [ObjectId] | ✅ | FK → permissions |
| `isSystem` | Boolean | ✅ | Cannot be deleted if true |
| `isActive` | Boolean | ✅ | |
| `createdAt` | Date | ✅ | |
| `updatedAt` | Date | ✅ | |

**Default system roles:** Admin, Supervisor, Technician, HR (future)

---

### 4.3 `permissions`

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `_id` | ObjectId | ✅ | |
| `key` | String | ✅ | Unique globally, e.g. `overtime:approve` |
| `module` | String | ✅ | `overtime`, `organization`, `reports`, etc. |
| `action` | String | ✅ | `view`, `create`, `approve`, `export`, etc. |
| `description` | String | ✅ | Human-readable |
| `isActive` | Boolean | ✅ | |

See [RBAC.md](./RBAC.md) for complete permission catalog.

---

### 4.4 `refresh_tokens`

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `_id` | ObjectId | ✅ | |
| `userId` | ObjectId | ✅ | |
| `tokenHash` | String | ✅ | SHA-256 |
| `deviceId` | String | ✅ | |
| `deviceInfo` | DeviceMetadata | ❌ | See sub-schema |
| `expiresAt` | Date | ✅ | TTL index |
| `revokedAt` | Date | ❌ | |
| `createdAt` | Date | ✅ | |

---

## 5. Overtime Collections

### 5.1 `overtime_records`

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `_id` | ObjectId | ✅ | |
| `companyId` | ObjectId | ✅ | |
| `userId` | ObjectId | ✅ | Technician |
| `organizationSnapshot` | OrgSnapshot | ✅ | Hierarchy at creation |
| **Classification** | | | |
| `type` | String | ✅ | `REGULAR`, `TRAVEL` |
| `status` | String | ✅ | See state machine |
| `workOrderId` | ObjectId | ❌ | FK → work_orders (optional) |
| `vehicleId` | ObjectId | ❌ | FK → vehicles (optional, future) |
| **Content** | | | |
| `jobDescription` | String | ✅ | Min length from settings |
| `completionNotes` | String | ❌ | |
| **Start capture** | | | |
| `startAt` | Date | ✅ | Server authoritative |
| `startGps` | GpsPoint | ✅ | Extended GPS |
| `startPhoto` | PhotoRef | ✅ | `{ url, publicId }` |
| `startDeviceInfo` | DeviceMetadata | ✅ | |
| **End capture** | | | |
| `endAt` | Date | ❌ | |
| `endGps` | GpsPoint | ❌ | |
| `endPhoto` | PhotoRef | ❌ | |
| `endDeviceInfo` | DeviceMetadata | ❌ | |
| **Travel extension** (when type=TRAVEL) | | | |
| `travel` | TravelMetadata | ❌ | See sub-schema |
| **Calculated (server-only)** | | | |
| `rawDurationMinutes` | Number | ❌ | |
| `excludedMinutes` | Number | ❌ | |
| `overtimeMinutes` | Number | ❌ | |
| `overtimeHours` | Number | ❌ | |
| `calculationVersion` | String | ❌ | |
| `calculatedAt` | Date | ❌ | |
| **Quality flags** | | | |
| `gpsQuality` | String | ❌ | `GOOD`, `LOW` |
| `syncStatus` | String | ✅ | `SYNCED`, `PENDING` |
| **Review** | | | |
| `reviewedBy` | ObjectId | ❌ | |
| `reviewedAt` | Date | ❌ | |
| `rejectionReason` | String | ❌ | |
| **Sync** | | | |
| `clientRequestId` | String | ✅ | Idempotency key |
| `createdAt` | Date | ✅ | |
| `updatedAt` | Date | ✅ | |
| `archivedAt` | Date | ❌ | |

#### Status Enum

`DRAFT` | `RUNNING` | `PENDING_REVIEW` | `APPROVED` | `REJECTED` | `ARCHIVED`

---

## 6. Work Orders Collections (Schema-Ready)

### 6.1 `work_orders`

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `_id` | ObjectId | ✅ | |
| `companyId` | ObjectId | ✅ | |
| `jobNumber` | String | ✅ | Unique per company |
| `jobTitle` | String | ✅ | |
| `customerId` | ObjectId | ❌ | FK → customers (future) |
| `customerName` | String | ❌ | Denormalized |
| `customerAddress` | Object | ❌ | `{ street, city, governorate, lat, lng }` |
| `assignedTechnicianId` | ObjectId | ❌ | FK → users |
| `supervisorId` | ObjectId | ❌ | FK → users |
| `organizationSnapshot` | OrgSnapshot | ✅ | |
| `priority` | String | ✅ | `LOW`, `MEDIUM`, `HIGH`, `CRITICAL` |
| `status` | String | ✅ | `DRAFT`, `ASSIGNED`, `IN_PROGRESS`, `ON_HOLD`, `COMPLETED`, `CANCELLED` |
| `description` | String | ❌ | |
| `notes` | String | ❌ | |
| `attachments` | [PhotoRef] | ❌ | |
| `location` | GpsPoint | ❌ | |
| `estimatedDurationMinutes` | Number | ❌ | |
| `actualDurationMinutes` | Number | ❌ | |
| `createdAt` | Date | ✅ | |
| `updatedAt` | Date | ✅ | |
| `completedAt` | Date | ❌ | |
| `deletedAt` | Date | ❌ | |

**Index:** `{ companyId: 1, jobNumber: 1 }` unique

### 6.2 `customers` (Future — Schema Reserved)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `_id` | ObjectId | ✅ | |
| `companyId` | ObjectId | ✅ | |
| `name` | String | ✅ | |
| `code` | String | ✅ | |
| `contactPhone` | String | ❌ | |
| `contactEmail` | String | ❌ | |
| `address` | Object | ❌ | |
| `isActive` | Boolean | ✅ | |
| `createdAt` | Date | ✅ | |
| `updatedAt` | Date | ✅ | |

---

## 7. Vehicle Collections (Schema-Ready)

### 7.1 `vehicles`

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `_id` | ObjectId | ✅ | |
| `companyId` | ObjectId | ✅ | |
| `vehicleCode` | String | ✅ | Unique per company |
| `plateNumber` | String | ✅ | |
| `type` | String | ✅ | `CAR`, `VAN`, `TRUCK`, `MOTORCYCLE` |
| `make` | String | ❌ | |
| `model` | String | ❌ | |
| `year` | Number | ❌ | |
| `status` | String | ✅ | `ACTIVE`, `MAINTENANCE`, `RETIRED` |
| `branchId` | ObjectId | ❌ | |
| `createdAt` | Date | ✅ | |
| `updatedAt` | Date | ✅ | |

**Index:** `{ companyId: 1, vehicleCode: 1 }` unique

### 7.2 `vehicle_assignments`

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `_id` | ObjectId | ✅ | |
| `companyId` | ObjectId | ✅ | |
| `vehicleId` | ObjectId | ✅ | FK → vehicles |
| `userId` | ObjectId | ✅ | FK → users (technician) |
| `assignedAt` | Date | ✅ | |
| `unassignedAt` | Date | ❌ | Null = currently assigned |
| `assignedBy` | ObjectId | ✅ | FK → users (admin) |
| `notes` | String | ❌ | |
| `createdAt` | Date | ✅ | |

**Index:** `{ vehicleId: 1, unassignedAt: 1 }` — find current assignment

---

## 8. Platform Collections

### 8.1 `company_settings`

Key-value store with grouping. Replaces simple settings from v1.0.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `_id` | ObjectId | ✅ | |
| `companyId` | ObjectId | ✅ | |
| `key` | String | ✅ | Dot-notation key |
| `value` | Mixed | ✅ | |
| `group` | String | ✅ | Category |
| `dataType` | String | ✅ | `string`, `number`, `boolean`, `array`, `object` |
| `updatedBy` | ObjectId | ✅ | |
| `createdAt` | Date | ✅ | |
| `updatedAt` | Date | ✅ | |

**Index:** `{ companyId: 1, key: 1 }` unique

#### Default Settings Seed

| Key | Default | Group |
|-----|---------|-------|
| `company.name` | (from companies) | profile |
| `company.logo` | null | profile |
| `working_hours.start` | `"09:00"` | working_hours |
| `working_hours.end` | `"17:00"` | working_hours |
| `working_hours.timezone` | `"Africa/Cairo"` | working_hours |
| `overtime.allowed_types` | `["REGULAR","TRAVEL"]` | overtime |
| `overtime.max_session_hours` | `16` | overtime |
| `overtime.gps_accuracy_limit_meters` | `100` | overtime |
| `overtime.auto_archive_days` | `90` | overtime |
| `travel.rate_per_km` | `0` | travel |
| `travel.max_reimbursement` | `0` | travel |
| `media.camera_quality` | `80` | media |
| `media.max_image_size_mb` | `5` | media |
| `offline.retention_days` | `30` | offline |
| `offline.max_queue_size` | `100` | offline |
| `offline.retry_intervals_seconds` | `[5,30,120,600,3600]` | offline |
| `notifications.channels` | `["in_app"]` | notifications |
| `notifications.quiet_hours` | null | notifications |
| `maps.provider` | `"google"` | maps |
| `cloudinary.folder_prefix` | `""` | cloudinary |

---

### 8.2 `holidays`

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `_id` | ObjectId | ✅ | |
| `companyId` | ObjectId | ✅ | |
| `date` | Date | ✅ | Calendar date (no time) |
| `name` | String | ✅ | e.g. "New Year" |
| `isRecurring` | Boolean | ✅ | Repeats yearly |
| `createdAt` | Date | ✅ | |

**Index:** `{ companyId: 1, date: 1 }`

---

### 8.3 `notification_templates`

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `_id` | ObjectId | ✅ | |
| `companyId` | ObjectId | ❌ | Null = system default |
| `key` | String | ✅ | `overtime.approved` |
| `module` | String | ✅ | |
| `channels` | [String] | ✅ | `in_app`, `push`, `email`, `sms` |
| `title` | String | ✅ | Template with `{{variables}}` |
| `body` | String | ✅ | |
| `variables` | [String] | ✅ | Available variable names |
| `isActive` | Boolean | ✅ | |

---

### 8.4 `notifications`

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `_id` | ObjectId | ✅ | |
| `companyId` | ObjectId | ✅ | |
| `userId` | ObjectId | ✅ | Recipient |
| `templateKey` | String | ✅ | |
| `title` | String | ✅ | Rendered |
| `body` | String | ✅ | Rendered |
| `data` | Object | ❌ | `{ overtimeId, action, ... }` |
| `channels` | [Object] | ✅ | `[{ channel, status, sentAt }]` |
| `isRead` | Boolean | ✅ | Default: false |
| `readAt` | Date | ❌ | |
| `createdAt` | Date | ✅ | |

---

### 8.5 `audit_logs`

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `_id` | ObjectId | ✅ | |
| `companyId` | ObjectId | ✅ | |
| `actorId` | ObjectId | ✅ | |
| `actorRole` | String | ✅ | Role at time of action |
| `action` | String | ✅ | Dot-notation: `overtime.approved` |
| `module` | String | ✅ | |
| `resourceType` | String | ✅ | |
| `resourceId` | ObjectId | ❌ | |
| `metadata` | Object | ❌ | `{ from, to, changes, reason }` |
| `ipAddress` | String | ❌ | |
| `userAgent` | String | ❌ | |
| `previousHash` | String | ❌ | Hash chain (future tamper detection) |
| `entryHash` | String | ❌ | |
| `createdAt` | Date | ✅ | No updatedAt — immutable |

---

### 8.6 `idempotency_records`

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `_id` | ObjectId | ✅ | |
| `key` | String | ✅ | Unique |
| `userId` | ObjectId | ✅ | |
| `endpoint` | String | ✅ | |
| `responseStatus` | Number | ✅ | |
| `responseBody` | Mixed | ✅ | |
| `createdAt` | Date | ✅ | TTL: 72 hours |

---

## 9. Shared Sub-Schemas

### 9.1 `GpsPoint`

```javascript
{
  latitude:   { type: Number, required: true },
  longitude:  { type: Number, required: true },
  accuracy:   { type: Number, required: true },
  altitude:   { type: Number },
  heading:    { type: Number },
  speed:      { type: Number },
  timestamp:  { type: Date, required: true },
  provider:   { type: String, required: true, enum: ['gps','network','fused','passive'] },
  address:    { type: String }
}
```

### 9.2 `DeviceMetadata`

```javascript
{
  platform:         { type: String, required: true },
  manufacturer:     { type: String, required: true },
  phoneModel:       { type: String, required: true },
  osVersion:        { type: String, required: true },
  appVersion:       { type: String, required: true },
  deviceIdentifier: { type: String, required: true }
}
```

### 9.3 `PhotoRef`

```javascript
{
  url:       { type: String, required: true },
  publicId:  { type: String, required: true },
  uploadedAt:{ type: Date, required: true }
}
```

### 9.4 `OrgSnapshot`

```javascript
{
  companyId:    { type: ObjectId, required: true },
  branchId:     { type: ObjectId, required: true },
  regionId:     { type: ObjectId, required: true },
  cityId:       { type: ObjectId, required: true },
  departmentId: { type: ObjectId, required: true },
  teamId:       { type: ObjectId }
}
```

### 9.5 `TravelMetadata`

```javascript
{
  governorate:            { type: String, required: true },
  destination:            { type: String, required: true },
  travelReason:           { type: String, required: true },
  travelDistanceKm:       { type: Number, required: true },
  estimatedTravelMinutes: { type: Number, required: true },
  actualTravelMinutes:    { type: Number },
  reimbursementAmount:    { type: Number },
  reimbursementCurrency:  { type: String, default: 'IQD' },
  reimbursementStatus:    { type: String, enum: ['PENDING','APPROVED','PAID'] }
}
```

---

## 10. Indexes

### 10.1 `overtime_records`

```javascript
// One RUNNING session per user
{ userId: 1, status: 1 }
  partialFilterExpression: { status: 'RUNNING' }, unique: true

// Review queue
{ companyId: 1, 'organizationSnapshot.departmentId': 1, status: 1, endAt: -1 }

// Reports — monthly by user
{ companyId: 1, userId: 1, status: 1, startAt: 1 }

// Reports — by hierarchy level
{ companyId: 1, 'organizationSnapshot.branchId': 1, startAt: 1 }
{ companyId: 1, 'organizationSnapshot.regionId': 1, startAt: 1 }

// Vehicle reports (future)
{ companyId: 1, vehicleId: 1, startAt: 1 }

// Work order link
{ companyId: 1, workOrderId: 1 }

// Idempotency
{ clientRequestId: 1 }, unique: true

// Global search text
{ jobDescription: 'text', completionNotes: 'text' }
```

### 10.2 Organization

```javascript
// users
{ email: 1 }, unique
{ companyId: 1, employeeId: 1 }, unique
{ companyId: 1, departmentId: 1, isActive: 1 }
{ companyId: 1, lastSeenAt: -1 }  // online/offline dashboard

// work_orders
{ companyId: 1, jobNumber: 'text', jobTitle: 'text' }
```

### 10.3 Platform

```javascript
// audit_logs
{ companyId: 1, createdAt: -1 }
{ companyId: 1, action: 1, createdAt: -1 }

// notifications
{ userId: 1, isRead: 1, createdAt: -1 }

// permissions
{ key: 1 }, unique
```

---

## 11. Aggregation Patterns

### 11.1 Dashboard KPIs

```javascript
// Running overtime count
db.overtime_records.countDocuments({
  companyId, status: 'RUNNING',
  ...(branchId && { 'organizationSnapshot.branchId': branchId })
})

// Today's approved hours
db.overtime_records.aggregate([
  { $match: { companyId, status: 'APPROVED', reviewedAt: { $gte: todayStart, $lt: todayEnd } } },
  { $group: { _id: '$type', totalMinutes: { $sum: '$overtimeMinutes' } } }
])
```

### 11.2 Monthly Report with Hierarchy

```javascript
db.overtime_records.aggregate([
  { $match: { companyId, startAt: { $gte: monthStart, $lt: monthEnd },
      ...(branchId && { 'organizationSnapshot.branchId': ObjectId(branchId) }) } },
  { $group: {
      _id: { userId: '$userId', type: '$type', status: '$status' },
      totalMinutes: { $sum: '$overtimeMinutes' },
      count: { $sum: 1 }
  }},
  { $lookup: { from: 'users', localField: '_id.userId', foreignField: '_id', as: 'employee' } }
])
```

---

## 12. Sample Documents

See [ARCHITECTURE.md](./ARCHITECTURE.md) for overtime calculation examples. Full sample JSON available in `scripts/sample-data/` (Phase 1).

### Overtime Record (Travel, Approved)

```json
{
  "_id": "6888a1b2c3d4e5f6a7b8c9d0",
  "companyId": "6888a1b2c3d4e5f6a7b8c000",
  "userId": "6888a1b2c3d4e5f6a7b8c001",
  "organizationSnapshot": {
    "companyId": "6888a1b2c3d4e5f6a7b8c000",
    "branchId": "6888a1b2c3d4e5f6a7b8c010",
    "regionId": "6888a1b2c3d4e5f6a7b8c011",
    "cityId": "6888a1b2c3d4e5f6a7b8c012",
    "departmentId": "6888a1b2c3d4e5f6a7b8c002",
    "teamId": "6888a1b2c3d4e5f6a7b8c013"
  },
  "type": "TRAVEL",
  "status": "APPROVED",
  "workOrderId": null,
  "vehicleId": "6888a1b2c3d4e5f6a7b8c020",
  "jobDescription": "Emergency server repair — Basra branch",
  "startAt": "2026-07-28T05:00:00.000Z",
  "startGps": {
    "latitude": 33.3152, "longitude": 44.3661,
    "accuracy": 8.5, "altitude": 34.2, "heading": 180,
    "speed": 0, "timestamp": "2026-07-28T05:00:03.000Z",
    "provider": "fused",
    "address": "Al-Karrada, Baghdad, Iraq"
  },
  "startPhoto": {
    "url": "https://res.cloudinary.com/.../6888.../2026/07/6888.../start.jpg",
    "publicId": "6888.../6888.../2026/07/6888.../start",
    "uploadedAt": "2026-07-28T05:00:10.000Z"
  },
  "startDeviceInfo": {
    "platform": "android", "manufacturer": "Samsung",
    "phoneModel": "Galaxy S24", "osVersion": "14",
    "appVersion": "1.0.0", "deviceIdentifier": "abc-123-def"
  },
  "endAt": "2026-07-28T20:00:00.000Z",
  "endGps": { "...": "..." },
  "endPhoto": { "...": "..." },
  "endDeviceInfo": { "...": "..." },
  "travel": {
    "governorate": "Basra",
    "destination": "Basra Tech Center, Al-Ashar",
    "travelReason": "Emergency server failure",
    "travelDistanceKm": 550,
    "estimatedTravelMinutes": 360,
    "actualTravelMinutes": 390
  },
  "rawDurationMinutes": 900,
  "excludedMinutes": 480,
  "overtimeMinutes": 420,
  "overtimeHours": 7.0,
  "calculationVersion": "2.0.0",
  "gpsQuality": "GOOD",
  "reviewedBy": "6888a1b2c3d4e5f6a7b8c030",
  "reviewedAt": "2026-07-29T08:00:00.000Z",
  "clientRequestId": "550e8400-e29b-41d4-a716-446655440000",
  "syncStatus": "SYNCED",
  "createdAt": "2026-07-28T05:00:10.000Z",
  "updatedAt": "2026-07-29T08:00:00.000Z"
}
```
