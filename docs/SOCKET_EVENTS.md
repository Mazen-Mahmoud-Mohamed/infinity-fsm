# Socket.IO Events Specification

**Product:** Infinity FSM Platform  
**Version:** 2.0.0  

---

## Connection & Authentication

Unchanged from v1.0 with additions:
- JWT payload includes `roleIds` (permissions loaded server-side)
- Rooms extended for hierarchy levels

### Room Strategy (Updated)

| Room | Members | Purpose |
|------|---------|---------|
| `user:{userId}` | Single user | Personal notifications |
| `company:{companyId}` | All company users | Broadcasts |
| `branch:{branchId}` | Branch members | Branch-scoped events |
| `department:{departmentId}` | Dept members + supervisors | Review queue |
| `supervisors:{companyId}` | Supervisors + admins | Review updates |
| `technicians:{companyId}` | Technicians | Field alerts |
| `online:{companyId}` | Currently connected users | Presence tracking |

### Presence Tracking (New)

On connect: set `users.lastSeenAt`, emit to `online:{companyId}`.  
On disconnect: update `lastSeenAt`, emit offline event.  
Dashboard uses this for online/offline technician counts.

---

## Server → Client Events (Updated)

### Overtime Events

| Event | Target | Trigger | MVP |
|-------|--------|---------|-----|
| `overtime:started` | `department:{id}` | RUNNING state entered | ✅ |
| `overtime:ended` | `supervisors:{companyId}` | → PENDING_REVIEW | ✅ |
| `overtime:approved` | `user:{userId}` | → APPROVED | ✅ |
| `overtime:rejected` | `user:{userId}` | → REJECTED | ✅ |
| `overtime:archived` | `user:{userId}` | → ARCHIVED | ✅ |
| `overtime:cancelled` | `user:{userId}` | RUNNING → DRAFT | ✅ |

### `overtime:started` Payload (Updated)

```json
{
  "event": "overtime:started",
  "data": {
    "overtimeId": "...",
    "userId": "...",
    "employeeName": "Ahmed Hassan",
    "type": "TRAVEL",
    "status": "RUNNING",
    "jobDescription": "Emergency repair — Basra",
    "workOrderId": null,
    "vehicleId": "6888...",
    "organizationSnapshot": { "branchId": "...", "departmentId": "..." },
    "startAt": "2026-07-29T05:00:00.000Z"
  },
  "timestamp": "2026-07-29T05:00:05.000Z"
}
```

### Dashboard Events (New)

| Event | Target | Trigger |
|-------|--------|---------|
| `dashboard:kpi-updated` | `supervisors:{companyId}` | Any KPI changes |
| `dashboard:technician-online` | `supervisors:{companyId}` | Technician connects |
| `dashboard:technician-offline` | `supervisors:{companyId}` | Technician disconnects |

### `dashboard:kpi-updated` Payload

```json
{
  "event": "dashboard:kpi-updated",
  "data": {
    "changedKpis": ["running", "pendingReview"],
    "scope": { "companyId": "...", "branchId": "..." },
    "values": {
      "running": 13,
      "pendingReview": 8
    }
  },
  "timestamp": "2026-07-29T13:00:00.000Z"
}
```

### Platform Events (New)

| Event | Target | Trigger |
|-------|--------|---------|
| `config:settings-changed` | `company:{companyId}` | Admin updates settings |
| `config:module-enabled` | `company:{companyId}` | Module activated |

---

## Client → Server Events (Updated)

| Event | Emitter | Purpose |
|-------|---------|---------|
| `notification:read` | Any | Mark notification read |
| `overtime:subscribe-review` | Supervisor+ | Join review room |
| `overtime:unsubscribe-review` | Supervisor+ | Leave review room |
| `dashboard:subscribe` | Supervisor+ | Join dashboard KPI room |
| `dashboard:unsubscribe` | Supervisor+ | Leave dashboard room |
| `presence:heartbeat` | Any | Update lastSeenAt (every 60s) |
| `sync:request-status` | Any | Request sync state |
| `ping` | Any | Connection health check |

---

## Future Module Events (Reserved)

| Event | Module | State |
|-------|--------|-------|
| `work_order:assigned` | Work Orders | SCHEMA_READY |
| `work_order:completed` | Work Orders | SCHEMA_READY |
| `vehicle:assigned` | Vehicles | SCHEMA_READY |
| `attendance:clock_in` | Attendance | PLANNED |
| `schedule:updated` | Scheduling | PLANNED |

---

## Event Catalog Summary

**MVP events:** 16 server→client, 8 client→server  
**Total catalog (including future):** 25 server→client, 10 client→server

See v1.0 sections for connection lifecycle, error handling, reconnection strategy, and scaling considerations — all remain valid.
