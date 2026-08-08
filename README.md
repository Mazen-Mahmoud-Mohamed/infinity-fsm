# Infinity FSM

**Enterprise Field Service Management for maintenance companies and field workforce teams**

Infinity FSM is a production-oriented **employee / workforce management** and Field Service Management (FSM) platform. It helps organizations manage technicians in the field with attendance, overtime journeys, work orders, inventory, assets, preventive maintenance, service reports, dashboards, and role-based administration — from a single Flutter client and Node.js API.

| Layer | Stack |
|-------|--------|
| **Client** | Flutter · Material 3 · Clean Architecture · Cubit (`flutter_bloc`) · Repository Pattern |
| **API** | Node.js · Express · MongoDB (Mongoose) · JWT · Socket.IO |
| **Media** | Cloudinary |
| **Locales** | English (LTR) · Arabic (RTL) |
| **Targets** | Android · Windows Desktop |

---

## Table of Contents

- [Project Overview](#project-overview)
- [Main Features](#main-features)
- [Dashboard](#dashboard)
- [Overtime Excel Export](#overtime-excel-export)
- [Export Ready / Save As Flow](#export-ready--save-as-flow)
- [Technology Stack](#technology-stack)
- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [UI / Design](#ui--design)
- [Important Implementation Notes](#important-implementation-notes)
- [Testing](#testing)
- [Setup / Installation](#setup--installation)
- [Development Commands](#development-commands)
- [Environment Variables](#environment-variables)
- [API Surface](#api-surface)
- [Security & Roles](#security--roles)
- [Documentation](#documentation)
- [License](#license)
- [Author](#author)

---

## Project Overview

Infinity FSM solves a practical operations problem: field teams need **one system** for clocking attendance, capturing overtime evidence (GPS, photos, voice), executing work orders, tracking stock and assets, scheduling preventive maintenance, and giving supervisors/admins clear analytics and control.

It is designed as an **enterprise workforce / FSM product**, not a single-purpose overtime tracker:

- Technicians capture evidence on phone or desktop.
- Supervisors review and approve overtime and oversee operations.
- Administrators configure users, roles, settings, media policy, and organization structure.

The Flutter app shares one codebase for **phone, tablet, and Windows desktop** (NavigationRail on wide layouts; bottom navigation on phones).

---

## Main Features

Features below are present in the repository (`mobile/lib/features/*` and `backend/src/modules/*`).

### Platform & access

| Feature | What exists |
|---------|-------------|
| **Authentication** | JWT access + refresh, secure token storage, login/session handling |
| **User management** | Admin user CRUD, password change/reset flows |
| **Roles & permissions** | RBAC with Admin / Supervisor / Technician scopes and granular permission checks |
| **Organization** | Company/organization hierarchy and settings |
| **Profile** | User profile and related settings |
| **Settings** | Theme, language, notifications preferences, overtime media settings, diagnostics / server management |
| **Localization** | Full English & Arabic via Flutter ARB / `gen-l10n`, including RTL |
| **Global search** | Client-side palette that searches across existing module APIs (users, work orders, assets, inventory, overtime, PM, reports) |
| **Notifications (UI)** | In-app notification center and bell; feed currently sourced from dashboard live activity / audit projections (dedicated `/notifications` API is planned, not mounted yet) |
| **Reports Center** | Hub for operational reports and export entry points |
| **Audit logging** | Server-side audit trail for settings and operational events |

### Operations modules

| Module | Capabilities |
|--------|--------------|
| **Attendance** | GPS clock in/out, selfie verification, personal/team history, admin review, connectivity-aware UX |
| **Work orders** | Create, assign, track, complete; attachments and timeline-oriented flows |
| **Overtime** | Multi-stage journeys (Start → Arrived → Finished Work → End), Normal & Travel types, overnight travel, GPS/maps/photos/voice, approve/reject (including partial approve), offline queue + sync |
| **Inventory** | Warehouses, parts, stock visibility (including low-stock style alerts on dashboard) |
| **Assets** | Asset registry and related workflows |
| **Preventive maintenance** | PM plans / schedules / history-oriented UI |
| **Service reports** | List, detail, generation/download, customer signature support |

### Overtime (field evidence)

```
Start Journey → Arrived at Work Site → Finished Work → End Journey
```

Each stage can capture GPS (accuracy, battery, network), reverse-geocoded address, photos, and an **independent stage voice note**. Maps use OpenStreetMap (`flutter_map`). Administrators configure voice duration/quality, photo compression, and upload policy under **Settings → Overtime Settings**, including an admin **Configuration Testing Lab** for safe local previews (no Cloudinary upload from the lab).

### Offline

- **Overtime** has the most complete offline path: local pending actions, sync on reconnect, upload-policy awareness.
- Attendance and other modules use offline banners / caching patterns where implemented.
- Repository interfaces are prepared for broader offline expansion.

---

## Dashboard

The **executive dashboard** (admin-focused layout; supervisor/technician variants also exist) is a dense, two-column analytics surface — not a stack of oversized metric cards.

### Header & filters

- Compact welcome line (regular “Welcome back,” + semibold user name)
- Period filters: **Today · This Week · This Month · This Year · Custom**
- Report range label for the active period

### KPI strip

Compact strip of primary KPIs (when data is available), for example:

- Total employees  
- Currently working  
- Total working hours  
- Overtime / approved hours  
- Attendance rate  

### Main layout (desktop / tablet)

**Main column**

- Workforce overview (totals, active, currently working, average hours + progress)
- **Overtime Analytics** (KPI row + embedded charts + technician table)
- Trends (attendance / work orders / overtime / PM where series exist) with 7 / 30 day window

**Side column**

- Operations (work order + PM status list with status colors)
- Resources (inventory / asset alerts and counts)
- Recent notifications / activity feed

### Overtime analytics on dashboard

- Approved hours, trips, overnight trips, technicians  
- Charts: hours per technician, trips per technician, hours over time  
- **Technician Summary** as a compact table (name, approved hours, trips, overnight, avg hours/trip) — not large per-technician cards  

### Typography

Dashboard text uses a centralized **`DashboardTypography`** helper (`mobile/lib/features/dashboard/presentation/widgets/dashboard_typography.dart`) for consistent page titles, section titles, KPI values/labels, list/table/chart styles — built on the app `Theme` / `AppTypography` (no separate random font stack).

### Data behavior

- Uses existing executive dashboard Cubit + summary APIs  
- Prefers cached data / refresh indicators (`isRefreshing`) over full-page loading when data already exists  
- Role-aware sections (admin dense layout; other roles keep their section builders)

---

## Overtime Excel Export

Authorized **Admin / Supervisor** users can export overtime workbooks generated on the backend with **ExcelJS**.

### Modes

| Mode | Contents |
|------|----------|
| **Summary** | Summary sheet only |
| **Detailed** | Summary + **Sessions Index** + **one worksheet per session** (with overflow sheet when volume exceeds the detailed sheet cap) |

### Report language

Export dialog supports **English** and **العربية**. Selected language localizes human-readable labels. Not translated: IDs, emails, GPS coordinates, device/network values, and other raw technical identifiers.

### Summary sheet

- Report metadata (company, generated by/at, version, export type, date range, filters, language)
- KPI grid including:
  - Total technicians  
  - Total calculated / worked hours  
  - Total approved hours  
  - Total sessions / trips  
  - Travel · Normal · Overnight session counts  
  - Approved · Pending/review · Rejected session counts  
- **Employee summary table** (one row per technician): name, email, worked hours, approved hours, session counts by type/status  

**Branch and Department are intentionally excluded** from export filters, columns, and labels.

### Detailed sheets

- Sessions index with identity and duration columns  
- Per-session printable sheets: overtime info, journey timeline, embedded photo thumbnails (when available), voice/maps hyperlinks, device context  
- Arabic workbooks use **RTL worksheet views** where language is Arabic  

### Arabic duration rendering

Durations are written as prose (e.g. `18 ساعة و 44 دقيقة`), never decimal hour strings like `14.95`. Arabic cells use Excel-compatible BiDi protection (LRM around digit runs + LRE…PDF embedding) and LTR reading order on duration cells so hours appear before minutes in Microsoft Excel.

---

## Export Ready / Save As Flow

After generation, the Flutter client writes the `.xlsx` to a temporary file and shows an **Export ready** dialog:

| Element | Behavior |
|---------|----------|
| **Title** | Export ready |
| **Content** | File icon, filename, sessions exported count |
| **Save As** (primary) | Opens the **native OS save dialog** via `file_selector` (`getSaveLocation`) on Windows / macOS / Linux — user picks folder + filename; `.xlsx` type group; file is **copied** to the chosen path |
| **Cancel Save As** | Returns to the dialog with **no error** |
| **Open File** | Opens with the system default app (`url_launcher`) |
| **Open Containing Folder** | Reveals the generated temp file in Explorer / Finder / file manager |
| **Close** | Dismisses the dialog |
| **Success / errors** | Inline success path after Save As; snackbars for open/save failures |

Mobile builds without native Save As fall back to share-oriented actions. The original generated temp file is kept when Save As is cancelled.

---

## Technology Stack

### Frontend / mobile (`mobile/pubspec.yaml`)

| Technology | Role |
|------------|------|
| Flutter / Dart (^3.12) | Cross-platform UI |
| Material 3 | Design system (light / dark / system) |
| `flutter_bloc` (Cubit) | State management |
| GetIt | Dependency injection |
| Dio | HTTP |
| GoRouter | Navigation (`StatefulShellRoute`) |
| `flutter_map` + latlong2 | OpenStreetMap |
| geolocator / geocoding | GPS + reverse geocoding |
| image_picker / image | Capture & compression |
| record / just_audio / just_audio_media_kit | Voice record & playback (Windows audio via media_kit) |
| flutter_secure_storage | Tokens |
| shared_preferences | Preferences / local caches |
| path_provider / path / share_plus / file_selector | File IO, share, native Save As |
| url_launcher | Open files / URLs |
| connectivity_plus / internet_connection_checker_plus | Connectivity |
| local_auth / device_info_plus / permission_handler / battery_plus | Device capabilities |
| timezone / intl | Time & formatting |
| cached_network_image / flutter_svg | Images |

### Backend (`backend/package.json`)

| Technology | Role |
|------------|------|
| Node.js ≥ 20 | Runtime |
| Express | HTTP API |
| Mongoose / MongoDB | Persistence |
| jsonwebtoken / bcrypt | Auth |
| Cloudinary | Media storage |
| exceljs | Overtime Excel workbooks |
| Socket.IO | Realtime foundation |
| Helmet / cors / express-rate-limit / express-validator | Hardening & validation |
| multer | Uploads |
| Pino / pino-http | Logging |
| Jest / Supertest / mongodb-memory-server | Backend tests (dev) |

---

## Architecture

### Flutter (Clean Architecture)

```
Presentation  →  Pages / Widgets + Cubits
Domain        →  Entities, Use Cases, Repository interfaces
Data          →  Models, datasources, Repository implementations
Core          →  Config, network, theme, router, localization, DI, shared widgets
Shared        →  Cross-feature presentation (e.g. profile)
```

Each feature under `mobile/lib/features/<name>/` follows this layering.

### Backend

```
Routes → Validators → Controllers → Services → Mongoose Models
```

Mounted under `/api/v1`. Platform concerns (auth, RBAC, settings, dashboard, user management, organization, time, security) live under `backend/src/modules/core/`. Business domains live under `backend/src/modules/business/`.

---

## Project Structure

```
infinity-fsm/
├── backend/
│   ├── src/
│   │   ├── config/
│   │   ├── modules/
│   │   │   ├── core/                 # auth, rbac, dashboard, users, settings, …
│   │   │   └── business/             # attendance, overtime, work-orders, inventory, …
│   │   ├── routes/                   # /api/v1
│   │   ├── shared/
│   │   └── __tests__/                # Jest suites
│   ├── scripts/                      # seed & migrations
│   └── .env.example
├── mobile/
│   ├── lib/
│   │   ├── core/                     # theme, router, l10n, DI, network, widgets
│   │   ├── features/                 # auth, dashboard, attendance, overtime, …
│   │   └── shared/
│   ├── android/ · windows/ · ios/ · macos/
│   ├── test/                         # Flutter tests
│   └── assets/
├── docs/                             # Architecture, API, RBAC, roadmap, …
├── infra/
├── screenshots/                      # Optional captures for docs
├── LICENSE
└── README.md
```

---

## UI / Design

- Dark-friendly **desktop-style** shell with NavigationRail on wide screens  
- Compact, data-dense **executive dashboard** with consistent typography  
- Material 3 theming (no hard-coded one-off dashboard font family)  
- Responsive breakpoints: phone `< 600`, tablet `600–900`, desktop `≥ 900` (`AppBreakpoints`)  
- Charts and operational lists designed for quick scanning  
- Full **Arabic RTL** and **English LTR** support across UI and Excel exports  

---

## Important Implementation Notes

| Topic | Detail |
|-------|--------|
| **RBAC** | Permissions checked on client and protected backend routes |
| **Excel BiDi** | Arabic durations protected for Excel display; English unchanged |
| **Save As** | Native dialog via `file_selector` on desktop; cancel is silent |
| **Offline overtime** | Local queue + reconciliation/sync schedulers with forensic/trace helpers in tests |
| **SessionQueryCache** | Shared query cache to avoid duplicate network fetches |
| **Media** | Cloudinary for production uploads; Configuration Lab stays local-only |
| **Maps** | OpenStreetMap — not Google Maps SDK |

---

## Testing

### Backend (Jest)

Located under `backend/src/__tests__/`, including:

- `overtime.excel.export.test.js` — Excel workbook structure, i18n, Arabic durations, no Branch/Department columns  
- `overtime.calculation.test.js`, `overtime.approved-hours.test.js`, `overtime.timeline.test.js`  
- `rbac.test.js`  

```bash
cd backend
npm test
# or focus Excel export:
npm test -- --testPathPattern=overtime.excel.export
```

### Flutter

Located under `mobile/test/`, including overtime calculator / offline lifecycle / sync / photo compressor / duration formatter / API URL normalizer / widget tests.

```bash
cd mobile
flutter test
flutter analyze
```

Run the commands locally to obtain current pass/fail results for your environment.

---

## Setup / Installation

### Prerequisites

- **Node.js 20+**
- **MongoDB 6+** (local or Atlas)
- **Flutter SDK** with Dart **3.12+** (see `mobile/pubspec.yaml`)
- **Cloudinary** account for production media uploads

### Backend

```bash
cd backend
cp .env.example .env    # set MONGODB_URI, JWT secrets, Cloudinary, etc.
npm install
npm run seed            # optional demo data
npm run dev             # http://localhost:3000  (node --watch)
```

Health:

```bash
curl http://localhost:3000/api/v1/health
curl http://localhost:3000/api/v1/health/ready
```

### Flutter client

```bash
cd mobile
flutter pub get
flutter gen-l10n
flutter run
```

Windows desktop:

```bash
cd mobile
flutter pub get
flutter run -d windows
```

Release APK:

```bash
cd mobile
flutter build apk --release
```

Local API override (compile-time):

```bash
flutter run --dart-define=ENV=development --dart-define=API_BASE_URL=http://192.168.1.10:3000/api/v1
```

Default API base lives in `mobile/lib/core/config/env_config.dart`. Runtime **Server Management** can override the active API base without rebuilding (admin-protected).

---

## Development Commands

| Area | Command |
|------|---------|
| Backend install | `cd backend && npm install` |
| Backend dev | `cd backend && npm run dev` |
| Backend start | `cd backend && npm start` |
| Backend seed | `cd backend && npm run seed` |
| Backend test | `cd backend && npm test` |
| Backend lint | `cd backend && npm run lint` |
| Flutter deps | `cd mobile && flutter pub get` |
| Flutter l10n | `cd mobile && flutter gen-l10n` |
| Flutter run | `cd mobile && flutter run` |
| Flutter Windows | `cd mobile && flutter run -d windows` |
| Flutter analyze | `cd mobile && flutter analyze` |
| Flutter test | `cd mobile && flutter test` |
| Flutter APK | `cd mobile && flutter build apk --release` |

---

## Environment Variables

Copy `backend/.env.example` → `backend/.env`. **Never commit real secrets.**

| Variable | Purpose |
|----------|---------|
| `NODE_ENV` | `development` / `production` / `test` |
| `PORT` | API port (default `3000`) |
| `API_VERSION` | Version segment (default `v1`) |
| `MONGODB_URI` | MongoDB connection string |
| `JWT_ACCESS_SECRET` / `JWT_REFRESH_SECRET` | Token secrets (≥ 32 chars) |
| `JWT_ACCESS_EXPIRY` / `JWT_REFRESH_EXPIRY` | Token TTLs |
| `CORS_ORIGINS` | Allowed origins |
| `RATE_LIMIT_*` | Rate limiting |
| `LOG_LEVEL` | Pino level |
| `CLOUDINARY_*` | Media uploads |
| `SOCKET_CORS_ORIGINS` | Socket.IO CORS |
| `DEVICE_CLOCK_SKEW_SECONDS` | Clock drift allowance |
| `ATTENDANCE_GPS_ACCURACY_THRESHOLD_METERS` | Attendance GPS gate |
| `OVERTIME_*` | Overtime duration / GPS thresholds |

Client: `--dart-define=API_BASE_URL=...` and `--dart-define=ENV=development|production`.

---

## API Surface

Primary mount: **`/api/v1`**

```
/health
/health/ready
/auth
/organization
/attendance
/overtime          # includes /export for Excel
/work-orders
/inventory
/assets
/pm
/reports
/users
/roles
/settings
/time
/security
/dashboard
```

See [docs/API.md](./docs/API.md) for the fuller catalog. Some docs modules (e.g. dedicated notifications/search services) describe future endpoints that are not yet mounted in `routes/v1`.

---

## Security & Roles

- JWT access + refresh, bcrypt password hashing  
- Helmet, CORS allow-list, rate limiting  
- RBAC on protected routes  
- Device clock skew checks  
- GPS accuracy thresholds for attendance / overtime  
- Audit logging for sensitive settings changes  
- Secrets via environment only  

| Role | Typical scope |
|------|----------------|
| **Admin** | Users, roles, settings, inventory, assets, PM, reports, media policy, exports |
| **Supervisor** | Team oversight, overtime review/export, operational dashboards |
| **Technician** | Self attendance, overtime capture, assigned work orders |

See [docs/RBAC.md](./docs/RBAC.md).

---

## Documentation

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

> Prefer this README for the **current shipped UI/export behavior**. Some docs may still describe planned phases; when in doubt, trust the code under `mobile/` and `backend/src/`.

---

## License

Released under the [MIT License](./LICENSE).

---

## Author

**Mazen Mahmoud** — Total-Com Solutions

Built as an enterprise Field Service Management platform for real-world technician and workforce operations.
