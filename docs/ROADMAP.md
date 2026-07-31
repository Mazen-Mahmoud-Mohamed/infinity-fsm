# Development Roadmap

**Product:** Infinity FSM Platform  
**Version:** 2.0.0  
**Estimated Duration:** 20–24 weeks  
**Team:** 2 backend, 2 Flutter, 1 QA, 1 DevOps (part-time)  

---

## Phase Overview

```
Phase 0 ──▶ Phase 1 ──▶ Phase 2 ──▶ Phase 3 ──▶ Phase 4 ──▶ Phase 5 ──▶ Phase 6
Arch &       Platform    Overtime     Offline      Admin &      Production   Future
Testing      Core        MVP          Sync         Reports      Hardening    Modules
(2 wks)      (4 wks)     (4 wks)      (3 wks)      (4 wks)      (3 wks)      (ongoing)
```

> **Key change from v1.0:** Testing infrastructure built in Phase 0, not deferred. Organization hierarchy and RBAC built in Phase 1 before any business logic.

---

## Phase 0: Architecture & Testing Foundation (Weeks 1–2)

**Goal:** Testing infrastructure, CI pipeline, schema migration tooling.

### Tasks

| # | Task | Priority |
|---|------|----------|
| 0.1 | Finalize architecture documents (this deliverable) | P0 |
| 0.2 | Initialize backend project with Jest + Supertest | P0 |
| 0.3 | Configure mongodb-memory-server for integration tests | P0 |
| 0.4 | Initialize Flutter project with flutter_test + bloc_test | P0 |
| 0.5 | CI pipeline: lint + unit tests on PR | P0 |
| 0.6 | Coverage reporting with thresholds (see TESTING.md) | P0 |
| 0.7 | Schema migration tooling setup | P0 |
| 0.8 | Seed scripts: permissions, roles, default company | P0 |
| 0.9 | Overtime calculator unit tests (TDD — tests before impl) | P0 |
| 0.10 | State machine unit tests (TDD) | P0 |
| 0.11 | RBAC permission matrix tests (TDD) | P0 |
| 0.12 | Docker Compose (API + MongoDB) | P0 |
| 0.13 | Test fixtures and factory pattern | P1 |

### Deliverables

- [ ] CI pipeline runs on every PR
- [ ] Calculator tests exist (initially failing — TDD)
- [ ] State machine tests exist (initially failing — TDD)
- [ ] RBAC tests exist (initially failing — TDD)
- [ ] Docker Compose starts MongoDB
- [ ] Seed script creates default permissions + roles

### Exit Criteria

- `npm test` and `flutter test` run in CI
- Coverage reporting active
- All architecture documents reviewed and approved

---

## Phase 1: Platform Core (Weeks 3–6)

**Goal:** Auth, RBAC, full organization hierarchy, configuration, audit.

### Backend

| # | Task | Priority |
|---|------|----------|
| 1.1 | Express app bootstrap + middleware stack | P0 |
| 1.2 | MongoDB connection + health checks | P0 |
| 1.3 | Auth module: login, refresh, logout | P0 |
| 1.4 | RBAC module: roles, permissions, middleware | P0 |
| 1.5 | Organization: companies, branches, regions, cities | P0 |
| 1.6 | Organization: departments, teams | P0 |
| 1.7 | Users CRUD with hierarchy placement | P0 |
| 1.8 | Configuration module: settings CRUD | P0 |
| 1.9 | Holidays management | P1 |
| 1.10 | Audit log module (append-only) | P0 |
| 1.11 | Platform modules endpoint | P1 |
| 1.12 | Integration tests for all Phase 1 endpoints | P0 |
| 1.13 | RBAC tests: every permission gate verified | P0 |

### Flutter

| # | Task | Priority |
|---|------|----------|
| 1.14 | Flutter project init (Android, iOS, Windows) | P0 |
| 1.15 | Clean Architecture folder structure | P0 |
| 1.16 | DI setup (get_it + injectable) | P0 |
| 1.17 | API client (Dio) + auth interceptor | P0 |
| 1.18 | Secure token storage | P0 |
| 1.19 | Login screen + auth BLoC | P0 |
| 1.20 | Role-based routing (go_router) | P0 |
| 1.21 | Permission helper for UI gating | P0 |
| 1.22 | Theme + shared widgets | P1 |

### Deliverables

- [ ] Full org hierarchy CRUD via API
- [ ] RBAC enforced on every endpoint
- [ ] Login works on all 3 platforms
- [ ] Admin can create users with hierarchy placement
- [ ] Settings configurable via API
- [ ] All actions audit-logged

---

## Phase 2: Overtime MVP (Weeks 7–10)

**Goal:** Complete overtime workflow with extended GPS, travel, state machine.

### Backend

| # | Task | Priority |
|---|------|----------|
| 2.1 | Overtime model with full schema (GPS, device, travel) | P0 |
| 2.2 | Overtime calculator implementation (pass Phase 0 tests) | P0 |
| 2.3 | State machine implementation (pass Phase 0 tests) | P0 |
| 2.4 | Start/end/cancel/approve/reject/archive endpoints | P0 |
| 2.5 | Cloudinary signed upload with folder convention | P0 |
| 2.6 | Maps reverse geocoding | P0 |
| 2.7 | Idempotency middleware | P0 |
| 2.8 | Work order link (optional workOrderId) | P1 |
| 2.9 | Vehicle link (optional vehicleId) | P1 |
| 2.10 | Socket.IO overtime events | P0 |
| 2.11 | Notification creation on state changes | P0 |
| 2.12 | GPS validation (accuracy threshold, zero coords) | P0 |
| 2.13 | Integration tests: full lifecycle | P0 |
| 2.14 | GPS validation test suite | P0 |

### Flutter

| # | Task | Priority |
|---|------|----------|
| 2.15 | Camera service (camera-only) | P0 |
| 2.16 | Extended GPS capture service | P0 |
| 2.17 | Device info service | P0 |
| 2.18 | Cloudinary direct upload | P0 |
| 2.19 | Start overtime screen (type, travel fields, photo) | P0 |
| 2.20 | End overtime screen | P0 |
| 2.21 | Running overtime dashboard + timer | P0 |
| 2.22 | Overtime history list | P1 |
| 2.23 | Map widget (start/end pins) | P1 |
| 2.24 | Socket.IO client | P1 |

### Deliverables

- [ ] Full overtime lifecycle with 6 states
- [ ] Travel overtime with extended metadata
- [ ] Extended GPS + device info captured
- [ ] Cloudinary folder convention enforced
- [ ] All calculator + state machine tests pass
- [ ] E2E: login → start → end on Android

---

## Phase 3: Offline Sync (Weeks 11–13)

**Goal:** Full offline-first with crash recovery.

### Backend

| # | Task | Priority |
|---|------|----------|
| 3.1 | Sync batch endpoint | P0 |
| 3.2 | Sync status endpoint | P0 |
| 3.3 | Enhanced idempotency for batch | P0 |

### Flutter

| # | Task | Priority |
|---|------|----------|
| 3.4 | Hive active session persistence | P0 |
| 3.5 | SQLite sync queue (drift) | P0 |
| 3.6 | Sync queue manager (priority ordering) | P0 |
| 3.7 | Connectivity monitor | P0 |
| 3.8 | Offline start/end (DRAFT → sync → RUNNING) | P0 |
| 3.9 | Background sync worker | P0 |
| 3.10 | Crash recovery + session recovery | P0 |
| 3.11 | Photo queue (upload before API) | P0 |
| 3.12 | Offline indicator UI | P1 |
| 3.13 | Windows sync scheduler | P1 |

### Testing

| # | Task | Priority |
|---|------|----------|
| 3.14 | Offline sync test suite (see TESTING.md) | P0 |
| 3.15 | Airplane mode E2E test | P0 |
| 3.16 | App kill recovery E2E test | P0 |
| 3.17 | Idempotency replay tests | P0 |

### Deliverables

- [ ] Full offline overtime workflow
- [ ] Zero data loss verified by test suite
- [ ] Crash recovery works on all platforms

---

## Phase 4: Dashboard, Reports, Admin UI (Weeks 14–17)

**Goal:** Supervisor/admin workflows, reporting, search.

### Backend

| # | Task | Priority |
|---|------|----------|
| 4.1 | Dashboard KPI aggregation | P0 |
| 4.2 | Technician online/offline tracking | P0 |
| 4.3 | Unified report endpoint (all dimensions) | P0 |
| 4.4 | CSV export | P0 |
| 4.5 | Global search (MongoDB text indexes) | P0 |
| 4.6 | Work orders schema seed (no UI) | P1 |
| 4.7 | Vehicles schema seed (no UI) | P1 |

### Flutter

| # | Task | Priority |
|---|------|----------|
| 4.8 | Dashboard screen with KPIs | P0 |
| 4.9 | Review queue + detail + approve/reject | P0 |
| 4.10 | Monthly/daily/weekly report screens | P0 |
| 4.11 | Report export (CSV) | P0 |
| 4.12 | Global search screen | P1 |
| 4.13 | Admin: org hierarchy management | P1 |
| 4.14 | Admin: user management | P1 |
| 4.15 | Admin: settings + holidays | P1 |
| 4.16 | Admin: audit log viewer | P2 |
| 4.17 | Notification center | P1 |

### Deliverables

- [ ] Dashboard with all specified KPIs
- [ ] Reports filterable by all hierarchy levels
- [ ] Global search across entities
- [ ] All three roles functional on all platforms

---

## Phase 5: Production Hardening (Weeks 18–20)

| # | Task | Priority |
|---|------|----------|
| 5.1 | Security test suite (OWASP, RBAC bypass) | P0 |
| 5.2 | Load testing (k6, 500+ concurrent) | P0 |
| 5.3 | MongoDB index optimization | P0 |
| 5.4 | Sentry error monitoring | P0 |
| 5.5 | Structured logging + aggregation | P0 |
| 5.6 | Production deployment (Docker + Nginx + TLS) | P0 |
| 5.7 | MongoDB Atlas production cluster | P0 |
| 5.8 | Redis (Socket.IO adapter + cache) | P1 |
| 5.9 | Firebase Crashlytics (mobile) | P0 |
| 5.10 | App signing (Android, iOS, Windows) | P0 |
| 5.11 | E2E suite all platforms | P0 |
| 5.12 | PDF/Excel export | P1 |
| 5.13 | Push notifications (FCM) | P1 |
| 5.14 | DR runbook + backup verification | P0 |
| 5.15 | Performance benchmarking vs NFR targets | P0 |

### Deliverables

- [ ] Production deployed
- [ ] Security audit passed
- [ ] Load test passed
- [ ] App store submission ready

---

## Phase 6: Future Business Modules (Ongoing)

See [MODULE_REGISTRY.md](./MODULE_REGISTRY.md) and [FUTURE_IMPROVEMENTS.md](./FUTURE_IMPROVEMENTS.md).

| Module | Estimated Effort | Priority |
|--------|-----------------|----------|
| Work Orders (full UI) | 4 weeks | High |
| Vehicles (full UI) | 2 weeks | Medium |
| Attendance | 4 weeks | High |
| Web Admin Dashboard | 6 weeks | High |
| Payroll Integration | 3 weeks | High |
| Scheduling | 6 weeks | Medium |
| Analytics | 4 weeks | Medium |

---

## Testing Integration Across Phases

| Phase | Testing Milestone |
|-------|-------------------|
| 0 | CI pipeline, TDD tests written, coverage tracking |
| 1 | Auth + RBAC integration tests, 80% coverage |
| 2 | Calculator + GPS + lifecycle tests, E2E start/end |
| 3 | Full offline sync test suite, crash recovery E2E |
| 4 | Report accuracy tests, search tests, role E2E |
| 5 | Security suite, load tests, all-platform E2E |

---

## Risk Register

| Risk | Impact | Mitigation |
|------|--------|------------|
| Org hierarchy complexity | High | Snapshot pattern; extensive seed data testing |
| RBAC scope bugs | High | Dedicated test matrix; repository-layer enforcement |
| Offline sync edge cases | High | Specialized test suite from Phase 0 design |
| Scope creep into Work Orders MVP | Medium | Schema-ready only; strict MVP boundary |
| 6-level hierarchy UI complexity | Medium | Tree component built early in Phase 1 |
| Extended GPS not available on all devices | Low | Graceful degradation; optional fields |

---

## Milestone Timeline

```
Week:  1   2   3   4   5   6   7   8   9  10  11  12  13  14  15  16  17  18  19  20
       ├─ Phase 0 ─┤
                   ├──── Phase 1 ────┤
                                   ├──── Phase 2 ────┤
                                                   ├─ Phase 3 ─┤
                                                               ├──── Phase 4 ────┤
                                                                               ├─ Ph 5 ─┤

Milestones:
  ◆ Week 2:  Testing infra + TDD tests ready
  ◆ Week 6:  Platform core complete (auth, RBAC, org, config)
  ◆ Week 10: Overtime MVP complete
  ◆ Week 13: Offline sync verified
  ◆ Week 17: Dashboard, reports, admin UI complete
  ◆ Week 20: Production deployment
```
