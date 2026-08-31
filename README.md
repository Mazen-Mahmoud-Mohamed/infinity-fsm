# INFINITY

Enterprise Field Service Management for workforce operations — work orders, overtime journeys, attendance, notifications, and administration.

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
4. [Technician Experience](#4-technician-experience)
5. [Technician Interface Control](#5-technician-interface-control)
6. [Overtime Workflow](#6-overtime-workflow)
7. [Notifications](#7-notifications)
8. [Offline & Sync](#8-offline--sync)
9. [Performance Optimizations](#9-performance-optimizations)
10. [Localization](#10-localization)
11. [Security](#11-security)
12. [Technology Stack](#12-technology-stack)
13. [Project Structure](#13-project-structure)
14. [Development Setup](#14-development-setup)
15. [Testing](#15-testing)
16. [Build & Release](#16-build--release)
17. [Environment Variables](#17-environment-variables)
18. [Firebase Integration](#18-firebase-integration)
19. [Deployment](#19-deployment)
20. [API Overview](#20-api-overview)
21. [Performance Notes](#21-performance-notes)
22. [Important Implementation Notes](#22-important-implementation-notes)
23. [Recent Updates](#23-recent-updates)
24. [Troubleshooting](#24-troubleshooting)
25. [Documentation](#25-documentation)
26. [License](#26-license)
27. [Author](#27-author)

---

## 1. Overview

**INFINITY** helps organizations run field operations from a single full-stack platform:

- Create, assign, and complete **work orders** with customer/site context
- Capture multi-stage **overtime journeys** (photos, voice, notes, GPS)
- Track **attendance** with GPS evidence
- Deliver **realtime and push notifications** to technicians and managers
- Give admins and supervisors role-based dashboards, review tools, and **technician interface control**
- Manage inventory, assets, preventive maintenance, and service reports where enabled

| Topic | Detail |
|-------|--------|
| **Problem** | Field teams need one system for attendance, overtime evidence, work orders, stock/assets, PM, and admin analytics — not disconnected tools. |
| **Users** | **Admin**, **Supervisor**, **Technician** |
| **Platforms** | **Android** (phones/tablets) · **Windows** desktop |
| **Locales** | Arabic **RTL** · English **LTR** |
| **Client** | Flutter · Material 3 · Clean Architecture · Cubit · Repository Pattern |
| **API** | Node.js · Express · MongoDB · JWT · Socket.IO · Firebase Admin (FCM) |
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
- Notification bell with unread count (notifications API + dashboard fallback)

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

- Create, list, assign, accept, reject, complete, and cancel work orders
- Status flow: `PENDING` → `ASSIGNED` → `ACCEPTED` / `REJECTED` → `IN_PROGRESS` → `COMPLETED` / `CANCELLED`
- Priorities: `LOW` · `MEDIUM` · `HIGH` · `CRITICAL`
- **Multiple technician assignees** (`assignedTechnicianIds`) with a primary assignee
- Scheduled date/time, customer information, location label, and optional location URL
- **Customer phone numbers** (optional, zero or more per work order)
- Notes, voice notes, attachments, and execution photos (before / during / after where supported)
- Timeline-oriented detail flows
- Technician execution workflow with permission-aware UI (admin vs technician views)

#### Customer phone numbers

| Topic | Behavior |
|-------|----------|
| **Optional** | A work order may contain zero, one, or multiple customer phone numbers |
| **API field** | Additive `customerPhoneNumbers` array on create/update |
| **Create default** | Missing value defaults to an empty array |
| **Update** | Omitting the field preserves the existing stored value |
| **Normalization** | Trimmed strings; empty values are not submitted |
| **De-duplication** | Digit-based de-duplication; display text is preserved |
| **Country codes** | No automatic country-code rewrite |
| **Technician UI** | Technicians see phone numbers when present on assigned work orders |
| **Call action** | Single number → **Call** opens the device dialer (`tel:`); does **not** auto-dial |
| **Multiple numbers** | Technician selects a number before opening the dialer |

Backend validation and normalization live in `work-orders.service.js` / `work-orders.validator.js`. Client helpers: `work_order_phone_numbers.dart`.

### 🔔 Notifications

- **In-app notification center** (`/notifications`) with unread count and mark-as-read
- **Firebase Cloud Messaging (Android)** for device push delivery
- **Socket.IO** realtime delivery (`notification:new`) while connected
- **Local OS notifications** (Android foreground + Windows toast while app is running)
- Persisted recipient notifications with deduplication keys
- Multi-device FCM token registration (`/notifications/device-tokens`)
- Rich contextual titles/bodies (technician name, job number, customer, site where available)
- Structured `data` payload for navigation (`workOrderId`, `overtimeId`, `jobNumber`, etc.)
- **Deep-link navigation** to work-order and overtime admin detail routes
- Pending navigation queue until auth/router bootstrap completes
- Mark-as-read when a notification is opened
- Idempotent navigation (duplicate tap protection)

See [§7 Notifications](#7-notifications) for platform behavior (Android FCM, Windows Socket.IO, deep links).

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
- **Cached technician interface configuration** (per company) for offline navigation
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

## 4. Technician Experience

The technician app is intentionally **simplified** for field execution. Technicians use the **operational home** (not the executive admin dashboard).

### Configurable sections (Admin → Technician Interface)

| Section | Typical label | Backend flag |
|---------|---------------|--------------|
| Overtime / work journeys | **العمل** | `overtime` |
| Work Orders | **أوامر العمل** | `workOrders` |
| Profile | **أنا** | `profile` |
| Attendance | **الحضور** | `attendance` |

Only enabled sections appear in technician bottom navigation / rail. Disabled sections are removed from normal navigation; existing route guards redirect deep links according to authorization rules (notification deep links still target entity routes when permitted).

### Work Order detail — technician vs admin

Technician work-order detail **hides administrative metadata** when the user lacks team/all work-order view permissions (`showAdminDetails` gate in `work_order_detail_page.dart`).

**Typically hidden from technicians** (when admin details are off):

- Captured GPS coordinates and administrative location metadata
- Timeline / event administrative metadata
- Assignee administration details beyond what the technician needs
- Raw map URLs and administrative coordinate controls

**Operational information preserved** for technicians (when present on the work order):

- Title, job number, status, priority, scheduled date/time
- Customer name and **customer phone numbers** (with Call action)
- Location label and open-location action
- Notes, voice note, attachments, execution photos
- Primary workflow actions (accept, start, complete, etc.)

Permissions and admin interface configuration both apply — not every technician sees every field on every work order.

---

## 5. Technician Interface Control

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

### Offline persistence (technician app)

| Topic | Behavior |
|-------|----------|
| **Source of truth** | Server configuration (`GET /settings/technician-interface/config`) |
| **Local cache** | Last successfully received config stored per company in SharedPreferences (`technician_interface_config:{companyId}`) |
| **Offline startup** | Cached config loads **immediately** — the app does **not** revert to all sections just because the device is offline |
| **Online sync** | Cached config shown first; network fetch updates cache and UI when newer |
| **Admin changes while offline** | Technician cannot receive updates until connectivity returns and sync succeeds |
| **First install offline** | Falls back to existing application defaults when no cache exists yet |
| **Logout** | In-memory session cache clears; disk cache remains until replaced by a newer server config |

Implementation: `TechnicianInterfaceCubit` + `TechnicianInterfaceLocalDataSource`.

---

## 6. Overtime Workflow

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

### Overtime notifications — checkpoint vs journey end

The v2 journey distinguishes two late-stage events that must **not** be confused in notification copy:

| Event | Trigger | Meaning | Example title (AR) |
|-------|---------|---------|-------------------|
| **`finished_work`** | `recordCheckpoint(..., finishedWork)` | Technician finished **work at the site** (mid-journey checkpoint) | **إنهاء العمل في الموقع** |
| **`ended`** | `end()` with `endJourney` checkpoint | Technician **ended the overtime journey** (final stage) | **إنهاء رحلة العمل الإضافي** |

Workflow order: **start journey → arrive → finish work at site → end journey**.

> **Known limitation:** Overtime records do not currently store a linked work-order number. Overtime notifications therefore cannot include a WO reference unless the backend model is extended.

---

## 7. Notifications

INFINITY delivers operational notifications through **persistence + realtime + push**, without replacing existing business modules.

### Channels

| Channel | Platform | When active |
|---------|----------|-------------|
| **In-app center** | Android · Windows | Authenticated users — list, unread count, mark-as-read |
| **Firebase Cloud Messaging** | **Android** | Device push (foreground, background, terminated) |
| **Socket.IO** | Android · **Windows** | Realtime `notification:new` while authenticated and connected |
| **Local OS notification** | Android · Windows | Foreground FCM mirror; Windows toast via Socket.IO while app is running |

Windows does **not** use FCM for background/terminated push in the current implementation. Windows notifications arrive via **Socket.IO while the application process is running**.

### Recipients & events (implemented hooks)

| Audience | Event | When |
|----------|-------|------|
| **Technician** | Work order assigned | New/changed assignee |
| **Admin / Supervisor** | Work order accepted | Technician accepts |
| **Admin / Supervisor** | Work order completed | Technician completes |
| **Admin / Supervisor** | Overtime started | Journey start |
| **Admin / Supervisor** | Overtime arrived | Arrived at work site checkpoint |
| **Admin / Supervisor** | Overtime finished work | Finished work at site checkpoint |
| **Admin / Supervisor** | Overtime ended | Journey ended |

Hooks: `backend/src/modules/notifications/notification.hooks.js`. Delivery: persist → Socket.IO → FCM (Android tokens).

### Structured payload (navigation + context)

Visible title/body are for humans; **`data`** carries machine-readable fields where available:

`notificationId` · `type` · `entityType` · `entityId` · `workOrderId` · `overtimeId` · `jobNumber` · `customerName` · `locationLabel` · `actorName` · `technicianName` · `siteAddress` · `event`

Copy builders include technician/customer/site context when present in the source entity — no invented fields.

Example body pattern (placeholders only):

> تم إكمال أمر الشغل `{jobNumber}` بواسطة `{technicianName}`.

### Deep linking & tap behavior

| Route | Purpose |
|-------|---------|
| `/work-orders/:id` | Work order detail |
| `/overtime/admin/:id` | Overtime admin detail |

| State | Android behavior |
|-------|------------------|
| **Foreground** | Local notification → tap → navigate |
| **Background** | FCM system notification → `onMessageOpenedApp` → navigate |
| **Terminated** | `getInitialMessage()` + launch details → **pending navigation** until auth/router ready |
| **Logged out** | Intent stored in preferences → consumed once after login |

Additional behaviors (implemented):

- **Mark-as-read** when opened (`PUT /notifications/:id/read`)
- **Idempotent navigation** (duplicate tap / dual callback protection)
- **Windows focus** — toast click brings the INFINITY window to foreground and navigates

Client: `PushNotificationService` + `notification_navigation.dart`.

### Android push prerequisites

- Firebase project configured for Android package **`com.example.mobile`**
- `google-services.json` in `mobile/android/app/` (use `google-services.json.example` as template — **do not commit** production secrets)
- Backend Firebase Admin credentials via environment (see [§18 Firebase Integration](#18-firebase-integration))
- `FCM_ENABLED=true` on the API
- Android 13+ notification permission granted by the user

Android release builds use **core library desugaring** (`desugar_jdk_libs`) required by `flutter_local_notifications`.

---

## 8. Offline & Sync

| Concern | Implementation |
|---------|----------------|
| **Connectivity** | `ConnectivityService` — network interface + internet probe + **API health** |
| **Authoritative gate** | API reachability (`canSync`) — not generic internet alone |
| **Health endpoint** | `GET /api/v1/health` (probe hits API `/health`) |
| **Probe reuse** | Fresh successful online probe reused for **5 seconds** |
| **Windows false-offline** | Generic OS/internet checkers can report false negatives on Windows; **API health remains authoritative** for sync |
| **Pending queue** | Overtime actions persisted locally and retried |
| **Technician interface cache** | Per-company visibility flags persisted locally; used on offline cold start |
| **Auto sync** | Configurable on/off |
| **Intervals** | `5 / 15 / 30 / 60` minutes (default `5`) |
| **Wi‑Fi-only** | Implemented for **overtime** sync when enabled |
| **Single-flight** | Sync cubits avoid overlapping sync cycles (follow-up when needed) |
| **Restore sync** | Connectivity restore triggers sync when API becomes reachable |

Attendance and other modules use offline banners / caching patterns where implemented. **Overtime** has the most complete offline business-data path. **Technician interface visibility** is offline-resilient via local config cache; the app is **not** fully offline-capable for all business modules.

---

## 9. Performance Optimizations

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

## 10. Localization

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

## 11. Security

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
- Secrets via environment only — never commit `.env`, service-account JSON, or `google-services.json`

> **Never commit** Firebase service-account JSON files, private keys, API secrets, database credentials, JWT secrets, or other sensitive credentials to Git. **Never paste credentials into this README.**

### Windows Remember Me (summary)

1. Sign in with Remember Me → tokens in secure storage (serialized writes).
2. Password never stored.
3. Full restart restores session from refresh/session tokens; expired access refreshes automatically.
4. Invalid refresh → session cleared → Sign in.
5. Remember Me **off** → tokens in memory only for the live process.
6. Android keeps existing always-persist-to-secure-storage behavior; Windows policy does not change mobile auth.

---

## 12. Technology Stack

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
| Realtime | Socket.IO (authenticated rooms; operational notifications) |
| Push (Android) | Firebase Cloud Messaging + Firebase Admin SDK (backend) |
| Excel | ExcelJS |
| Desktop | Windows |
| Mobile | Android |

---

## 13. Project Structure

```
infinity-fsm/
├── backend/                 # Node.js / Express API
│   ├── src/
│   │   ├── config/
│   │   ├── modules/
│   │   │   ├── core/        # auth, rbac, dashboard, users, settings, …
│   │   │   ├── business/    # attendance, overtime, work-orders, …
│   │   │   └── notifications/  # in-app + FCM + device tokens + hooks
│   │   ├── routes/          # /api/v1
│   │   ├── shared/          # middleware, utils
│   │   └── __tests__/
│   ├── scripts/             # seed & migrations
│   └── .env.example
├── mobile/                  # Flutter client (Android + Windows)
│   ├── lib/
│   │   ├── core/            # theme, router, l10n, DI, network, storage, push
│   │   ├── features/        # auth, dashboard, attendance, overtime, notifications, …
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

## 14. Development Setup

### Requirements

- Flutter SDK with Dart **^3.12**
- Node.js **≥ 20**
- npm
- MongoDB (local or Atlas) / configured backend
- Cloudinary account for production media uploads
- Windows desktop: Visual Studio **Desktop development with C++** workload
- Android push: Firebase project + `google-services.json` (local file, not committed)
- Backend push: Firebase Admin service-account credentials via environment (see §17–§18)

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

## 15. Testing

### Backend (Jest)

Under `backend/src/__tests__/`, including:

- Overtime calculation, calendar-day split, end-duration policy
- Dashboard overtime trends
- Overtime Excel export / timeline / approved hours
- Auth parallel role prefetch
- Dashboard live-activity / list-projection payload tests
- RBAC
- **Notification hooks** (copy builders, context fields)
- **Push delivery** (`notifications.push.test.js`)
- **Work order customer phones** and multi-assignee/location tests
- **Technician interface settings**

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
- **Technician interface offline local cache**
- **Push notification navigation** / pending intent mapping
- **Notifications unread seed**
- Work orders (customer phones, technician UI, form flows)
- Attendance areas as covered by existing suites

```bash
cd mobile
flutter test
flutter analyze
```

Recent ConnectivityService interface updates are covered by updated overtime test fakes (lifecycle, forensics, reconciliation, scheduler). Run those suites after connectivity changes.

> Do not treat analyzer “issue count” as error count — most findings are info/style; compile errors are separate.

---

## 16. Build & Release

### Android

```bash
cd mobile
flutter clean
flutter pub get
flutter build apk --release
# optional Play Store bundle:
flutter build appbundle --release
```

Typical APK output:

`mobile/build/app/outputs/flutter-apk/app-release.apk`

### Windows

```bash
cd mobile
flutter clean
flutter pub get
flutter build windows --release
```

Output:

`mobile/build/windows/x64/runner/Release/` (executable name `mobile.exe`; window title **INFINITY**)

Windows builds require Visual Studio C++ tooling, CMake, and NuGet (Flutter downloads NuGet when needed). **`firebase_core`** may download/extract the Firebase C++ SDK during Windows builds — low disk space on `C:` or OneDrive paths can cause extraction failures. See `mobile/windows/FIREBASE_CPP_SDK.md` for optional pre-extracted SDK setup.

Optional installer: root `installer.iss` (Inno Setup) packages the Windows Release build.

Release APK and Windows builds have been successfully produced in project validation. Build success depends on the local toolchain and environment — do not assume every machine will succeed without the prerequisites above.

Do not commit signing keystores, API secrets, `.env`, `google-services.json`, or Firebase service-account JSON files.

---

## 17. Environment Variables

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
| `FCM_ENABLED` | `true` / `false` — disable push without removing code |
| `FIREBASE_SERVICE_ACCOUNT_JSON` | **Option A:** full service-account JSON as one line (recommended on Render) |
| `FIREBASE_SERVICE_ACCOUNT_PATH` | **Option B:** absolute path to service-account JSON file (local dev) |
| `DEVICE_CLOCK_SKEW_SECONDS` | Clock drift allowance |
| `ATTENDANCE_GPS_ACCURACY_THRESHOLD_METERS` | Attendance GPS gate |
| `OVERTIME_MAX_SESSION_HOURS` | Soft review threshold (default `16`) |
| `OVERTIME_MAX_REQUEST_HOURS` / `OVERTIME_MIN_REQUEST_HOURS` | Request bounds |
| `OVERTIME_GPS_ACCURACY_THRESHOLD_METERS` | Overtime GPS gate |

**FCM credentials:** provide **either** `FIREBASE_SERVICE_ACCOUNT_JSON` **or** `FIREBASE_SERVICE_ACCOUNT_PATH` — not both required. Push is enabled when `FCM_ENABLED` is not `false` and credentials resolve.

**Client:** `--dart-define=API_BASE_URL=...` and `--dart-define=ENV=development|production`.

> **Security:** Never commit Firebase service-account JSON files, private keys, API secrets, database credentials, JWT secrets, or other sensitive credentials to Git.

---

## 18. Firebase Integration

| Component | Configuration |
|-----------|---------------|
| **Android app ID** | `com.example.mobile` (`mobile/android/app/build.gradle.kts`) |
| **Android client config** | `mobile/android/app/google-services.json` (from Firebase console; use `google-services.json.example` locally) |
| **Flutter Firebase options** | `mobile/lib/core/push/firebase_options.dart` (synced from Android config via `mobile/tool/sync_firebase_options.js`) |
| **Android FCM** | `firebase_core` + `firebase_messaging`; default channel `infinity_default`; app name **INFINITY** |
| **Backend FCM** | Firebase Admin SDK — `backend/src/modules/notifications/fcm.service.js` |
| **Windows** | `firebase_core` Windows native dependency for plugin compatibility; **push delivery on Windows uses Socket.IO**, not FCM |

### Backend setup (Render / local)

1. Create a Firebase project and enable Cloud Messaging.
2. Add an Android app with package name **`com.example.mobile`**.
3. Download `google-services.json` into `mobile/android/app/` (**gitignored** — do not commit).
4. Create a Firebase **service account** with FCM permissions.
5. Configure the backend with **one** of:
   - `FIREBASE_SERVICE_ACCOUNT_JSON=<paste JSON as single line>` (Render secret), or
   - `FIREBASE_SERVICE_ACCOUNT_PATH=/absolute/path/to/service-account.json` (local only)
6. Set `FCM_ENABLED=true` (or `false` to disable push during development).

**Do not** commit service-account JSON, private keys, or `google-services.json` contents to the repository or this README.

---

## 19. Deployment

| Component | Current state |
|-----------|---------------|
| **Backend API** | Production base URL: `https://infinity-fsm-api.onrender.com/api/v1` (`EnvConfig.productionApiBaseUrl`). Hosted on **Render**. Configure MongoDB, JWT, Cloudinary, CORS, Socket.IO, and Firebase Admin via Render environment secrets. |
| **Mobile / Desktop** | Distributed as **built artifacts** (Android APK/AAB, Windows Release folder / optional Inno Setup installer) — not a separate hosted web frontend. |
| **`infra/`** | Planning notes only (Docker/CI planned). No live Docker/CI pipeline configs are required to run the app today. |

Typical backend release flow:

```
Local changes
    ↓
Tests / validation (npm test · flutter test · flutter analyze)
    ↓
Git commit
    ↓
GitHub
    ↓
Render deployment (manual or connected service — configure in Render dashboard)
    ↓
Backend live
```

Bind the API to the platform port (`PORT`) and keep secrets in the host environment — never in the repository.

---

## 20. API Overview

Primary mount: **`/api/v1`**

| Group | Path prefix | Notes |
|-------|-------------|--------|
| Health | `/health`, `/health/ready` | Liveness / readiness |
| Auth | `/auth` | `POST /login`, `POST /refresh`, `POST /logout`, `GET /me` |
| Dashboard | `/dashboard` | Role summary & related stats |
| Overtime | `/overtime` | Journey, review, export |
| Attendance | `/attendance` | Clock / history / admin |
| Work Orders | `/work-orders` | CRUD & workflow |
| **Notifications** | `/notifications` | In-app inbox, unread count, mark-as-read, device tokens |
| Settings | `/settings` | Including technician interface config |
| Organization | `/organization` | Company / org |
| Users / Roles | `/users`, `/roles` | Admin RBAC |
| Inventory / Assets / PM | `/inventory`, `/assets`, `/pm` | Operations modules |
| Reports | `/reports` | Operational reports |
| Time / Security | `/time`, `/security` | Platform helpers |

Fuller catalog: [docs/API.md](./docs/API.md). Prefer **mounted routes in code** over older planned docs. There is **no** dedicated `/search` API; global search queries existing module endpoints client-side.

Realtime notification events are emitted on Socket.IO (`notification:new`) to authenticated user rooms.

---

## 21. Performance Notes

- Avoid global caching of **real-time** overtime running state
- Dashboard uses **controlled, short-lived** deduplication (in-flight + ~5s fresh reuse) — not a long-lived stale cache
- List endpoints use **lightweight projections**; detail endpoints retain full data
- Auth parallelization reduces sequential Mongo round-trips; DB validation stays authoritative
- Load balancing / Redis are **not** part of the current required architecture based on measured bottlenecks (Atlas RTT + sequential client calls remain the primary latency drivers)

---

## 22. Important Implementation Notes

| Topic | Guarantee |
|-------|-----------|
| Overtime math | Calculation logic lives in backend policy/calculator — separate from UI formatting |
| Admin review | Approve / Partial / Reject behavior preserved |
| Technician UI | Hides technical metadata where designed; admin retains detailed review data |
| Rejection reason | Visible to technician in history when present |
| Offline | Overtime actions persisted and retried; reconciliation when server already confirmed a stage |
| Technician Interface | Company-scoped; Admin/Supervisor navigation unrestricted; **offline cache per company** |
| Notifications | Persist → Socket.IO → FCM (Android); push failures do not fail business operations |
| Maps | OpenStreetMap only |
| SessionQueryCache | Used to avoid duplicate network fetches where wired |
| Dashboard loading | Prefer `isRefreshing` / cached summary over full-page loaders when data exists |
| Product name | **INFINITY** in UI / Windows title; package `mobile` unchanged |

| Product name | **INFINITY** in UI / Windows title; package `mobile` unchanged; Android `applicationId` `com.example.mobile` |

---

## 23. Recent Updates

Recent shipped improvements (verify in code before relying on docs alone):

- Work order **customer phone numbers** (optional multi-number support + Call action)
- **Technician-simplified** work-order detail (permission-aware admin metadata hiding)
- **Admin-controlled technician interface visibility** with **offline per-company cache**
- **Notifications module** — in-app center, persistence, unread state, mark-as-read
- **Firebase Cloud Messaging** on Android + Firebase Admin on backend
- **Socket.IO** realtime notifications (including Windows while app is running)
- Professional **notification copy** with technician/customer/site context
- **Notification deep links**, pending navigation, idempotent tap handling, Windows focus on click
- Clear overtime wording: **إنهاء العمل في الموقع** vs **إنهاء رحلة العمل الإضافي**
- Android **core library desugaring** for `flutter_local_notifications`
- Windows **Firebase C++ SDK** optional pre-extract path (`mobile/windows/FIREBASE_CPP_SDK.md`)

---

## 24. Troubleshooting

| Symptom | Likely cause / check |
|---------|----------------------|
| Android push never arrives | Missing/invalid `google-services.json`; `DefaultFirebaseOptions.isConfigured` false; backend `FCM_ENABLED` or Firebase Admin credentials missing |
| FCM works but no tap navigation | Auth/router not ready — pending navigation should consume after login; verify `PushNotificationService` |
| Windows no notifications when app closed | Expected — Windows uses Socket.IO while the process is running, not FCM background push |
| Windows build fails on Firebase SDK extract | Low `C:` disk space or OneDrive path — see `mobile/windows/FIREBASE_CPP_SDK.md` |
| Technician sees all tabs offline | Ensure app version with local interface cache; verify prior online sync stored config for the company |
| Admin changed interface; technician still sees old tabs offline | Expected until connectivity returns and `TechnicianInterfaceCubit.load()` succeeds |
| Render push skipped | Set `FIREBASE_SERVICE_ACCOUNT_JSON` secret; confirm `FCM_ENABLED=true` |
| Notification permission denied (Android 13+) | User must grant POST_NOTIFICATIONS in system settings |

---

## 25. Documentation

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

## 26. License

Released under the [MIT License](./LICENSE).

---

## 27. Author

**Mazen Mahmoud** — Total-Com Solutions

Built as an enterprise Field Service Management platform for real-world technician and workforce operations.
