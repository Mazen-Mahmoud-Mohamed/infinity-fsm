# RBAC — Roles & Permissions Specification

**Product:** Infinity FSM Platform  
**Version:** 2.0.0  

---

## Table of Contents

1. [Authorization Model](#1-authorization-model)
2. [Default Roles](#2-default-roles)
3. [Permission Catalog](#3-permission-catalog)
4. [Role-Permission Matrix](#4-role-permission-matrix)
5. [Scope Rules](#5-scope-rules)
6. [Permission Overrides](#6-permission-overrides)
7. [Implementation Guidelines](#7-implementation-guidelines)

---

## 1. Authorization Model

```
User
 ├── roleIds[] ──▶ Role ──▶ permissionIds[] ──▶ Permission
 └── permissionOverrides[] ──▶ { permission, type: grant|deny }
```

**Authorization check order:**
1. Collect all permissions from user's roles.
2. Apply direct grants (add permission).
3. Apply direct denies (remove permission — deny wins).
4. Check scope (company/branch/department/self).
5. Allow or deny.

**Permission key format:** `{module}:{action}`  
Examples: `overtime:approve`, `reports:export`, `organization:manage_users`

---

## 2. Default Roles

| Role | Slug | Scope | Description |
|------|------|-------|-------------|
| **Admin** | `admin` | Company | Full company management |
| **Supervisor** | `supervisor` | Branch/Department | Review overtime, view team reports |
| **Technician** | `technician` | Self | Start/end own overtime |
| **HR** | `hr` | Company (read) | View reports, export — no approval (future) |

Roles are stored in `roles` collection. System roles (`isSystem: true`) cannot be deleted. Companies can create custom roles by combining permissions.

---

## 3. Permission Catalog

### 3.1 Authentication

| Key | Description |
|-----|-------------|
| `auth:login` | Authenticate (implicit — all users) |

### 3.2 Overtime

| Key | Description |
|-----|-------------|
| `overtime:view_own` | View own overtime records |
| `overtime:view_team` | View team overtime records |
| `overtime:view_all` | View all company overtime |
| `overtime:create` | Create draft overtime |
| `overtime:start` | Start running overtime |
| `overtime:end` | End running overtime |
| `overtime:cancel` | Cancel running overtime |
| `overtime:approve` | Approve pending overtime |
| `overtime:reject` | Reject pending overtime |
| `overtime:archive` | Archive approved/rejected records |

### 3.3 Work Orders (Schema-Ready)

| Key | Description |
|-----|-------------|
| `work_orders:view_own` | View assigned work orders |
| `work_orders:view_team` | View team work orders |
| `work_orders:view_all` | View all work orders |
| `work_orders:create` | Create work orders |
| `work_orders:update` | Update work orders |
| `work_orders:assign` | Assign technician |
| `work_orders:complete` | Mark completed |
| `work_orders:cancel` | Cancel work order |

### 3.4 Organization

| Key | Description |
|-----|-------------|
| `organization:view` | View org hierarchy |
| `organization:manage_branches` | CRUD branches |
| `organization:manage_regions` | CRUD regions |
| `organization:manage_cities` | CRUD cities |
| `organization:manage_departments` | CRUD departments |
| `organization:manage_teams` | CRUD teams |
| `organization:manage_users` | CRUD users |
| `organization:assign_roles` | Assign roles to users |

### 3.5 Vehicles (Schema-Ready)

| Key | Description |
|-----|-------------|
| `vehicles:view` | View vehicles |
| `vehicles:manage` | CRUD vehicles |
| `vehicles:assign` | Assign vehicle to technician |

### 3.6 Reports

| Key | Description |
|-----|-------------|
| `reports:view_own` | View own reports |
| `reports:view_team` | View team/department reports |
| `reports:view_all` | View all company reports |
| `reports:export` | Export reports (PDF/Excel/CSV) |

### 3.7 Dashboard

| Key | Description |
|-----|-------------|
| `dashboard:view` | View dashboard KPIs |
| `dashboard:view_company` | View company-wide KPIs |

### 3.8 Settings

| Key | Description |
|-----|-------------|
| `settings:view` | View company settings |
| `settings:manage` | Update company settings |
| `settings:manage_holidays` | Manage holiday calendar |

### 3.9 Search

| Key | Description |
|-----|-------------|
| `search:global` | Use global search |

### 3.10 Audit

| Key | Description |
|-----|-------------|
| `audit:view` | View audit logs |

### 3.11 Notifications

| Key | Description |
|-----|-------------|
| `notifications:view` | View own notifications |
| `notifications:manage_templates` | Manage notification templates |
| `notifications:broadcast` | Send company announcements |

### 3.12 RBAC Management

| Key | Description |
|-----|-------------|
| `rbac:manage_roles` | Create/edit custom roles |
| `rbac:manage_permissions` | Grant/revoke permission overrides |

---

## 4. Role-Permission Matrix

| Permission | Admin | Supervisor | Technician | HR (future) |
|------------|:-----:|:----------:|:----------:|:-----------:|
| **Overtime** | | | | |
| `overtime:view_own` | ✅ | ✅ | ✅ | ✅ |
| `overtime:view_team` | ✅ | ✅ | ❌ | ✅ |
| `overtime:view_all` | ✅ | ❌ | ❌ | ✅ |
| `overtime:create` | ❌ | ❌ | ✅ | ❌ |
| `overtime:start` | ❌ | ❌ | ✅ | ❌ |
| `overtime:end` | ❌ | ❌ | ✅ | ❌ |
| `overtime:cancel` | ❌ | ❌ | ✅ | ❌ |
| `overtime:approve` | ✅ | ✅ | ❌ | ❌ |
| `overtime:reject` | ✅ | ✅ | ❌ | ❌ |
| `overtime:archive` | ✅ | ❌ | ❌ | ❌ |
| **Organization** | | | | |
| `organization:view` | ✅ | ✅ | ❌ | ✅ |
| `organization:manage_*` | ✅ | ❌ | ❌ | ❌ |
| `organization:manage_users` | ✅ | ❌ | ❌ | ❌ |
| `organization:assign_roles` | ✅ | ❌ | ❌ | ❌ |
| **Reports** | | | | |
| `reports:view_own` | ✅ | ✅ | ✅ | ✅ |
| `reports:view_team` | ✅ | ✅ | ❌ | ✅ |
| `reports:view_all` | ✅ | ❌ | ❌ | ✅ |
| `reports:export` | ✅ | ✅ | ❌ | ✅ |
| **Dashboard** | | | | |
| `dashboard:view` | ✅ | ✅ | ❌ | ✅ |
| `dashboard:view_company` | ✅ | ❌ | ❌ | ✅ |
| **Settings** | | | | |
| `settings:view` | ✅ | ❌ | ❌ | ❌ |
| `settings:manage` | ✅ | ❌ | ❌ | ❌ |
| `settings:manage_holidays` | ✅ | ❌ | ❌ | ❌ |
| **Other** | | | | |
| `search:global` | ✅ | ✅ | ❌ | ✅ |
| `audit:view` | ✅ | ❌ | ❌ | ❌ |
| `notifications:view` | ✅ | ✅ | ✅ | ✅ |
| `notifications:broadcast` | ✅ | ❌ | ❌ | ❌ |
| `rbac:manage_roles` | ✅ | ❌ | ❌ | ❌ |
| `vehicles:view` | ✅ | ✅ | ❌ | ❌ |
| `vehicles:manage` | ✅ | ❌ | ❌ | ❌ |
| `work_orders:*` | ✅ | ✅ | view_own | ❌ |

---

## 5. Scope Rules

Permissions are further constrained by **data scope**:

| Role | Data Scope | Implementation |
|------|-----------|----------------|
| **Technician** | Own records only | Filter: `userId = req.user.id` |
| **Supervisor** | Own branch/department | Filter: `organizationSnapshot.departmentId IN user.managedDepartments` OR `organizationSnapshot.branchId = user.branchId` |
| **Admin** | Entire company | Filter: `companyId = req.user.companyId` |
| **HR** | Entire company (read-only) | Filter: `companyId = req.user.companyId`, no write permissions |

Scope is enforced in **repository layer**, not just controller. Even if a technician crafts a request with another user's ID, the repository query includes scope filters.

### 5.1 Supervisor Scope Configuration

Supervisors can be scoped to:
- Specific department(s) via `departments.supervisorIds`
- Entire branch (all departments in branch)

Stored on user record or derived from role assignment metadata.

---

## 6. Permission Overrides

Direct user-level overrides for exceptional cases:

```javascript
// Grant extra permission to a specific user
{ permission: 'reports:export', type: 'grant' }

// Deny permission even if role includes it
{ permission: 'overtime:approve', type: 'deny' }
```

**Deny always wins over grant.** Overrides are audit-logged.

---

## 7. Implementation Guidelines

### 7.1 Middleware

```javascript
// Usage in routes
router.post('/:id/approve',
  authenticate,
  requirePermission('overtime:approve'),
  scopeToRecord('overtime'),
  overtimeController.approve
);
```

### 7.2 Permission Caching

User permissions cached in memory (per request) and Redis (cross-request, TTL 5 min). Invalidated on role/permission change.

### 7.3 JWT Payload

JWT contains minimal data — permissions are loaded from DB/cache on each request:

```javascript
{
  sub: userId,
  companyId,
  roleIds: [...],
  // NOT permissions — loaded server-side
}
```

### 7.4 Flutter Client

Client receives user permissions in `/auth/me` response for UI rendering (show/hide buttons). **Server always re-validates** — client permissions are cosmetic only.

```javascript
// Client uses permissions for UI only
if (user.hasPermission('overtime:approve')) {
  showApproveButton();
}
```

### 7.5 Testing Requirements

Every permission must have tests verifying:
- Authorized user succeeds.
- Unauthorized user receives 403.
- Wrong scope receives 403 even with correct permission.
- Deny override blocks despite role grant.

See [TESTING.md](./TESTING.md).
