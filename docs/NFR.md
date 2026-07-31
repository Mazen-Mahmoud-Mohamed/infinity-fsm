# Non-Functional Requirements (NFR)

**Product:** Infinity FSM Platform  
**Version:** 2.0.0  

---

## Table of Contents

1. [Performance Targets](#1-performance-targets)
2. [Scalability](#2-scalability)
3. [Security](#3-security)
4. [Availability & Reliability](#4-availability--reliability)
5. [Backup Strategy](#5-backup-strategy)
6. [Logging Strategy](#7-logging-strategy)
7. [Monitoring & Alerting](#7-monitoring--alerting)
8. [Disaster Recovery](#8-disaster-recovery)
9. [Deployment Strategy](#9-deployment-strategy)
10. [Versioning Strategy](#10-versioning-strategy)
11. [Data Retention & Privacy](#11-data-retention--privacy)
12. [Compatibility](#12-compatibility)

---

## 1. Performance Targets

| Metric | Target | Measurement |
|--------|--------|-------------|
| API response time (p50) | < 100ms | Excluding photo upload |
| API response time (p95) | < 300ms | Excluding photo upload |
| API response time (p99) | < 800ms | Excluding photo upload |
| Dashboard KPI load | < 500ms | All KPIs in single request |
| Global search | < 400ms | Top 20 results |
| Monthly report generation | < 2s | Up to 500 employees |
| Monthly report (large) | < 30s | 5000+ employees (async job) |
| Photo upload (client → Cloudinary) | < 5s | 5 MB on 4G |
| Offline sync batch (10 ops) | < 3s | Including photo uploads |
| Socket.IO event delivery | < 200ms | From server action to client |
| App cold start | < 3s | To login screen |
| App warm start | < 1s | To dashboard |
| Flutter frame rate | 60 fps | No jank on list screens |

---

## 2. Scalability

### 2.1 Capacity Targets

| Scale | Technicians | Supervisors | Companies | Concurrent Users |
|-------|-------------|-------------|-----------|-----------------|
| **Launch** | 500 | 50 | 1 | 200 |
| **Year 1** | 5,000 | 500 | 10 | 2,000 |
| **Year 3** | 50,000 | 5,000 | 100 | 20,000 |
| **Year 5** | 200,000 | 20,000 | 500 | 80,000 |

### 2.2 Scaling Strategy

| Component | Initial | Scale Path |
|-----------|---------|------------|
| **API Server** | Single Node.js instance | Horizontal: PM2 cluster → Docker replicas → K8s |
| **MongoDB** | Atlas M10 | Vertical → Sharding by companyId |
| **Socket.IO** | In-process | Redis adapter → dedicated Socket.IO service |
| **Search** | MongoDB text indexes | Atlas Search → Elasticsearch cluster |
| **Reports** | Sync aggregation | Pre-computed materialized views → async job queue |
| **File Storage** | Cloudinary | Cloudinary auto-scales |
| **Cache** | None | Redis for settings, permissions, dashboard KPIs |

### 2.3 Database Growth Estimates

| Collection | Records/Year (5K tech) | Avg Doc Size |
|------------|----------------------|--------------|
| `overtime_records` | ~600,000 | ~3 KB |
| `audit_logs` | ~2,000,000 | ~1 KB |
| `notifications` | ~1,200,000 | ~0.5 KB |

Estimated Year 1 storage: ~5 GB (well within MongoDB Atlas limits).

---

## 3. Security

### 3.1 Authentication

| Control | Implementation |
|---------|----------------|
| Password hashing | bcrypt, cost factor 12 |
| Access token lifetime | 15 minutes |
| Refresh token lifetime | 7 days, rotated on use |
| Refresh token storage | SHA-256 hash in MongoDB |
| Device binding | Refresh token tied to deviceId |
| Brute force protection | Rate limit: 10 login attempts/min/IP |
| Account lockout | 10 failed attempts → 15 min lockout (future) |

### 3.2 Authorization

| Control | Implementation |
|---------|----------------|
| Model | Full RBAC (roles + permissions + scope) |
| Enforcement | Repository layer + middleware |
| Client permissions | UI only — server always re-validates |
| Privilege escalation | Deny overrides audited; admin cannot self-grant |

### 3.3 Data Protection

| Control | Implementation |
|---------|----------------|
| Tenant isolation | companyId filter on every query |
| Transport | TLS 1.2+ everywhere |
| Secrets | Environment variables, never in code/git |
| Photo URLs | Cloudinary signed URLs with expiry |
| PII | Employee data scoped to company; no cross-tenant |
| Input validation | Joi/Zod on every endpoint |
| Output encoding | No raw HTML in API responses |
| CORS | Whitelist client origins |
| Headers | Helmet.js (CSP, HSTS, X-Frame-Options) |
| Rate limiting | 100 req/min general, 10/min auth |
| Dependency scanning | npm audit + Snyk in CI (nightly) |

### 3.4 Compliance Readiness

| Requirement | Status |
|-------------|--------|
| Audit trail | ✅ Immutable audit logs |
| Data export | ✅ Report export (CSV/Excel/PDF) |
| Data deletion | ✅ Soft delete + future hard delete on request |
| Access logs | ✅ Login/logout audited |
| Encryption at rest | ✅ MongoDB Atlas encryption |
| Encryption in transit | ✅ TLS |

---

## 4. Availability & Reliability

| Metric | Target |
|--------|--------|
| Uptime SLA | 99.5% (production) |
| Planned maintenance window | Sunday 02:00–04:00 UTC |
| Maximum unplanned downtime | 4 hours/year |
| RPO (Recovery Point Objective) | 1 hour |
| RTO (Recovery Time Objective) | 4 hours |
| Mean time to recovery | < 1 hour |

### 4.1 Health Checks

```
GET /health          → { status: 'ok', uptime, version }
GET /health/ready    → { mongodb: 'connected', redis: 'connected' }
GET /health/live     → 200 if process alive
```

---

## 5. Backup Strategy

| Component | Method | Frequency | Retention |
|-----------|--------|-----------|-----------|
| MongoDB | Atlas automated backup | Continuous (PITR) | 30 days |
| MongoDB | Manual snapshot | Weekly | 90 days |
| Cloudinary | Built-in versioning | Automatic | Per Cloudinary plan |
| Audit logs | MongoDB backup (included) | Continuous | 7 years |
| Configuration | Git repository | Every commit | Indefinite |
| Environment secrets | Secure vault (not git) | On change | Current + 1 previous |

### 5.1 Backup Verification

- Monthly restore test to staging environment.
- Verify data integrity after restore.
- Document restore procedure in runbook.

---

## 6. Logging Strategy

### 6.1 Log Format

Structured JSON logging via Pino:

```json
{
  "level": "info",
  "time": "2026-07-29T13:00:00.000Z",
  "requestId": "uuid",
  "userId": "6888...",
  "companyId": "6888...",
  "method": "POST",
  "url": "/api/v1/overtime/start",
  "statusCode": 201,
  "responseTime": 45,
  "msg": "Overtime started"
}
```

### 6.2 Log Levels

| Level | Usage |
|-------|-------|
| `error` | Unhandled exceptions, DB connection failures |
| `warn` | GPS quality low, token near expiry, retry attempts |
| `info` | Request/response, state transitions, login events |
| `debug` | Query details, calculation steps (dev/staging only) |

### 6.3 Log Retention

| Environment | Retention |
|-------------|-----------|
| Production | 90 days (hot), 1 year (cold archive) |
| Staging | 30 days |
| Development | 7 days |

### 6.4 Sensitive Data

Never log: passwords, JWT tokens, refresh tokens, full GPS coordinates in debug (use truncated), personal phone numbers.

---

## 7. Monitoring & Alerting

### 7.1 Metrics (Prometheus-compatible)

| Metric | Alert Threshold |
|--------|----------------|
| API response time p95 | > 500ms for 5 min |
| Error rate (5xx) | > 1% for 5 min |
| MongoDB connection pool | > 80% utilization |
| Active Socket.IO connections | Informational |
| Sync queue depth (server) | > 1000 pending |
| Failed login rate | > 50/min |
| Disk usage | > 80% |
| Memory usage | > 85% |

### 7.2 Tools

| Purpose | Tool | Phase |
|---------|------|-------|
| Error tracking | Sentry | Phase 5 |
| APM | Datadog or New Relic | Phase 5 |
| Uptime monitoring | UptimeRobot or Pingdom | Phase 5 |
| Log aggregation | CloudWatch or ELK | Phase 5 |
| Mobile crash reporting | Firebase Crashlytics | Phase 5 |

### 7.3 Alerting Channels

| Severity | Channel |
|----------|---------|
| Critical (service down) | PagerDuty / phone |
| High (error spike) | Slack + email |
| Medium (performance) | Slack |
| Low (informational) | Dashboard only |

---

## 8. Disaster Recovery

### 8.1 Failure Scenarios

| Scenario | Impact | Recovery |
|----------|--------|----------|
| API server crash | Service unavailable | Auto-restart (PM2/Docker), < 1 min |
| MongoDB primary failure | Read/write unavailable | Atlas auto-failover, < 30s |
| Cloudinary outage | Photo upload fails | Queue locally, retry when restored |
| Google Maps outage | Geocoding fails | Store coordinates without address, backfill later |
| Full region outage | Complete service down | Restore from backup to secondary region, < 4 hours |
| Data corruption | Incorrect data | Point-in-time recovery, < 1 hour RPO |

### 8.2 DR Runbook

Documented in `infra/runbooks/disaster-recovery.md` (Phase 5):
1. Assess scope and impact.
2. Notify stakeholders.
3. Execute recovery procedure.
4. Verify data integrity.
5. Resume service.
6. Post-incident review.

---

## 9. Deployment Strategy

### 9.1 Environments

| Environment | Purpose | Deploy Trigger |
|-------------|---------|----------------|
| **Development** | Local developer machines | Manual |
| **CI** | Automated testing | Every PR |
| **Staging** | QA + E2E testing | Merge to `develop` |
| **Production** | Live system | Merge to `main` + manual approval |

### 9.2 Deployment Process

```
Feature branch → PR → CI tests pass → Merge to develop → Deploy staging
                                                          → QA approval
                                                     → PR to main
                                                     → Manual approval
                                                     → Deploy production
                                                     → Health check
                                                     → Smoke tests
```

### 9.3 Zero-Downtime Deployment

- Rolling deployment with health check gate.
- Database migrations are backward-compatible (expand → migrate → contract).
- Feature flags for risky changes.
- Rollback procedure: redeploy previous Docker image (< 5 min).

### 9.4 Mobile App Deployment

| Platform | Channel | Release Cadence |
|----------|---------|----------------|
| Android | Google Play (internal → beta → production) | Bi-weekly |
| iOS | TestFlight → App Store | Bi-weekly |
| Windows | MS Store or sideload | Monthly |

Backend supports N-1 app versions (current + previous).

---

## 10. Versioning Strategy

### 10.1 API Versioning

- URL-based: `/api/v1/`, `/api/v2/`
- Breaking changes require new version.
- Old version supported for minimum 6 months after new version release.
- Deprecation warnings in response headers: `Sunset: Sat, 01 Jan 2028 00:00:00 GMT`

### 10.2 Database Schema Versioning

- Migration scripts in `backend/src/migrations/`
- Each migration: `up()` and `down()` functions.
- Migration version tracked in `schema_migrations` collection.
- Migrations run automatically on deploy.

### 10.3 Calculation Versioning

- `calculationVersion` stored on every overtime record.
- Algorithm changes increment version.
- Recalculation tool available for admin (with audit trail).

### 10.4 App Versioning

- Semantic versioning: `MAJOR.MINOR.PATCH`
- Backend checks `appVersion` from device info.
- Force update if below minimum supported version.

---

## 11. Data Retention & Privacy

| Data Type | Retention | Deletion |
|-----------|-----------|----------|
| Overtime records | Indefinite (archived after 90 days) | Soft delete; hard delete on request |
| Audit logs | 7 years | Never deleted |
| Notifications | 1 year | Auto-purge |
| Idempotency records | 72 hours | TTL auto-delete |
| Refresh tokens | 7 days | TTL auto-delete |
| Offline sync queue (client) | Configurable (default 30 days) | Client-managed |
| Cloudinary photos | Indefinite | Manual per company policy |
| Server logs | 90 days hot, 1 year cold | Auto-purge |

---

## 12. Compatibility

### 12.1 Mobile Platforms

| Platform | Minimum Version | Target |
|----------|----------------|--------|
| Android | API 24 (7.0) | API 34+ |
| iOS | 14.0 | 17.0+ |
| Windows | 10 (1903) | 11 |

### 12.2 Backend

| Component | Minimum Version |
|-----------|----------------|
| Node.js | 20 LTS |
| MongoDB | 7.0 |
| Flutter | 3.19+ |
| Dart | 3.3+ |

### 12.3 Browser (Future Web Admin)

| Browser | Minimum Version |
|---------|----------------|
| Chrome | Last 2 versions |
| Firefox | Last 2 versions |
| Safari | Last 2 versions |
| Edge | Last 2 versions |
