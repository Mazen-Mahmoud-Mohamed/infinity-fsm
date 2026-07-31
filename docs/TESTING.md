# Testing Architecture

**Product:** Infinity FSM Platform  
**Version:** 2.0.0  
**Policy:** Testing is designed from day one — not deferred to later phases.

---

## Table of Contents

1. [Testing Philosophy](#1-testing-philosophy)
2. [Test Pyramid](#2-test-pyramid)
3. [Backend Testing](#3-backend-testing)
4. [Flutter Testing](#4-flutter-testing)
5. [End-to-End Testing](#5-end-to-end-testing)
6. [Specialized Test Suites](#6-specialized-test-suites)
7. [CI/CD Integration](#7-cicd-integration)
8. [Coverage Requirements](#8-coverage-requirements)
9. [Test Data Management](#9-test-data-management)
10. [Test Environments](#10-test-environments)

---

## 1. Testing Philosophy

1. **Test behavior, not implementation** — Tests verify outcomes, not internal method calls.
2. **Domain logic first** — Highest coverage on business rules (calculations, state machines, RBAC).
3. **No untested permissions** — Every permission gate has explicit allow/deny tests.
4. **Offline sync is critical path** — Dedicated test suite, not an afterthought.
5. **CI blocks on failure** — No merge with failing tests or coverage drop.
6. **Tests are documentation** — Test names describe business rules.

---

## 2. Test Pyramid

```
                    ┌───────────┐
                    │    E2E    │  ~10%  — Full user journeys
                    ├───────────┤
                    │ Integration│  ~25%  — API, DB, sync
                    ├───────────┤
                    │   Unit    │  ~65%  — Domain, validators, utils
                    └───────────┘
```

| Layer | Count Target (MVP) | Run Time |
|-------|-------------------|----------|
| Unit | 300+ tests | < 30s |
| Integration | 100+ tests | < 2min |
| E2E | 20+ scenarios | < 15min |
| Load | 5+ scenarios | < 10min (nightly) |
| Security | 20+ checks | < 5min (nightly) |

---

## 3. Backend Testing

### 3.1 Unit Tests

**Framework:** Jest  
**Location:** `backend/src/modules/{module}/__tests__/`

| Test Suite | Priority | Description |
|------------|----------|-------------|
| `overtime-calculator.test.js` | P0 | All business rule examples + edge cases |
| `overtime-state-machine.test.js` | P0 | Every valid/invalid transition |
| `working-hours.policy.test.js` | P0 | Holiday exclusion, timezone handling |
| `rbac.service.test.js` | P0 | Permission checks, scope, overrides |
| `travel-metadata.validator.test.js` | P0 | Travel field validation |
| `gps.validator.test.js` | P0 | GPS quality flags, invalid coordinates |
| `idempotency.service.test.js` | P0 | Duplicate detection, TTL |
| `sync-batch.processor.test.js` | P0 | Ordered processing, partial failure |
| `report-aggregator.test.js` | P1 | Monthly/daily aggregation math |
| `dashboard-kpi.test.js` | P1 | KPI calculation accuracy |
| `cloudinary-path.test.js` | P1 | Folder path construction |
| `notification-renderer.test.js` | P2 | Template variable substitution |

#### Overtime Calculator Test Cases (Mandatory)

| # | Start | End | Expected OT | Notes |
|---|-------|-----|-------------|-------|
| 1 | 16:30 | 18:30 | 1h 30m | Partial evening |
| 2 | 07:00 | 10:00 | 2h 00m | Morning + partial official |
| 3 | 07:00 | 20:00 | 5h 00m | Full day span |
| 4 | 06:00 | 08:00 | 2h 00m | Pure morning |
| 5 | 18:00 | 22:00 | 4h 00m | Pure evening |
| 6 | 22:00 (Mon) | 10:00 (Tue) | 5h 00m | Overnight |
| 7 | 07:00 | 17:00 | 0h 00m | Exact official hours |
| 8 | 09:00 | 17:00 | 0h 00m | Full official day |
| 9 | 07:00 | 20:00 + holiday | 12h 00m | Holiday = full day OT |
| 10 | 07:00 | 20:00 | 5h 00m | Different timezone (UTC+3) |

### 3.2 Integration Tests

**Framework:** Jest + Supertest + mongodb-memory-server  
**Location:** `backend/src/__tests__/integration/`

| Test Suite | Description |
|------------|-------------|
| `auth.integration.test.js` | Login, refresh, logout, token expiry |
| `overtime-lifecycle.integration.test.js` | Full start → end → approve flow |
| `overtime-rbac.integration.test.js` | Permission enforcement per role |
| `overtime-reject.integration.test.js` | Rejection with reason validation |
| `sync-batch.integration.test.js` | Batch sync with idempotency |
| `reports.integration.test.js` | Monthly report accuracy |
| `dashboard.integration.test.js` | KPI endpoint responses |
| `search.integration.test.js` | Global search across entities |
| `settings.integration.test.js` | Settings CRUD + audit |
| `organization.integration.test.js` | Hierarchy CRUD + user placement |
| `audit-log.integration.test.js` | Immutability verification |

### 3.3 Repository Tests

**Framework:** Jest + mongodb-memory-server  
**Location:** `backend/src/modules/{module}/__tests__/`

Test Mongoose queries with real in-memory MongoDB:
- Index enforcement (unique RUNNING session)
- Scope filtering (supervisor sees only dept)
- Pagination correctness
- Aggregation pipeline output

### 3.4 API Tests

Every endpoint in [API.md](./API.md) must have tests covering:
- ✅ Happy path (200/201)
- ✅ Validation errors (400)
- ✅ Unauthorized (401)
- ✅ Forbidden (403) — wrong role AND wrong scope
- ✅ Not found (404)
- ✅ Conflict (409) — active session exists
- ✅ Business rule violation (422)
- ✅ Idempotency — duplicate request returns same response

---

## 4. Flutter Testing

### 4.1 Unit Tests

**Framework:** flutter_test + bloc_test + mocktail  
**Location:** `mobile/test/`

| Test Suite | Description |
|------------|-------------|
| `overtime_bloc_test.dart` | Start/end state transitions |
| `active_overtime_cubit_test.dart` | Session recovery logic |
| `sync_queue_manager_test.dart` | Queue ordering, retry logic |
| `login_usecase_test.dart` | Auth flow |
| `permission_helper_test.dart` | UI permission checks |
| `gps_capture_test.dart` | GPS data assembly |
| `offline_indicator_test.dart` | Connectivity state |

### 4.2 Widget Tests

**Location:** `mobile/test/widgets/`

| Widget | Tests |
|--------|-------|
| `StartOvertimeScreen` | Form validation, type selector, camera trigger |
| `EndOvertimeScreen` | Photo required, notes optional |
| `OvertimeDashboard` | Shows RUNNING state, timer |
| `ReviewQueueScreen` | Lists pending, approve/reject buttons |
| `LoginScreen` | Form validation, error display |
| `OfflineIndicator` | Shows/hides based on connectivity |
| `MonthlyReportScreen` | Data rendering, empty state |

### 4.3 Repository Tests (Flutter)

Test data layer with mocked remote/local datasources:
- Offline start saves to local + queue
- Sync processes queue in order
- Active session restored from Hive on launch

---

## 5. End-to-End Testing

**Framework:** `integration_test` (Flutter official) + Patrol (optional)  
**Location:** `mobile/integration_test/` and `tests/e2e/`

### 5.1 Critical User Journeys

| # | Journey | Platform | Phase |
|---|---------|----------|-------|
| 1 | Login → Start OT → End OT → See pending | Android | 2 |
| 2 | Supervisor login → Review → Approve | Android | 4 |
| 3 | Supervisor login → Review → Reject with reason | Android | 4 |
| 4 | Start OT offline → End OT offline → Sync online | Android | 3 |
| 5 | Start OT → Kill app → Reopen → End OT | Android | 3 |
| 6 | Login → View monthly report → Export CSV | Android | 4 |
| 7 | Admin → Create user → Assign role | Android | 4 |
| 8 | Travel OT with extended fields | Android | 2 |
| 9 | Full lifecycle on iOS | iOS | 5 |
| 10 | Full lifecycle on Windows | Windows | 5 |

### 5.2 E2E Test Environment

- Dedicated test company seeded before suite.
- Test users for each role pre-created.
- Backend running against test MongoDB instance.
- Cloudinary test cloud (or mocked upload).

---

## 6. Specialized Test Suites

### 6.1 Overtime Calculation Tests

Dedicated suite run on every PR touching domain logic.

```
tests/specialized/overtime-calculator/
├── same-day.test.js
├── multi-day.test.js
├── holiday-exclusion.test.js
├── timezone.test.js
├── edge-cases.test.js
└── business-examples.test.js    # All requirement examples
```

### 6.2 GPS Validation Tests

```
tests/specialized/gps/
├── accuracy-threshold.test.js
├── zero-coordinates.test.js
├── missing-fields.test.js
├── provider-types.test.js
└── timestamp-drift.test.js
```

### 6.3 Offline Synchronization Tests

```
tests/specialized/offline-sync/
├── queue-ordering.test.js
├── idempotency.test.js
├── photo-upload-before-api.test.js
├── partial-batch-failure.test.js
├── crash-recovery.test.js
├── conflict-resolution.test.js
├── retention-policy.test.js
└── airplane-mode-e2e.test.js
```

### 6.4 Security Tests

**Framework:** Custom scripts + OWASP ZAP (nightly)  
**Location:** `tests/security/`

| Test | Description |
|------|-------------|
| JWT tampering | Modified token rejected |
| Expired token | 401 returned |
| RBAC bypass | Technician cannot approve |
| Scope bypass | Supervisor cannot view other dept |
| SQL/NoSQL injection | Malicious input sanitized |
| Rate limiting | 429 after threshold |
| CORS | Unauthorized origin blocked |
| Idempotency replay | Same key, same response |
| Audit immutability | Update/delete audit fails |
| Cross-tenant access | Company A cannot see Company B |

### 6.5 Load Tests

**Framework:** k6  
**Location:** `tests/load/`

| Scenario | Target | Duration |
|----------|--------|----------|
| Login burst | 100 concurrent logins | 1 min |
| Overtime start/end | 200 concurrent technicians | 5 min |
| Dashboard load | 50 supervisors polling | 5 min |
| Report generation | 20 concurrent monthly reports | 2 min |
| Search | 100 concurrent queries | 2 min |
| Socket connections | 500 concurrent WebSockets | 5 min |

**Pass criteria:** p95 < 300ms, error rate < 0.1%, no memory leaks.

---

## 7. CI/CD Integration

### 7.1 Pull Request Pipeline

```yaml
on: pull_request
jobs:
  lint:          # ESLint + Prettier + Dart analyze
  unit-tests:    # Jest + flutter test (unit + widget)
  integration:   # Supertest + mongodb-memory-server
  calc-tests:    # Overtime calculator (mandatory pass)
  rbac-tests:    # Permission matrix verification
  coverage:      # Fail if below threshold
```

### 7.2 Merge to Develop

```yaml
on: push to develop
jobs:
  all-pr-tests:  # Re-run all PR tests
  e2e-android:   # integration_test on emulator
  security:      # Security test suite
```

### 7.3 Nightly

```yaml
schedule: daily 02:00 UTC
jobs:
  load-tests:    # k6 scenarios
  e2e-all:       # All platforms
  dependency-audit: # npm audit + dart pub outdated
```

---

## 8. Coverage Requirements

| Area | Minimum Coverage | Enforced |
|------|-----------------|----------|
| Domain services (calculator, state machine) | 95% | PR block |
| RBAC service | 95% | PR block |
| Validators | 90% | PR block |
| Services (application layer) | 85% | PR block |
| Controllers | 80% | PR block |
| Repositories | 80% | PR block |
| Flutter BLoC/Cubit | 85% | PR block |
| Flutter use cases | 90% | PR block |
| Overall backend | 80% | PR block |
| Overall Flutter | 75% | PR block |

---

## 9. Test Data Management

### 9.1 Seed Scripts

| Script | Purpose |
|--------|---------|
| `scripts/seed/company.js` | Default company + hierarchy |
| `scripts/seed/users.js` | Admin, supervisor, 5 technicians |
| `scripts/seed/overtime.js` | 50 sample records (all statuses) |
| `scripts/seed/settings.js` | Default company settings |
| `scripts/seed/permissions.js` | All permissions + default roles |

### 9.2 Test Fixtures

Shared fixtures in `backend/src/__tests__/fixtures/`:
- `users.fixture.js`
- `overtime.fixture.js`
- `organization.fixture.js`
- `gps.fixture.js`

### 9.3 Factory Pattern

Use `@faker-js/faker` for generating test data with consistent seeds for reproducibility.

---

## 10. Test Environments

| Environment | Purpose | Database |
|-------------|---------|----------|
| **Local** | Developer testing | mongodb-memory-server or Docker |
| **CI** | Automated pipelines | mongodb-memory-server |
| **Staging** | E2E + manual QA | MongoDB Atlas (staging cluster) |
| **Load** | Performance testing | MongoDB Atlas (isolated) |

No test shall ever run against production data.
