# INFINITY

Enterprise Field Service Management for workforce operations — attendance, overtime journeys, work orders, and administration.

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Node.js](https://img.shields.io/badge/Node.js-339933?style=for-the-badge&logo=nodedotjs&logoColor=white)
![Express](https://img.shields.io/badge/Express-000000?style=for-the-badge&logo=express&logoColor=white)
![MongoDB](https://img.shields.io/badge/MongoDB-47A248?style=for-the-badge&logo=mongodb&logoColor=white)
![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)
![Windows](https://img.shields.io/badge/Windows-0078D6?style=for-the-badge&logo=windows&logoColor=white)

**INFINITY** (Infinity FSM) is a production-oriented Field Service Management platform for maintenance companies and field teams. One Flutter client and one Node.js API cover technician capture, supervisor review, and admin configuration — in **English (LTR)** and **Arabic (RTL)** on **Android** and **Windows**.

---

## Table of Contents

1. [Overview](#1-overview)
2. [Main Features](#2-main-features)
3. [User Roles](#3-user-roles)
4. [Technician Interface Control](#4-technician-interface-control)
5. [Overtime Workflow](#5-overtime-workflow)
6. [Offline & Sync](#6-offline--sync)
7. [Performance Optimizations](#7-performance-optimizations)
8. [Localization](#8-localization)
9. [Security](#9-security)
10. [Technology Stack](#10-technology-stack)
11. [Project Structure](#11-project-structure)
12. [Development Setup](#12-development-setup)
13. [Testing](#13-testing)
14. [Build & Release](#14-build--release)
15. [Environment Variables](#15-environment-variables)
16. [Deployment](#16-deployment)
17. [API Overview](#17-api-overview)
18. [Performance Notes](#18-performance-notes)
19. [Important Implementation Notes](#19-important-implementation-notes)
20. [Documentation](#20-documentation)
21. [License](#21-license)
22. [Author](#22-author)

---

## 1. Overview

**INFINITY** helps organizations run field operations from a single system:

- Clock attendance with GPS evidence
- Capture multi-stage overtime journeys (photos, voice, notes, GPS)
- Assign and complete work orders
- Manage inventory, assets, preventive maintenance, and service reports
- Give admins and supervisors role-based dashboards and review tools

| Topic | Detail |
|-------|--------|
| **Problem** | Field teams need one system for attendance, overtime evidence, work orders, stock/assets, PM, and admin analytics — not disconnected tools. |
| **Users** | **Admin**, **Supervisor**, **Technician** |
| **Platforms** | **Android** (phones/tablets) · **Windows** desktop |
| **Locales** | Arabic **RTL** · English **LTR** |
| **Client** | Flutter · Material 3 · Clean Architecture · Cubit · Repository Pattern |
| **API** | Node.js · Express · MongoDB · JWT · Socket.IO |
| **API version** | `/api/v1` |

The Windows window title and product metadata display as **INFINITY**. The Flutter package name remains `mobile` so Android packaging is unchanged.

Flutter also contains `ios/`, `macos/`, `linux/`, and `web/` runner folders as standard scaffolding. Documented product targets are **Android** and **Windows**.

---

## 2. Main Features

Features below exist under `mobile/lib/features/*` and `backend/src/modules/*`.

### 🔐 Authentication & Security

- Login / Logout
- Remember Me (email + session tokens — **never** the password)
- Secure refresh-token persistence (`flutter_secure_storage`)
- Windows-specific Remember Me session policy (DPAPI-backed storage)
- Access-token refresh via `/auth/refresh`
- Role- and permission-based access (RBAC)

### 📊 Dashboard

- Workforce metrics and attendance information
- Overtime analytics and trends (eligible hours per calendar day)
- Role-based dashboard sections
- Period filters: Today · This Week · This Month · This Year · Custom
- Dashboard summary request deduplication (in-flight + short fresh reuse)
- Notification bell seeded from dashboard activity (no dedicated `/notifications` API)

### ⏱️ Overtime Management

- Journey stages: **START → ARRIVED → FINISHED WORK → END**
- Photos, voice notes, notes, GPS / OpenStreetMap
- Offline pending queue with **independent stage** sync
- Admin / Supervisor review: Approve · Partial Approve · Reject
- Rejection reason visible in technician history when present
- Overnight / multi-day handling with official working-hours rules
- Company overtime policy (soft 16h manual-review flag; no hard 48h end cap)
- Excel export (summary / detailed) with English & Arabic workbooks

### 📝 Work Orders

- Listing and technician assignments
- Status flow through create → assign → track → complete
- Attachments / photos where supported in the work-order UI
- Timeline-oriented detail flows

### 🕐 Attendance

- Attendance dashboard (clock in/out, breaks where implemented)
- Shared `AttendanceCubit` (single status / today fetch and poll)
- Attendance sync with connectivity awareness
- GPS accuracy gates on the backend

### 📦 Inventory · Assets · PM · Reports

- Inventory (warehouses, parts, low-stock style alerts on dashboard)
- Assets registry
- Preventive maintenance plans / schedules
- Service reports (list, detail, generation/download, customer signature support)
- Reports Center hub and overtime Excel Save As flow on desktop

### ⚙️ Settings

- Language, theme, notification preferences
- Sync settings (auto sync, interval, Wi‑Fi-only)
- Overtime media settings + Configuration Testing Lab (local preview; no Cloudinary upload from the lab)
- **Technician Interface** controls (Admin)
- Settings reachable from technician main sections when profile/settings is enabled
- Server Management API base override (admin-protected)

### 🌐 Connectivity & Offline

- API health–based connectivity (authoritative sync gate)
- Offline mode for overtime pending actions
- Retry synchronization on reconnect
- Configurable sync interval (`5 / 15 / 30 / 60` minutes)
- Wi‑Fi-only sync for overtime (when enabled)
- Global search palette across existing module APIs (no dedicated `/search` API)

> **Vehicles** is schema-ready documentation only and is **not** implemented in the API or UI.

---

## 3. User Roles

| Role | Access |
|------|--------|
| **Admin** | Full permissions: users, roles, settings (including Technician Interface), inventory, assets, PM, reports, media policy, exports, organization |
| **Supervisor** | Team oversight, overtime review/export, operational dashboards, work orders and related manage scopes; settings **view** (not full `settings:manage`) |
| **Technician** | Own attendance, overtime capture, assigned work orders, and view scopes for inventory/assets/PM/reports; uses **operational home** (not the executive admin dashboard) |

**Technician Interface** configuration affects **technician operational navigation only**. It does **not** remove Admin or Supervisor access, menus, or routes.

---

## 4. Technician Interface Control

**Admin Settings → Technician Interface** (`settings:manage`).

Company-scoped setting key: `technician_interface`.

| Control | When enabled | When disabled |
|---------|--------------|---------------|
| **Overtime** | Visible in technician nav | Hidden; deep links redirected |
| **Work Orders** | Visible | Hidden; deep links redirected |
| **Attendance** | Visible | Hidden; deep links redirected |
| **Profile** | Visible | Hidden; deep links redirected |

Defaults are all **enabled**.

**All-disabled state:** technicians are sent to a dedicated **no sections** screen asking them to contact an administrator (`/technician-no-sections`).

Config is readable by authenticated users for navigation; only admins with settings manage may update it.

---

## 5. Overtime Workflow

```
START
  ↓
ARRIVED (at work site)
  ↓
FINISHED WORK
  ↓
END
```

| Topic | Behavior |
|-------|----------|
| **Independent stages** | Each stage can be its own queue item (`start` · `arrivedAtWorkSite` · `finishedWork` · `end`). A stage does **not** wait for the entire journey to finish before sync can run. |
| **Online** | Stages sync to the API when connectivity allows (API reachable). |
| **Offline** | Stages are persisted locally in the pending queue. |
| **Reconnect** | Sync retries pending actions (scheduler + connectivity restore). |
| **Media** | Photos / voice stay pending until the server confirms upload where the upload policy requires it. |
| **Idempotency** | Stable `clientRequestId` per stage; backend reconciles duplicates / already-confirmed stages. |
| **Evidence** | GPS, reverse-geocoded address, photos, independent stage voice notes; maps via OpenStreetMap (`flutter_map`). |
| **Types** | Normal and Travel (including overnight travel). |

### Approval

| Action | Behavior |
|--------|----------|
| **Approve** | Full approval; approved hours from calculation when omitted |
| **Partial approve** | Reviewer sets approved hours (HH:MM UI → `approvedHours`) |
| **Reject** | Reject with reason (shown in technician history) |
| **Manual review** | Sessions over the soft duration threshold are flagged `requiresManualReview` |

### Company overtime policy (current)

| Rule | Behavior |
|------|----------|
| Soft duration threshold | Default **16 hours** (`OVERTIME_MAX_SESSION_HOURS`). Ending longer sessions is **allowed**. |
| Hard maximum | **No** hard 48-hour (or similar) end cap / `SESSION_TOO_LONG` |
| Minimum request | `OVERTIME_MIN_REQUEST_HOURS` (default `0.5`) |
| Working days | Saturday–Thursday · **09:00–17:00** (Africa/Cairo) |
| Friday | Full day off — eligible overtime can count the full **24 hours** |
| Multi-day | Split by calendar day using official OT rules (not equal division of the total) |

Authoritative calculator: `backend/src/modules/business/overtime/overtime.calculation.js`.

### Excel export

Authorized Admin / Supervisor users can export workbooks (ExcelJS):

- **Summary** or **Detailed** (index + per-session sheets)
- English / Arabic report language
- Desktop **Export ready** dialog with native **Save As** (`file_selector`)

Branch and Department are intentionally excluded from export filters/columns.

---

## 6. Offline & Sync

| Concern | Implementation |
|---------|----------------|
| **Connectivity** | `ConnectivityService` — network interface + internet probe + **API health** |
| **Authoritative gate** | API reachability (`canSync`) — not generic internet alone |
| **Health endpoint** | `GET /api/v1/health` (probe hits API `/health`) |
| **Probe reuse** | Fresh successful online probe reused for **5 seconds** |
| **Windows false-offline** | Generic OS/internet checkers can report false negatives on Windows; **API health remains authoritative** for sync |
| **Pending queue** | Overtime actions persisted locally and retried |
| **Auto sync** | Configurable on/off |
| **Intervals** | `5 / 15 / 30 / 60` minutes (default `5`) |
| **Wi‑Fi-only** | Implemented for **overtime** sync when enabled |
| **Single-flight** | Sync cubits avoid overlapping sync cycles (follow-up when needed) |
| **Restore sync** | Connectivity restore triggers sync when API becomes reachable |

Attendance and other modules use offline banners / caching patterns where implemented. Overtime has the most complete offline path.

---

## 7. Performance Optimizations

Optimizations below are **present in the current codebase**.

### 🚀 Dashboard

- In-flight request coalescing + **5-second** fresh reuse
- Notification badge seeding from loaded dashboard summary
- MongoDB query consolidation via `$facet`
- `liveActivity` via aggregate + `$lookup` (replaces find + populate)

### 🚀 API Payloads

- Lightweight overtime **list** projections
- Lightweight work-order **list** projections
- Full details remain on **detail** endpoints

### 🚀 Authentication

- Concurrent `User.findOne` + `Role.find` after JWT verify
- **DB user remains authoritative**
- JWT roles are used only to prefetch role documents — **not** as sole authorization

### 🚀 Flutter

- Shared `AttendanceCubit` (lazy singleton — no duplicate pollers)
- Overtime / attendance timer rebuild isolation (`BlocSelector`)
- Image decode hints (`memCacheWidth`) on key photo paths
- Connectivity health-probe reuse (5s when API was online)

### Measured backend benchmarks (local API → Atlas, small dataset)

Labeled **measured** — not estimates. Values from the latest verified profiling pass after auth parallelization:

| Metric | Before → After (measured) |
|--------|---------------------------|
| Auth median | **705.2 ms → 343.8 ms** |
| Dashboard HTTP median | **1140.9 ms → 781.4 ms** |
| Dashboard HTTP average | **1174.8 ms → 825.9 ms** |
| `liveActivity` (populate → `$lookup`) | **~702 ms → ~350 ms** (same measurement series) |

Android on-device frame timings are environment-dependent; use Flutter profile mode on a real device for client UI measurements.

---

## 8. Localization

| Topic | Detail |
|-------|--------|
| Languages | **Arabic** · **English** |
| Direction | Arabic **RTL** · English **LTR** |
| First launch | Follows **system** language when preference is `system` |
| Explicit choice | User language selection overrides system |
| Restore defaults | Returns locale preference to **system** |
| Sources | ARB: `mobile/lib/core/localization/l10n/app_en.arb`, `app_ar.arb` |
| Generation | Flutter `gen-l10n` (`flutter gen-l10n`) |

Dashboard charts and overtime Excel exports respect locale / RTL where implemented.

---

## 9. Security

Verified behavior only:

- JWT access + refresh; passwords hashed with **bcrypt**
- Role-based permissions on protected backend routes and client gates
- Admin settings authorization (`settings:manage` for Technician Interface, etc.)
- Secure token storage (`flutter_secure_storage`)
- Remember Me stores **session/refresh tokens** (and remembered email) — **never the password**
- Logout clears persisted session where applicable (Windows Remember Me policy clears tokens)
- DB-authoritative user validation (`isActive`, `deletedAt`, company, roles)
- JWT is **not** the sole authorization source after verify
- Helmet, CORS allow-list, rate limiting
- Device clock skew checks; GPS accuracy thresholds
- Client log sanitization for tokens / passwords
- Secrets via environment only — never commit `.env`

### Windows Remember Me (summary)

1. Sign in with Remember Me → tokens in secure storage (serialized writes).
2. Password never stored.
3. Full restart restores session from refresh/session tokens; expired access refreshes automatically.
4. Invalid refresh → session cleared → Sign in.
5. Remember Me **off** → tokens in memory only for the live process.
6. Android keeps existing always-persist-to-secure-storage behavior; Windows policy does not change mobile auth.

---

## 10. Technology Stack

| Layer | Technology |
|-------|------------|
| Mobile / Desktop | Flutter / Dart (^3.12) |
| UI | Material 3 |
| State | `flutter_bloc` (Cubit) |
| DI | GetIt |
| HTTP | Dio |
| Routing | GoRouter (`StatefulShellRoute`) |
| Localization | Flutter `gen-l10n` (ARB) |
| Maps | OpenStreetMap (`flutter_map`) — not Google Maps SDK |
| Media uploads | Cloudinary |
| Backend | Node.js (≥ 20) / Express |
| Database | MongoDB / Mongoose |
| Authentication | JWT + bcrypt |
| Realtime | Socket.IO (authenticated rooms; ping/pong foundation) |
| Excel | ExcelJS |
| Desktop | Windows |
| Mobile | Android |

---

## 11. Project Structure

```
infinity-fsm/
├── backend/                 # Node.js / Express API
│   ├── src/
│   │   ├── config/
│   │   ├── modules/
│   │   │   ├── core/        # auth, rbac, dashboard, users, settings, …
│   │   │   └── business/    # attendance, overtime, work-orders, …
│   │   ├── routes/          # /api/v1
│   │   ├── shared/          # middleware, utils
│   │   └── __tests__/
│   ├── scripts/             # seed & migrations
│   └── .env.example
├── mobile/                  # Flutter client (Android + Windows)
│   ├── lib/
│   │   ├── core/            # theme, router, l10n, DI, network, storage
│   │   ├── features/        # auth, dashboard, attendance, overtime, …
│   │   └── shared/
│   ├── android/
│   ├── windows/             # runner title: INFINITY
│   ├── test/
│   └── assets/
├── docs/                    # Architecture, API, RBAC, roadmap, …
├── infra/                   # Deployment planning notes
├── tests/                   # Cross-cutting test assets (planning)
├── screenshots/
├── installer.iss            # Windows Inno Setup installer
├── LICENSE
└── README.md
```

**Architecture (Flutter):** Presentation (pages/widgets + Cubits) → Domain (entities, use cases, repository interfaces) → Data (models, datasources, repositories).

**Architecture (Backend):** Routes → Validators → Controllers → Services → Mongoose models.

---

## 12. Development Setup

### Requirements

- Flutter SDK with Dart **^3.12**
- Node.js **≥ 20**
- npm
- MongoDB (local or Atlas) / configured backend
- Cloudinary account for production media uploads
- Windows desktop: Visual Studio **Desktop development with C++** workload

### Backend

```bash
cd backend
cp .env.example .env    # set placeholders — never commit real secrets
npm install
npm run seed            # optional
npm run dev             # http://localhost:3000  (node --watch)
```

Health checks:

```bash
curl http://localhost:3000/api/v1/health
curl http://localhost:3000/api/v1/health/ready
```

### Flutter

```bash
cd mobile
flutter pub get
flutter gen-l10n
flutter run -d android    # or: flutter run -d windows
```

Local API override (compile-time):

```bash
flutter run --dart-define=ENV=development --dart-define=API_BASE_URL=http://<host>:3000/api/v1
```

Default / production API base is configured in `mobile/lib/core/config/env_config.dart`. Runtime **Server Management** can override the active API base without rebuilding (admin-protected).

### Useful commands

| Area | Command |
|------|---------|
| Backend start | `cd backend && npm start` |
| Backend lint | `cd backend && npm run lint` |
| Backend test | `cd backend && npm test` |
| Flutter analyze | `cd mobile && flutter analyze` |
| Flutter test | `cd mobile && flutter test` |

---

## 13. Testing

### Backend (Jest)

Under `backend/src/__tests__/`, including:

- Overtime calculation, calendar-day split, end-duration policy
- Dashboard overtime trends
- Overtime Excel export / timeline / approved hours
- Auth parallel role prefetch
- Dashboard live-activity / list-projection payload tests
- RBAC

```bash
cd backend
npm test
```

### Flutter

Under `mobile/test/`, including:

- Authentication / Windows Remember Me / token manager
- Dashboard widgets (RTL, charts, workforce overview)
- Overtime offline lifecycle, sync scheduler, reconciliation, forensics
- Connectivity service
- Settings / localization / Technician Interface navigation
- Work orders / attendance areas as covered by existing suites

```bash
cd mobile
flutter test
flutter analyze
```

Recent ConnectivityService interface updates are covered by updated overtime test fakes (lifecycle, forensics, reconciliation, scheduler). Run those suites after connectivity changes.

> Do not treat analyzer “issue count” as error count — most findings are info/style; compile errors are separate.

---

## 14. Build & Release

### Android

```bash
cd mobile
flutter build apk --release
# optional Play Store bundle:
flutter build appbundle --release
```

Typical APK output:

`mobile/build/app/outputs/flutter-apk/app-release.apk`

### Windows

```bash
cd mobile
flutter build windows --release
```

Output:

`mobile/build/windows/x64/runner/Release/` (executable name `mobile.exe`; window title **INFINITY**)

Optional installer: root `installer.iss` (Inno Setup) packages the Windows Release build.

Release APK and Windows builds have been successfully produced and exercised on real devices/desktops in current project validation. Do not commit signing keystores, API secrets, or `.env` files.

---

## 15. Environment Variables

Copy `backend/.env.example` → `backend/.env`. **Never commit real secrets.**

| Variable | Purpose |
|----------|---------|
| `NODE_ENV` | `development` / `production` / `test` |
| `PORT` | API port (default `3000`) |
| `API_VERSION` | Version segment (default `v1`) |
| `MONGODB_URI` | MongoDB URI — e.g. `mongodb://localhost:27017/<db>` or Atlas `mongodb+srv://<user>:<password>@<cluster>/...` |
| `JWT_ACCESS_SECRET` / `JWT_REFRESH_SECRET` | Token secrets (≥ 32 chars) — use strong unique values in production |
| `JWT_ACCESS_EXPIRY` / `JWT_REFRESH_EXPIRY` | Defaults `15m` / `7d` |
| `CORS_ORIGINS` | Allowed origins (comma-separated) |
| `RATE_LIMIT_WINDOW_MS` / `RATE_LIMIT_MAX` / `RATE_LIMIT_AUTH_MAX` | Rate limiting |
| `LOG_LEVEL` | Pino level |
| `CLOUDINARY_CLOUD_NAME` / `CLOUDINARY_API_KEY` / `CLOUDINARY_API_SECRET` | Media uploads |
| `SOCKET_CORS_ORIGINS` | Socket.IO CORS |
| `DEVICE_CLOCK_SKEW_SECONDS` | Clock drift allowance |
| `ATTENDANCE_GPS_ACCURACY_THRESHOLD_METERS` | Attendance GPS gate |
| `OVERTIME_MAX_SESSION_HOURS` | Soft review threshold (default `16`) |
| `OVERTIME_MAX_REQUEST_HOURS` / `OVERTIME_MIN_REQUEST_HOURS` | Request bounds |
| `OVERTIME_GPS_ACCURACY_THRESHOLD_METERS` | Overtime GPS gate |

**Client:** `--dart-define=API_BASE_URL=...` and `--dart-define=ENV=development|production`.

---

## 16. Deployment

| Component | Current state |
|-----------|---------------|
| **Backend API** | Production base URL points at a **Render** web service (`EnvConfig.productionApiBaseUrl`). Configure MongoDB, JWT, Cloudinary, and CORS via the host’s environment settings. |
| **Mobile / Desktop** | Distributed as **built artifacts** (Android APK/AAB, Windows Release folder / optional Inno Setup installer) — not a separate hosted web frontend. |
| **`infra/`** | Planning notes only (Docker/CI planned). No live Docker/CI pipeline configs are required to run the app today. |

Bind the API to the platform port (e.g. `PORT`) and keep secrets in the host environment — never in the repository.

---

## 17. API Overview

Primary mount: **`/api/v1`**

| Group | Path prefix | Notes |
|-------|-------------|--------|
| Health | `/health`, `/health/ready` | Liveness / readiness |
| Auth | `/auth` | `POST /login`, `POST /refresh`, `POST /logout`, `GET /me` |
| Dashboard | `/dashboard` | Role summary & related stats |
| Overtime | `/overtime` | Journey, review, export |
| Attendance | `/attendance` | Clock / history / admin |
| Work Orders | `/work-orders` | CRUD & workflow |
| Settings | `/settings` | Including technician interface config |
| Organization | `/organization` | Company / org |
| Users / Roles | `/users`, `/roles` | Admin RBAC |
| Inventory / Assets / PM | `/inventory`, `/assets`, `/pm` | Operations modules |
| Reports | `/reports` | Operational reports |
| Time / Security | `/time`, `/security` | Platform helpers |

Fuller catalog: [docs/API.md](./docs/API.md). Prefer **mounted routes in code** over older planned docs. Dedicated `/notifications` and `/search` APIs are **not** mounted; the app uses dashboard activity and client-side search across existing APIs.

---

## 18. Performance Notes

- Avoid global caching of **real-time** overtime running state
- Dashboard uses **controlled, short-lived** deduplication (in-flight + ~5s fresh reuse) — not a long-lived stale cache
- List endpoints use **lightweight projections**; detail endpoints retain full data
- Auth parallelization reduces sequential Mongo round-trips; DB validation stays authoritative
- Load balancing / Redis are **not** part of the current required architecture based on measured bottlenecks (Atlas RTT + sequential client calls remain the primary latency drivers)

---

## 19. Important Implementation Notes

| Topic | Guarantee |
|-------|-----------|
| Overtime math | Calculation logic lives in backend policy/calculator — separate from UI formatting |
| Admin review | Approve / Partial / Reject behavior preserved |
| Technician UI | Hides technical metadata where designed; admin retains detailed review data |
| Rejection reason | Visible to technician in history when present |
| Offline | Overtime actions persisted and retried; reconciliation when server already confirmed a stage |
| Technician Interface | Company-scoped; Admin/Supervisor navigation unrestricted |
| Maps | OpenStreetMap only |
| SessionQueryCache | Used to avoid duplicate network fetches where wired |
| Dashboard loading | Prefer `isRefreshing` / cached summary over full-page loaders when data exists |
| Product name | **INFINITY** in UI / Windows title; package `mobile` unchanged |

---

## 20. Documentation

| Document | Description |
|----------|-------------|
| [Architecture](./docs/ARCHITECTURE.md) | Platform design & ADRs |
| [Database](./docs/DATABASE.md) | Schema notes |
| [REST API](./docs/API.md) | Endpoint catalog |
| [RBAC](./docs/RBAC.md) | Roles & permissions |
| [Socket.IO Events](./docs/SOCKET_EVENTS.md) | Realtime catalog |
| [Testing](./docs/TESTING.md) | Test strategy |
| [NFR](./docs/NFR.md) | Non-functional requirements |
| [Module Registry](./docs/MODULE_REGISTRY.md) | Module catalog |
| [Roadmap](./docs/ROADMAP.md) | Delivery phases |
| [Future Improvements](./docs/FUTURE_IMPROVEMENTS.md) | Post-MVP ideas |

> Prefer this README for **current shipped behavior**. Some docs may still describe planned phases; when in doubt, trust `mobile/` and `backend/src/`.

---

## 21. License

Released under the [MIT License](./LICENSE).

---

## 22. Author

**Mazen Mahmoud** — Total-Com Solutions

Built as an enterprise Field Service Management platform for real-world technician and workforce operations.
