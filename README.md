# Infinity FSM

**Production-grade Enterprise Field Service Management (FSM) platform**

[![Flutter](https://img.shields.io/badge/Flutter-Material%203-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Node.js](https://img.shields.io/badge/Node.js-20%2B-339933?logo=nodedotjs&logoColor=white)](https://nodejs.org)
[![MongoDB](https://img.shields.io/badge/MongoDB-Atlas-47A248?logo=mongodb&logoColor=white)](https://www.mongodb.com/atlas)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)

Infinity FSM is a full-stack enterprise Field Service Management platform for organizations that run technicians in the field. It unifies attendance, offline-first overtime journeys, GPS verification, live camera evidence, work orders, inventory, assets, preventive maintenance, service reports, user administration, and fine-grained RBAC in one coherent product.

Built with **Flutter** (Android & Windows Desktop), **Node.js / Express**, **MongoDB Atlas**, and **Cloudinary**, with a modern **Material 3** UI, **Arabic & English** localization (RTL/LTR), responsive layouts, OpenStreetMap GPS & maps, and enterprise role-based access control.

---

## Table of Contents

- [Highlights](#highlights)
- [Features](#features)
- [Offline Support](#offline-support)
- [Localization](#localization)
- [Technology Stack](#technology-stack)
- [Architecture](#architecture)
- [Desktop & Responsive UI](#desktop--responsive-ui)
- [Screenshots](#screenshots)
- [Project Structure](#project-structure)
- [Documentation](#documentation)
- [Getting Started](#getting-started)
- [Environment Variables](#environment-variables)
- [API Structure](#api-structure)
- [Security](#security)
- [Roles & Permissions](#roles--permissions)
- [Latest Improvements](#latest-improvements)
- [Roadmap](#roadmap)
- [License](#license)
- [Author](#author)

---

## Highlights

| Capability | Support |
|------------|---------|
| Android | ✅ |
| Windows Desktop | ✅ |
| Responsive phone / tablet / desktop layouts | ✅ |
| Arabic & English (RTL / LTR) | ✅ |
| Offline-first overtime (+ attendance sync hooks) | ✅ |
| Enterprise RBAC with localized permissions | ✅ |
| GPS, reverse geocoding & OpenStreetMap | ✅ |
| Cloudinary image storage | ✅ |
| Material 3 light / dark / system themes | ✅ |
| Runtime API URL switching (Server Management) | ✅ |

---

## Features

### Authentication

- JWT access + refresh token authentication
- Secure login with local session persistence
- Profile management
- Avatar / profile photo upload (Cloudinary)
- Change password (authenticated users)
- Biometric unlock on supported devices (used to protect Server Management access)

### Dashboard

- Role-aware enterprise dashboard (Admin / Supervisor / Technician)
- KPI cards and operational statistics
- Charts and trend views
- Quick actions into primary modules
- In-app notification feed entry points

### Attendance

- GPS-backed clock in / out with accuracy checks
- Live selfie verification for attendance evidence
- Personal attendance history
- Team attendance views (permission-scoped)
- Admin review workflows
- Offline capture with sync when connectivity returns

### Overtime

Complete field overtime journey with evidence and admin control:

- Offline-first overtime sessions with automatic synchronization
- Pending action queue and local persistence
- Multi-stage GPS checkpoints:
  - Start Journey
  - Arrived at Work Site
  - Finished Work
  - End Journey
- Journey Timeline with stage evidence
- Journey Overview map (markers, polyline, legend)
- Open Live Location for map viewing
- Per-checkpoint GPS accuracy, battery, network status, and reverse-geocoded address
- Stage selfies / photos
- Normal and travel overtime types
- Admin approval and rejection
- Interactive desktop overtime detail layout (timeline + map focus)

### Work Orders

- Create, assign, track, and complete field work orders
- Staged execution with attachments, locations, and timeline
- Desktop split detail layout (execution + context sidebar)

### Preventive Maintenance

- PM plans
- PM schedules
- PM history
- Checklist builder

### Inventory

- Warehouses
- Spare parts catalog
- Stock history / movements
- Low-stock visibility on operational dashboards

### Assets

- Asset registry and management
- Asset categories
- Asset history
- QR-oriented asset workflows

### Service Reports

- Service reports list and dashboard
- Report detail views
- Generation / download flows (permission-scoped)
- Customer signature support where enabled

### User Management & Organization

- Users lifecycle (view / create / update / delete — permission-scoped)
- Roles & Permissions administration
- Departments and organization hierarchy (branches, regions, teams as permitted)
- Admin password reset permission for user accounts

### Enterprise RBAC

- Role management (view / create / update / delete)
- Permission catalog grouped by module
- Localized permission names (EN / AR)
- Human-readable permission descriptions (what / where / whose data)
- Search across permission titles, descriptions, and groups
- Desktop tooltips and keyboard-accessible descriptions
- Presentation-only labels — backend permission keys remain unchanged

### Settings

Enterprise settings hub (responsive list on phone; split panel on desktop):

- Theme (System / Light / Dark) — exclusive control of the real app theme
- Theme Preview (visual showcase only; does not change app theme)
- Language (English / Arabic)
- Notification preferences
- Organization / company settings
- Performance overview
- About
- Update Center
- Diagnostics
- **Server Management** — runtime backend URL configuration, connection test, ping, and diagnostics export **without rebuilding the app** (protected access; biometric unlock on supported devices)

---

## Offline Support

Infinity FSM is designed for unreliable field connectivity, with overtime as the primary offline-first workflow:

- **Offline overtime sessions** — start / checkpoint / end while offline
- **Local storage** — SharedPreferences-backed caches and pending queues
- **Automatic synchronization** — pending actions drain when the device reconnects
- **Queue visibility** — offline / pending indicators in the UI
- **Attendance offline hooks** — offline attendance records with later sync
- **Connectivity awareness** — offline banners and soft-refresh behavior
- **Repository interfaces** prepared for broader module offline expansion

> Full offline execution for every module continues to expand; overtime is the most complete offline path today.

---

## Localization

- **English (LTR)** and **Arabic (RTL)** via Flutter ARB + `gen-l10n`
- Locale-aware dates and number formatting through shared formatters
- Enterprise localization pass across primary modules
- Localized Roles & Permissions (group titles, permission titles, and descriptions)
- Consistent terminology for core modules (Dashboard, Attendance, Overtime, Work Orders, Inventory, Assets, Maintenance, Settings, etc.)
- Human-friendly error mapping (`localizeAppMessage`) instead of raw API English on failure screens

---

## Technology Stack

### Frontend

| Technology | Role |
|------------|------|
| Flutter | Cross-platform UI (Android, Windows) |
| Dart | Client language |
| Material 3 | Design system (light / dark) |
| flutter_bloc (Cubit) | State management |
| get_it | Dependency injection |
| Dio | HTTP client |
| go_router | Navigation (`StatefulShellRoute`) |
| flutter_map | OpenStreetMap rendering |
| geolocator / geocoding | GPS + reverse geocoding |
| SharedPreferences | Local preferences & offline caches |
| flutter_secure_storage | Secure token storage |
| local_auth | Biometric unlock (supported devices) |
| Cloudinary-delivered media | Avatars, selfies, attachments |

### Backend

| Technology | Role |
|------------|------|
| Node.js 20+ | Runtime |
| Express | HTTP API |
| MongoDB Atlas / Mongoose | Primary database |
| JWT | Access + refresh authentication |
| Cloudinary | Cloud image / media storage |
| Multer | Multipart upload handling |
| Socket.IO | Realtime foundation |
| Pino | Structured logging |
| Helmet / rate limiting / CORS | API hardening |

---

## Architecture

### Flutter — Clean Architecture

```
Presentation  →  Pages / Widgets + Cubits (flutter_bloc)
Domain        →  Entities, Use Cases, Repository interfaces
Data          →  Models, Remote/Local datasources, Repository implementations
```

Cross-cutting concerns live under `mobile/lib/core/` (config, network, theme, router, localization, shared widgets, DI).

Routing uses **`go_router`** with a **`StatefulShellRoute.indexedStack`** for the Desktop Shell and phone bottom navigation.

### Backend — Modular API

```
Routes → Validators → Controllers → Services → Mongoose Models
```

```
Platform Core (stable)                 Business Modules
──────────────────────                 ────────────────
Auth & JWT                             Attendance
RBAC / Permissions                     Overtime (+ travel OT)
Organization hierarchy                 Work Orders
Settings / Configuration               Inventory
Notifications foundation               Assets
Audit logging                          Preventive Maintenance
File storage (Cloudinary)              Service Reports
Maps / GPS utilities                   Dashboard analytics
Sync foundations                       User Management
```

---

## Desktop & Responsive UI

### Desktop Shell

- Persistent **NavigationRail** for primary modules
- Shell-branch navigation (content swaps inside the shell)
- Shared **`AppPageFrame`**, desktop stat grids, action cards, and split views
- Settings split panel (section list + content)
- Desktop overtime detail with interactive map / timeline focus

### Breakpoints

| Breakpoint | Width | Chrome |
|------------|-------|--------|
| Phone | `< 600` | Bottom `NavigationBar` |
| Tablet | `600–900` | Adaptive padding / compact rail |
| Desktop | `≥ 900` | Extended `NavigationRail` |

### Primary desktop modules

Dashboard · Attendance · Work Orders · Overtime · Profile · Inventory · Assets · Preventive Maintenance · Service Reports · User Management · Roles & Permissions · Settings

Phone bottom navigation focuses on day-to-day modules: Dashboard, Attendance, Work Orders, Overtime, Profile.

---

## Screenshots

> Replace placeholders in `/screenshots` with real captures before publishing.  
> See [screenshots/README.md](./screenshots/README.md) for suggested filenames.

### Mobile / general

| Screen | Light | Dark |
|--------|-------|------|
| Login | ![Login](./screenshots/login.png) | ![Login Dark](./screenshots/login-dark.png) |
| Dashboard | ![Dashboard](./screenshots/dashboard.png) | ![Dashboard Dark](./screenshots/dashboard-dark.png) |
| Attendance | ![Attendance](./screenshots/attendance.png) | |
| Overtime Journey | ![Overtime](./screenshots/overtime.png) | |
| Work Orders | ![Work Orders](./screenshots/work-orders.png) | |
| Inventory | ![Inventory](./screenshots/inventory.png) | |
| Assets | ![Assets](./screenshots/assets.png) | |
| Preventive Maintenance | ![PM](./screenshots/pm.png) | |
| Service Reports | ![Reports](./screenshots/reports.png) | |
| Roles & Permissions | ![Roles](./screenshots/roles.png) | |
| Settings / Theme | ![Settings](./screenshots/settings.png) | |

### Desktop (placeholders)

| Screen | Capture |
|--------|---------|
| Desktop Shell / Dashboard | ![Desktop Dashboard](./screenshots/desktop-dashboard.png) |
| Desktop Overtime Detail | ![Desktop Overtime](./screenshots/desktop-overtime.png) |
| Desktop Work Order Detail | ![Desktop Work Order](./screenshots/desktop-work-order.png) |
| Desktop Inventory Hub | ![Desktop Inventory](./screenshots/desktop-inventory.png) |
| Desktop User Management | ![Desktop Users](./screenshots/desktop-users.png) |
| Desktop Roles & Permissions | ![Desktop Roles](./screenshots/desktop-roles.png) |
| Desktop Settings | ![Desktop Settings](./screenshots/desktop-settings.png) |

---

## Project Structure

```
infinity-fsm/
├── backend/                      # Node.js + Express API
│   ├── src/
│   │   ├── config/               # Env, Cloudinary, DB
│   │   ├── modules/
│   │   │   ├── core/             # auth, rbac, organization, settings, dashboard, users, ...
│   │   │   └── business/         # attendance, overtime, work-orders, inventory, assets, pm, reports
│   │   ├── routes/               # /api/v1 mounting
│   │   └── shared/               # middleware, errors, utils, constants
│   ├── scripts/                  # seed & migrations
│   └── .env.example
├── mobile/                       # Flutter application
│   ├── lib/
│   │   ├── core/                 # config, network, theme, router, l10n, widgets, DI
│   │   ├── features/             # Clean Architecture feature modules
│   │   └── shared/               # cross-feature presentation (e.g. profile)
│   ├── windows/                  # Desktop runner
│   └── assets/
├── docs/                         # Architecture & API documentation
├── infra/                        # Docker / CI / deployment planning
├── scripts/                      # Ops helpers
├── tests/                        # Cross-cutting test assets
├── screenshots/                  # README screenshot placeholders
├── README.md
└── LICENSE
```

---

## Documentation

| Document | Description |
|----------|-------------|
| [Architecture](./docs/ARCHITECTURE.md) | Platform core, modules, ADRs |
| [Database Schema](./docs/DATABASE.md) | Collections, indexes, relationships |
| [REST API](./docs/API.md) | Endpoint catalog |
| [RBAC](./docs/RBAC.md) | Roles, permissions, scope |
| [Socket.IO Events](./docs/SOCKET_EVENTS.md) | Realtime event catalog |
| [Testing Strategy](./docs/TESTING.md) | Unit, integration, E2E |
| [Non-Functional Requirements](./docs/NFR.md) | Performance, security, DR |
| [Module Registry](./docs/MODULE_REGISTRY.md) | Module catalog |
| [Roadmap](./docs/ROADMAP.md) | Delivery phases |
| [Future Improvements](./docs/FUTURE_IMPROVEMENTS.md) | Post-MVP ideas |

---

## Getting Started

### Prerequisites

- Node.js **20+**
- MongoDB **6+** (local or **MongoDB Atlas**)
- Flutter SDK with **Dart 3.12+** (see `mobile/pubspec.yaml`)
- Cloudinary account (required for production media uploads)

### Backend

```bash
cd backend
cp .env.example .env   # fill MONGODB_URI, JWT secrets, Cloudinary, etc.
npm install
npm run seed           # optional demo data
npm run dev            # http://localhost:3000
```

Health check:

```bash
curl http://localhost:3000/api/v1/health
```

### Frontend

```bash
cd mobile
flutter pub get
flutter gen-l10n
flutter run
```

#### Windows Desktop

```bash
cd mobile
flutter pub get
flutter run -d windows
```

#### Release APK

```bash
cd mobile
flutter build apk --release
```

#### Local API override (compile-time)

```bash
flutter run --dart-define=ENV=development --dart-define=API_BASE_URL=http://192.168.1.10:3000/api/v1
```

> Default production API base is configured in `mobile/lib/core/config/env_config.dart`.  
> At runtime, **Server Management** can switch the active API base URL without rebuilding (admin-protected).

---

## Environment Variables

Copy `backend/.env.example` to `backend/.env` and provide real values. **Never commit `backend/.env`.**

### Backend

| Variable | Description |
|----------|-------------|
| `NODE_ENV` | `development` / `production` / `test` |
| `PORT` | API port (default `3000`) |
| `API_VERSION` | API version segment (default `v1`) |
| `MONGODB_URI` | MongoDB / Atlas connection string |
| `JWT_ACCESS_SECRET` | Access token secret (≥ 32 chars) |
| `JWT_SECRET` | Alias for `JWT_ACCESS_SECRET` |
| `JWT_REFRESH_SECRET` | Refresh token secret (≥ 32 chars) |
| `JWT_ACCESS_EXPIRY` | Access token TTL (default `15m`) |
| `JWT_REFRESH_EXPIRY` | Refresh token TTL (default `7d`) |
| `CORS_ORIGINS` | Comma-separated allowed origins |
| `RATE_LIMIT_WINDOW_MS` | Rate-limit window |
| `RATE_LIMIT_MAX` | Max requests per window |
| `RATE_LIMIT_AUTH_MAX` | Max auth requests per window |
| `LOG_LEVEL` | Pino log level |
| `CLOUDINARY_CLOUD_NAME` | Cloudinary cloud name |
| `CLOUDINARY_API_KEY` | Cloudinary API key |
| `CLOUDINARY_API_SECRET` | Cloudinary API secret |
| `SOCKET_CORS_ORIGINS` | Socket.IO CORS origins |
| `DEVICE_CLOCK_SKEW_SECONDS` | Allowed device clock drift |
| `ATTENDANCE_GPS_ACCURACY_THRESHOLD_METERS` | Max GPS accuracy for attendance |
| `OVERTIME_MAX_REQUEST_HOURS` | Max overtime request length |
| `OVERTIME_MIN_REQUEST_HOURS` | Min overtime request length |
| `OVERTIME_MAX_SESSION_HOURS` | Max live overtime session length |
| `OVERTIME_GPS_ACCURACY_THRESHOLD_METERS` | Max GPS accuracy for overtime |

### Frontend

| Configuration | Description |
|---------------|-------------|
| `--dart-define=API_BASE_URL=...` | Compile-time REST base URL including `/api/v1` |
| `--dart-define=ENV=development\|production` | Client environment / logging behavior |
| Server Management (in-app) | Runtime API base URL override, connection test, ping, diagnostics export |

---

## API Structure

```
/api/v1
├── /health
├── /health/ready
├── /auth
├── /users
├── /roles
├── /organization
├── /attendance
├── /overtime
├── /work-orders
├── /inventory
├── /assets
├── /pm
├── /reports
├── /dashboard
├── /settings
├── /security
└── /time
```

See [docs/API.md](./docs/API.md) for the full catalog.

---

## Security

- JWT access + refresh token rotation
- Password hashing (bcrypt)
- Helmet hardening
- Rate limiting (global + auth)
- CORS allow-list
- RBAC permission checks on protected routes
- Device clock skew detection
- Mandatory live camera capture for attendance / overtime evidence
- GPS accuracy thresholds
- Audit logging foundation
- Secrets via environment variables only
- Biometric-gated Server Management access on supported devices

---

## Roles & Permissions

| Role | Typical scope |
|------|----------------|
| **Admin** | Company-wide configuration, users, roles, inventory, assets, PM, reports |
| **Supervisor** | Team attendance, overtime review, work order oversight |
| **Technician** | Self attendance, overtime, assigned work orders |

User Management and Roles & Permissions are **top-level Desktop Shell modules**. Settings focuses on theme, language, notifications, organization, diagnostics, and about.

The Roles UI presents localized permission groups with searchable titles and one-sentence descriptions so non-technical administrators can understand each grant.

See [docs/RBAC.md](./docs/RBAC.md).

---

## Latest Improvements

Recent product and UX work reflected in the current codebase:

- Offline overtime queue, local persistence, and automatic sync
- Journey Overview map (markers, polyline, legend) + Journey Timeline
- Multi-stage overtime checkpoints with GPS / battery / network / address / selfie evidence
- Interactive desktop overtime detail (timeline ↔ map focus)
- Runtime **Server Management** (API URL switching without rebuild)
- Enterprise Settings hub (theme, language, notifications, organization, performance, diagnostics, update center, about)
- Theme Preview redesign (visual showcase only; app theme controlled solely by the top selector)
- Full localization audit (EN / AR, RTL / LTR)
- Enterprise RBAC localization (permission names, descriptions, groups, search, tooltips)
- Desktop Shell / NavigationRail polish and responsive settings layouts
- Avatar upload and profile presentation improvements
- Biometric protection for sensitive settings entry points
- Dark mode polish across Material 3 surfaces
- Human-friendly error localization on failure screens

---

## Roadmap

### Completed

- [x] Platform core (auth, RBAC, organization, settings)
- [x] Attendance with GPS + live selfie verification
- [x] Offline-first overtime journey + admin review
- [x] Work Orders, Inventory, Assets, PM, Service Reports
- [x] Desktop Shell + responsive Material 3 UI
- [x] Arabic / English localization with RTL
- [x] Cloudinary media pipeline
- [x] Runtime Server Management & diagnostics
- [x] Localized Roles & Permissions UX

### Planned

- [ ] Deeper offline sync and conflict resolution across remaining modules
- [ ] Push notifications (FCM / APNs)
- [ ] Advanced analytics and payroll exports
- [ ] Vehicles module UI
- [ ] Expanded scheduling and customer CRM
- [ ] Hardened production deployment (Docker, CI/CD, monitoring)

See [docs/ROADMAP.md](./docs/ROADMAP.md) and [docs/FUTURE_IMPROVEMENTS.md](./docs/FUTURE_IMPROVEMENTS.md).

---

## License

Released under the [MIT License](./LICENSE).

---

## Author

**Mazen Mahmoud** — Total-Com Solutions

Built as an enterprise Field Service Management platform for real-world technician operations.
