# Infinity FSM

**Enterprise Field Service Management Platform**

Infinity FSM is a production-oriented Field Service Management (FSM) system for companies that manage technicians in the field. It unifies attendance, overtime (including travel overtime), GPS verification, live camera capture, work orders, inventory, assets, preventive maintenance, service reports, user management, and fine-grained RBAC in one coherent platform.

The Flutter client targets **phones, tablets, and desktop (Windows)** with a shared responsive design system. Desktop uses a unified **Desktop Shell** with a persistent `NavigationRail` and shell-branch navigation. The backend is a modular Node.js / Express / MongoDB API with JWT auth, Cloudinary media, and a Socket.IO foundation.

Designed for real field operations. Built with Clean Architecture on the client and a platform-first modular API on the server. Offline-ready repository interfaces are in place for future sync.

---

## Table of Contents

- [Features](#-features)
- [Desktop Experience](#-desktop-experience)
- [Responsive UI](#-responsive-ui)
- [Architecture](#-architecture)
- [Tech Stack](#-tech-stack)
- [Screenshots](#-screenshots)
- [Project Structure](#-project-structure)
- [Documentation](#-documentation)
- [Installation](#-installation)
- [Backend Setup](#-backend-setup)
- [Flutter Setup](#-flutter-setup)
- [Environment Variables](#-environment-variables)
- [Running Locally](#-running-locally)
- [API Structure](#-api-structure)
- [Security Features](#-security-features)
- [Offline-first Architecture](#-offline-first-architecture)
- [Roles & Permissions](#-roles--permissions)
- [Recent Updates](#-recent-updates)
- [Future Roadmap](#-future-roadmap)
- [License](#-license)
- [Author](#-author)

---

## Features

### Platform & UX

- **Responsive layouts** — Phones, tablets, and desktop (Windows) with adaptive chrome
- **Desktop Shell navigation** — Persistent `NavigationRail` + content area (no full-screen hub pushes)
- **Mobile navigation** — Bottom `NavigationBar` for primary day-to-day modules
- **Authentication** — JWT access / refresh tokens with secure local session storage
- **Role-based dashboards** — Admin, Supervisor, and Technician executive views
- **Localization** — English and Arabic (RTL-ready) via Flutter gen-l10n
- **Image upload & preview** — Cloudinary-backed uploads; desktop-safe image delivery (JPG-friendly)
- **Reusable UI system** — Shared cards, grids, page frames, loaders, and desktop widgets
- **State management** — `flutter_bloc` (Cubit) throughout the client
- **API integration** — Dio + repository / datasource Clean Architecture layers
- **Notifications** — In-app notification feed
- **Offline-ready repositories** — Interfaces prepared for offline sync
- **Real-time foundation** — Socket.IO enabled backend

### Operations modules

- **Attendance** — Clock in/out, breaks, GPS + live selfie verification
- **Overtime** — Normal and travel overtime with photo and location evidence
- **GPS tracking** — High-accuracy location capture with reverse geocoding (OpenStreetMap)
- **Live camera verification** — Mandatory live photo capture for attendance / overtime evidence
- **Work Orders** — Create, assign, accept, execute, and complete field jobs
- **Work Order execution workflow** — Staged field execution with attachments, locations, and timeline
- **Inventory** — Warehouses, spare parts, stock movements, low-stock alerts
- **Assets** — Asset registry, categories, history, QR-ready architecture
- **Preventive Maintenance (PM)** — Plans, schedules, checklists, history
- **Service Reports** — Report generation and customer signatures
- **User Management** — First-class module for user lifecycle and administration
- **Roles & Permissions** — Fine-grained RBAC (Admin / Supervisor / Technician)
- **Profile** — Personal account view and preferences entry points
- **Settings** — Account, company information, system, and about (application settings only)

---

## Desktop Experience

Desktop (and wide tablet) uses a single navigation model and a shared design system.

### Unified Desktop Shell

- Persistent **NavigationRail** beside the content area
- Primary modules open via **shell branch navigation** (`goBranch`) — content swaps inside the shell
- Hub destinations do **not** push full-screen routes or show a Back button to leave the rail
- Phone bottom navigation remains limited to day-to-day modules (Dashboard, Attendance, Work Orders, Overtime, Profile)

### NavigationRail primary modules

1. Dashboard  
2. Attendance  
3. Work Orders  
4. Overtime  
5. Profile  
6. Inventory  
7. Assets  
8. Preventive Maintenance  
9. Service Reports  
10. User Management  
11. Roles & Permissions  
12. Settings  

### Desktop UI system

- **`AppPageFrame`** — Centers content and caps readable width under the shell
- **Desktop cards & grids** — `AppDesktopActionCard`, `AppDesktopStatGrid`, shared list cards
- **Desktop split layouts** — e.g. Work Order detail (main execution column + sidebar for attachments / locations / timeline)
- **Settings redesign** — Split section list + right content panel (Account, Company, System, About)
- **Dashboard improvements** — Responsive KPI / action layouts aligned with the desktop frame
- **Users & Roles hubs** — Same stats + action-card patterns as Inventory / Assets / Dashboard
- **Login** — Wide two-column branded layout on desktop

---

## Responsive UI

Infinity FSM uses a shared breakpoint and widget layer so features adapt without duplicate business logic.

| Breakpoint | Width | Typical chrome |
|------------|-------|----------------|
| Phone | `< 600` | Bottom `NavigationBar` |
| Tablet | `600–900` | Compact rail / adaptive padding |
| Desktop | `≥ 900` | Extended / labeled `NavigationRail` |

### Shared building blocks

- `AppBreakpoints` — Phone / tablet / desktop helpers, content max widths, grid columns, page padding
- `AppPageFrame` — Bounded, centered content for lists, forms, and hubs
- `AppDesktopStatGrid` / `AppDesktopActionCard` / `AppDesktopSplitView` — Desktop hub patterns
- `AppListCard`, loaders, refresh bars, scroll padding, offline banner
- `AppCachedNetworkImage` — Platform-aware network images (desktop-safe decoding)

### Desktop vs mobile behavior

| Concern | Desktop | Mobile |
|---------|---------|--------|
| Primary navigation | `NavigationRail` (all primary modules) | Bottom bar (5 modules) |
| Module hubs | Shell content swap | Same routes; phone chrome adapted |
| Dense layouts | Multi-column grids, split views | Single-column lists / sheets |
| Settings | Section rail + content panel | Stacked settings list |

---

## Architecture

Infinity FSM follows a **platform-first** modular architecture:

```
Platform Core (stable)                 Business Modules (pluggable)
──────────────────────                 ────────────────────────────
Auth & JWT                             Attendance
RBAC / Permissions                     Overtime + Travel Overtime
Organization hierarchy                 Work Orders
Settings / Configuration               Inventory
Notifications                          Assets
Audit logging                          Preventive Maintenance
File storage (Cloudinary)              Service Reports
Maps / GPS utilities                   Dashboard analytics
Sync & Search foundations              User Management UI
```

### Flutter (Clean Architecture)

```
Presentation  →  Cubits (flutter_bloc) + pages / widgets
Domain        →  Entities / Use Cases / Repository interfaces
Data          →  Models / Remote datasources / Repository implementations
```

Routing uses **`go_router`** with a **`StatefulShellRoute.indexedStack`** for the Desktop Shell and phone bottom navigation.

### Backend

```
Routes → Validators → Controllers → Services → Mongoose Models
```

---

## Tech Stack

| Layer | Technology |
|-------|------------|
| Client | Flutter (Material 3), Windows / Android / iOS targets |
| State | flutter_bloc (Cubit), get_it DI |
| Navigation | go_router (StatefulShellRoute) |
| Networking | Dio |
| Backend | Node.js 20+, Express, MongoDB, Mongoose |
| Auth | JWT (access + refresh) |
| Realtime | Socket.IO |
| Media | Cloudinary (JPG-oriented image delivery for desktop clients) |
| Maps | OpenStreetMap (`flutter_map`, geolocator, geocoding) |
| Localization | Flutter gen-l10n (EN / AR) |
| Logging | Pino (API), logger (Flutter) |

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
| Overtime | ![Overtime](./screenshots/overtime.png) | |
| Work Orders | ![Work Orders](./screenshots/work-orders.png) | |
| Inventory | ![Inventory](./screenshots/inventory.png) | |
| Assets | ![Assets](./screenshots/assets.png) | |
| Preventive Maintenance | ![PM](./screenshots/pm.png) | |
| Reports | ![Reports](./screenshots/reports.png) | |
| Settings | ![Settings](./screenshots/settings.png) | |

### Desktop (placeholders)

| Screen | Capture |
|--------|---------|
| Desktop Shell / Dashboard | ![Desktop Dashboard](./screenshots/desktop-dashboard.png) |
| Desktop Work Order detail | ![Desktop Work Order](./screenshots/desktop-work-order.png) |
| Desktop Inventory hub | ![Desktop Inventory](./screenshots/desktop-inventory.png) |
| Desktop User Management | ![Desktop Users](./screenshots/desktop-users.png) |
| Desktop Roles & Permissions | ![Desktop Roles](./screenshots/desktop-roles.png) |
| Desktop Settings | ![Desktop Settings](./screenshots/desktop-settings.png) |

---

## Project Structure

```
infinity-fsm/
├── backend/                 # Node.js + Express API
│   ├── src/
│   │   ├── config/
│   │   ├── modules/
│   │   │   ├── core/        # auth, rbac, organization, settings, dashboard, users, ...
│   │   │   └── business/    # attendance, overtime, work-orders, inventory, assets, pm, reports
│   │   ├── routes/          # API version mounting (/api/v1)
│   │   └── shared/          # middleware, errors, utils
│   ├── scripts/
│   └── .env.example
├── mobile/                  # Flutter application
│   ├── lib/
│   │   ├── core/            # config, network, theme, router, localization, widgets, breakpoints
│   │   │   └── widgets/
│   │   │       └── desktop/ # AppDesktopActionCard, StatGrid, SplitView, ...
│   │   ├── features/        # feature modules (Clean Architecture)
│   │   └── shared/          # cross-feature presentation (e.g. profile)
│   ├── windows/             # Desktop runner
│   └── assets/
├── docs/                    # Architecture & API documentation
├── infra/                   # Docker / CI / deployment planning
├── scripts/                 # Ops & seed helpers
├── tests/                   # Cross-cutting test assets
├── screenshots/             # README screenshot placeholders
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
| [Socket.IO Events](./docs/SOCKET_EVENTS.md) | Real-time event catalog |
| [Testing Strategy](./docs/TESTING.md) | Unit, integration, E2E |
| [Non-Functional Requirements](./docs/NFR.md) | Performance, security, DR |
| [Module Registry](./docs/MODULE_REGISTRY.md) | Module catalog |
| [Roadmap](./docs/ROADMAP.md) | Delivery phases |
| [Future Improvements](./docs/FUTURE_IMPROVEMENTS.md) | Post-MVP ideas |

---

## Installation

### Prerequisites

- Node.js **20+**
- MongoDB **6+** (local or Atlas)
- Flutter SDK with **Dart 3.12+** (see `mobile/pubspec.yaml`)
- Cloudinary account (required for production media uploads)

---

## Backend Setup

```bash
cd backend
cp .env.example .env
npm install
npm run seed    # optional demo data
npm run dev     # http://localhost:3000
```

Health check:

```bash
curl http://localhost:3000/api/v1/health
```

---

## Flutter Setup

```bash
cd mobile
flutter pub get
flutter gen-l10n
flutter run
```

> API base URL is centralized in `mobile/lib/core/config/env_config.dart`.  
> Default production API: `https://infinity-fsm-api.onrender.com/api/v1`  
> Override for local backend: `--dart-define=API_BASE_URL=http://<lan-ip>:3000/api/v1`

### Desktop (Windows)

```bash
cd mobile
flutter pub get
flutter run -d windows
```

### Build APK

```bash
cd mobile
flutter build apk --release
```

### Local API override

```bash
flutter run --dart-define=ENV=development --dart-define=API_BASE_URL=http://192.168.1.10:3000/api/v1
```

---

## Environment Variables

Copy `backend/.env.example` to `backend/.env` and fill in real values.

| Variable | Description |
|----------|-------------|
| `NODE_ENV` | `development` / `production` / `test` |
| `PORT` | API port (default `3000`) |
| `API_VERSION` | API version segment (default `v1`) |
| `MONGODB_URI` | MongoDB connection string |
| `JWT_ACCESS_SECRET` | Access token secret (≥ 32 chars). Alias: `JWT_SECRET` |
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

**Never commit `backend/.env`.**

Flutter client overrides (compile-time):

| Define | Description |
|--------|-------------|
| `API_BASE_URL` | REST base URL including `/api/v1` |
| `ENV` | `development` or `production` (logging behavior) |

---

## Running Locally

```bash
# Terminal 1 — API
cd backend
cp .env.example .env
npm install
npm run dev

# Terminal 2 — Flutter (device / emulator)
cd mobile
flutter pub get
flutter run

# Or desktop Windows
flutter run -d windows
```

---

## Building APK

```bash
cd mobile
flutter build apk --release
```

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

> In-app notifications are implemented on the Flutter client; backend notification surface continues to evolve with the realtime / sync roadmap.

---

## Security Features

- JWT access + refresh token rotation
- Password hashing (bcrypt)
- Helmet hardening
- Rate limiting (global + auth)
- CORS allow-list
- RBAC permission checks on protected routes
- Device clock skew detection
- Mandatory live camera capture for attendance / overtime
- GPS accuracy thresholds
- Audit logging foundation
- Secrets via environment variables only

---

## Offline-first Architecture

Repositories are designed with offline-ready interfaces:

- Queueable attendance / overtime actions
- Soft refresh + session query cache on mobile
- Connectivity-aware banners and sync hooks

Full offline execution continues to expand per the product roadmap.

---

## Roles & Permissions

| Role | Typical scope |
|------|----------------|
| **Admin** | Company-wide configuration, users, roles, inventory, assets, PM, reports |
| **Supervisor** | Team attendance, overtime review, work order oversight |
| **Technician** | Self attendance, overtime, assigned work orders |

User Management and Roles & Permissions are **top-level Desktop Shell modules** (not nested under Settings). Settings remains focused on account, company, system, and about.

See [docs/RBAC.md](./docs/RBAC.md).

---

## Recent Updates

Summary of the latest product and UX improvements:

- **Desktop Shell navigation refactor** — Primary modules open inside one shell via `StatefulShellRoute` branches
- **NavigationRail improvements** — Consistent rail destinations for all primary desktop modules
- **Users & Roles promoted** — First-class rail modules; removed from Settings → Administration
- **Settings redesign** — Desktop split panel for Account, Company Information, System, and About
- **Desktop dashboard redesign** — Frame width, spacing, and action patterns aligned with the design system
- **Desktop Work Orders redesign** — Split detail layout (execution main + sidebar context)
- **Responsive component system** — Shared breakpoints, grids, action cards, and list cards
- **Desktop page frame** — `AppPageFrame` for consistent content width under the shell
- **Image handling improvements** — Desktop-safe network image decoding / Cloudinary JPG-oriented delivery
- **Work Order detail layout improvements** — Clearer execution vs context separation on wide screens
- **Navigation improvements** — Shell `goBranch` instead of full-screen hub pushes; Settings / Profile entry via shell routes
- **UI consistency improvements** — Inventory, Assets, Users, Roles, and Dashboard share the same desktop hub language

---

## Future Roadmap

- Deeper offline sync and conflict resolution
- Push notifications (FCM / APNs)
- Advanced analytics and payroll exports
- Vehicles module UI
- Expanded scheduling and customer CRM
- Hardened production deployment (Docker, CI/CD, monitoring)

See [docs/ROADMAP.md](./docs/ROADMAP.md) and [docs/FUTURE_IMPROVEMENTS.md](./docs/FUTURE_IMPROVEMENTS.md).

---

## License

Released under the [MIT License](./LICENSE).

---

## Author

**Mazen Mahmoud** — Total-Com Solutions

Built as an enterprise Field Service Management platform for real-world technician operations.
