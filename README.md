# Infinity FSM

![Flutter](https://img.shields.io/badge/Flutter-3.x-blue)
![Node.js](https://img.shields.io/badge/Node.js-Express-green)
![MongoDB](https://img.shields.io/badge/MongoDB-Database-brightgreen)
![Cloudinary](https://img.shields.io/badge/Cloudinary-Media-blueviolet)
![License](https://img.shields.io/badge/License-MIT-orange)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20Windows-lightgrey)
![Offline First](https://img.shields.io/badge/Offline-First-success)
![Architecture](https://img.shields.io/badge/Architecture-Clean%20%7C%20Cubit-informational)

**Enterprise Field Service Management for maintenance companies and field service teams**

Infinity FSM is a modern Enterprise Field Service Management (FSM) system built for maintenance companies and field service teams that dispatch technicians into the field. It unifies attendance, overtime journeys, work orders, assets, inventory, preventive maintenance, and service reporting in one coherent product — with reliable evidence capture, offline resilience, and administrator control.

| | |
|---|---|
| **Frontend** | Flutter · Material 3 · Clean Architecture · Repository Pattern · Cubit / BLoC |
| **Backend** | Node.js · Express · MongoDB · JWT · Socket.IO |
| **Media** | Cloudinary |
| **Sync** | Offline-first synchronization with pending action queues |
| **Locales** | English & Arabic (RTL / LTR) |
| **Platforms** | Android · Windows Desktop |

---

## Table of Contents

- [Project Overview](#project-overview)
- [Features](#features)
- [Enterprise Overtime](#enterprise-overtime)
- [Stage-Based Voice Notes](#stage-based-voice-notes)
- [Enterprise Voice Configuration](#enterprise-voice-configuration)
- [Configuration Testing Lab](#configuration-testing-lab)
- [Responsive Experience](#responsive-experience)
- [Enterprise Excel Reports](#enterprise-excel-reports)
- [Windows Support](#windows-support)
- [Offline Support](#offline-support)
- [Localization](#localization)
- [Technology Stack](#technology-stack)
- [Architecture](#architecture)
- [Screenshots](#screenshots)
- [Documentation](#documentation)
- [Getting Started](#getting-started)
- [Environment Variables](#environment-variables)
- [API Structure](#api-structure)
- [Security](#security)
- [Roles & Permissions](#roles--permissions)
- [Roadmap](#roadmap)
- [License](#license)
- [Author](#author)

---

## Project Overview

Infinity FSM is an **Enterprise Field Service Management System** designed for maintenance companies, facility operators, and field service teams that need end-to-end visibility over technician operations.

The platform is built with:

| Layer | Technologies |
|-------|--------------|
| Mobile & Desktop UI | **Flutter**, Material 3, **Cubit** (flutter_bloc) |
| API | **Node.js**, **Express**, JWT, Socket.IO |
| Database | **MongoDB** (Atlas or self-hosted) with Mongoose |
| Media | **Cloudinary** for photos, selfies, attachments, and voice notes |
| Client architecture | **Clean Architecture**, **Repository Pattern**, **GetIt** DI, **GoRouter**, **Dio** |
| Field resilience | **Offline-first synchronization**, local pending queues, connectivity-aware UI |

Technicians capture GPS-verified evidence on the go. Supervisors review and approve journeys. Administrators configure organization-wide policies, media settings, and access control — all from a single enterprise application.

---

## Features

### Platform

| Feature | Description |
|---------|-------------|
| **Authentication** | JWT access + refresh tokens, secure session persistence, profile management, avatar upload |
| **Role-Based Access Control** | Admin / Supervisor / Technician roles with granular, localized permissions |
| **Dashboard** | Role-aware KPI cards, charts, live activity feed, and operational statistics |
| **Notifications** | In-app notification center with unread badges and mark-as-read support |
| **Reports Center** | Unified hub for operational reports and export entry points |
| **Global Search** | Cross-module search dialog for fast navigation to records |
| **Enterprise Excel Reports** | Multi-sheet overtime workbooks with embedded media and hyperlinks |
| **Audit Logs** | Server-side audit trail for settings, security, and operational events |
| **Localization** | Full English and Arabic with RTL / LTR support |
| **Windows Desktop Support** | Native Flutter desktop shell with NavigationRail |
| **Android Support** | Production-ready mobile client for field technicians |

### Operations

| Module | Capabilities |
|--------|--------------|
| **Attendance** | GPS clock in/out, live selfie verification, personal & team history, admin review, offline sync |
| **Work Orders** | Create, assign, track, complete; staged execution with attachments and timeline |
| **Assets** | Registry, categories, history, QR-oriented workflows |
| **Inventory** | Warehouses, spare parts, stock movements, low-stock visibility |
| **Preventive Maintenance** | PM plans, schedules, history, checklist builder |
| **Service Reports** | List, dashboard, detail, generation/download, customer signature |
| **Overtime** | Multi-stage journeys, GPS, maps, photos, voice notes, approvals, offline sync |

### Field Evidence & Media

| Capability | Description |
|------------|-------------|
| **Offline Sync** | Pending action queues with automatic drain on reconnect |
| **GPS Tracking** | Accuracy, battery, network status, reverse geocoding per checkpoint |
| **Journey Timeline** | Visual stage progression with evidence badges |
| **Cloudinary Media Storage** | Cloud-hosted photos and voice recordings |
| **Photo Uploads** | Live camera capture with configurable compression |
| **Voice Notes** | Independent voice note per overtime journey stage |
| **Enterprise Voice Configuration** | Duration, quality, upload policy, presets, restore defaults |
| **Configuration Testing Lab** | Admin-only preview of voice and photo settings before deployment |

---

## Enterprise Overtime

Overtime is the most complete offline-first workflow in Infinity FSM — a multi-stage field journey with GPS evidence, media capture, and approval.

### Four Journey Checkpoints

```
Start Journey → Arrived at Work Site → Finished Work → End Journey
```

Each checkpoint captures:

- **GPS** coordinates with accuracy, battery, and network metadata
- **Reverse-geocoded address**
- **Photos** (live camera) with configurable compression
- **Voice note** (optional, stage-specific)
- Timestamp and device context

### Maps, Timeline & Media

| Capability | Detail |
|------------|--------|
| **Journey Timeline** | Stage cards with evidence summary and sync status |
| **Maps** | Journey overview with markers, polyline, and legend (OpenStreetMap) |
| **Photos** | Live capture per stage with admin-configured size policy |
| **Voice Notes** | Independent recording per stage (see below) |
| **GPS Tracking** | Accuracy thresholds and reverse geocoding |

### Workflow

| Aspect | Detail |
|--------|--------|
| **Types** | Normal overtime · Travel overtime |
| **Technician** | Start session, advance stages, capture evidence, end session |
| **Admin / Supervisor** | Review sessions, approve or reject, inspect timeline + map |
| **History** | Personal history for technicians; full list for authorized roles |
| **Offline synchronization** | Full lifecycle offline with pending queue and sync on reconnect |

### Technician vs Admin

| Role | Experience |
|------|------------|
| **Technician** | Mobile-first journey capture, sync indicator, read-only voice settings info card |
| **Admin / Supervisor** | Review queue, interactive desktop detail (timeline ↔ map), Excel export, media configuration |

---

## Stage-Based Voice Notes

Each overtime stage has an **independent voice note**. Notes are not shared across stages — every checkpoint can record, replace, or clear its own audio.

### Stages

| Stage | Voice Note |
|-------|------------|
| 1 | **Start** |
| 2 | **Arrived** |
| 3 | **Finished Work** |
| 4 | **End** |

### Recording, Storage & Sync

| Capability | Description |
|------------|-------------|
| **Cloudinary storage** | Successful uploads are stored as Cloudinary media assets |
| **Offline recording** | Voice drafts are stored locally and uploaded when connectivity returns |
| **Automatic synchronization** | Pending voice notes drain with the overtime sync queue |
| **Timeline integration** | Voice notes appear in the Journey Timeline with sync status |
| **Windows playback** | Desktop playback via `just_audio_media_kit` / media_kit Windows audio backend |
| **Android playback** | Native playback through `just_audio` |
| **Playback controls** | Play, pause, stop, delete, and re-record per stage |

Recording respects administrator-configured **maximum duration** and **recording quality**, with a countdown timer and warning before auto-stop.

---

## Enterprise Voice Configuration

Administrators configure organization-wide overtime media behavior under **Settings → Overtime Settings**.

### Configurable Policies

| Setting | Options |
|---------|---------|
| **Voice Recording Duration** | 2, 5, 10, 15, or 20 minutes |
| **Voice Recording Quality** | High · Medium · Low (with live size estimates) |
| **Photo Compression Policy** | 1 MB · 2 MB · 5 MB · Original |
| **Upload Policy** | Immediately · Wi-Fi Preferred · Wi-Fi Only · Manual · Ask Every Time |

### Configuration Presets

| Preset | Duration | Quality | Photo | Upload |
|--------|----------|---------|-------|--------|
| **Office** | 2 min | Low | 1 MB | Immediately |
| **Field Service** | 5 min | Medium | 2 MB | Wi-Fi Preferred |
| **Heavy Maintenance** | 20 min | High | Original | Manual |
| **Custom** | Any combination | | | |

Manual edits to any preset value automatically switch the active preset to **Custom**.

### Restore Defaults

Administrators can restore:

- Recording duration → **5 minutes**
- Recording quality → **Medium**
- Maximum photo size → **2 MB**
- Upload policy → **Immediately**

### Audit Logging

Every configuration change creates a server-side audit entry, including:

- Voice recording duration changed
- Voice quality changed
- Upload policy changed
- Maximum photo size changed
- Configuration preset applied
- Settings restored to defaults

### Dynamic Configuration Updates

Settings are stored in the backend settings collection and propagated to clients. Technicians see a **read-only information card** on the voice recorder screen reflecting the active policy.

When **Ask Every Time** is selected, cellular upload prompts let the technician choose Wi-Fi Only, Mobile Data, or Later for that upload only.

---

## Configuration Testing Lab

Administrators can **safely preview** overtime media settings before deploying them organization-wide.

The lab lives at the bottom of **Settings → Overtime Settings** and is admin-only.

### Tools

| Tool | Purpose |
|------|---------|
| **Voice Recording Test** | Record with current duration/quality; inspect timer, encoding, estimated vs actual size |
| **Temporary Playback** | Play and delete the temporary test recording |
| **Photo Compression Preview** | Pick camera/gallery photo and apply the active compression policy |
| **Original vs Compressed comparison** | Compare source bytes against compressed output |
| **Fullscreen comparison viewer** | Tabs for Original, Compressed, and Compare with pinch / double-tap zoom |
| **Desktop Split Comparison** | Draggable before/after slider for pixel-aligned comparison |
| **Mobile optimized comparison** | Stacked Original → Compressed previews (no forced slider) |
| **Compression metrics** | Resolutions, sizes, ratio, JPEG quality, estimated upload size/time |
| **Storage calculator** | Estimated voice, image, session, daily, and monthly usage |
| **Upload estimates** | Combined voice + photo upload projections for the active policy |

### Safety Guarantees

| Guarantee | Detail |
|-----------|--------|
| **No uploads** | Test media never leaves the device through the upload pipeline |
| **No Cloudinary upload** | Lab artifacts are not sent to Cloudinary |
| **No backend changes** | Preview does not mutate overtime sessions or settings persistence beyond normal settings saves |
| **No permanent storage** | Temporary files are cleaned up when leaving the page |
| **Everything is temporary** | Designed for configuration validation only |

---

## Responsive Experience

Infinity FSM adapts layouts for phone, tablet, and desktop from a single Flutter codebase.

### Desktop

- Split comparison slider in the Configuration Lab
- Multi-column dashboards and metric grids
- Persistent **NavigationRail** enterprise shell
- Settings split panel (section list + content)
- Interactive overtime detail (timeline ↔ map)

### Mobile

- Responsive controls and equal-width adaptive selectors
- Stacked image comparison in the Configuration Lab
- Fullscreen preview with swipeable Original / Compressed / Compare pages
- Touch-optimized interactions (pinch zoom, double-tap zoom)
- Bottom `NavigationBar` for day-to-day modules

### Breakpoints

| Breakpoint | Width | Chrome |
|------------|-------|--------|
| Phone | `< 600` | Bottom `NavigationBar` |
| Tablet | `600–900` | Adaptive padding / compact rail |
| Desktop | `≥ 900` | Extended `NavigationRail` |

### Primary Modules

Dashboard · Attendance · Work Orders · Overtime · Profile · Inventory · Assets · Preventive Maintenance · Service Reports · Reports Center · User Management · Roles & Permissions · Settings

Phone bottom navigation focuses on day-to-day modules: Dashboard, Attendance, Work Orders, Overtime, Profile.

Global search and the notification bell are available from the dashboard app bar.

---

## Enterprise Excel Reports

Authorized administrators and supervisors can export overtime data as enterprise Excel workbooks (**ExcelJS** on the backend).

### Workbook Structure

| Mode | Sheets |
|------|--------|
| **Summary** | Executive Summary sheet only |
| **Detailed** | Executive Summary + **Sessions Index** + **one worksheet per overtime session** |

### Executive Summary

- Company branding (logo hyperlink when available)
- Export metadata and date range
- KPI grid (session counts, durations, statuses)
- Filter summary

### Session Sheets

Each detailed session sheet includes:

- Session header with technician, type, status, and duration
- **Journey timeline** table with stage timestamps
- Status badges for session and stage states
- **Embedded photo thumbnails** per stage
- **Voice recording hyperlinks** linking to Cloudinary recordings
- **Google Maps hyperlinks** for GPS coordinates
- Key-value evidence rows (GPS, address, photo count, voice duration)
- Navigation link back to Sessions Index
- **Landscape printing** page setup

Exports are triggered from the **Reports Center** or overtime admin views with configurable date, status, and type filters.

---

## Windows Support

Infinity FSM targets both **Android** and **Windows Desktop** from a single Flutter codebase.

| Capability | Android | Windows |
|------------|---------|---------|
| Native app shell | ✅ | ✅ Native desktop support |
| NavigationRail layout | — | ✅ |
| GPS & maps | ✅ | ✅ (where hardware permits) |
| Camera / photo capture | ✅ | ✅ |
| Voice recording | ✅ | ✅ |
| Voice playback | ✅ | ✅ via **media_kit** backend |
| Cloudinary integration | ✅ | ✅ |
| Excel export | ✅ | ✅ |
| Offline synchronization | ✅ | ✅ |

### Voice Playback on Windows

Windows uses **`just_audio_media_kit`** with **`media_kit_libs_windows_audio`** as the playback backend for overtime voice notes. This is registered at app bootstrap in `mobile/lib/core/app/bootstrap.dart`.

```bash
cd mobile
flutter pub get
flutter run -d windows
```

---

## Offline Support

Infinity FSM is designed for unreliable field connectivity:

| Capability | Status |
|------------|--------|
| Offline overtime sessions (start / checkpoint / end) | ✅ Complete |
| Local pending action queue | ✅ |
| Automatic sync on reconnect | ✅ |
| Upload policy–aware sync (Wi-Fi gating, manual) | ✅ |
| Offline attendance capture | ✅ Hooks present |
| Offline banners & queue indicators | ✅ |
| Repository interfaces for broader offline expansion | ✅ Prepared |

> Overtime is the most complete offline path today. Other modules continue to expand offline coverage.

---

## Localization

- **English (LTR)** and **Arabic (RTL)** via Flutter ARB + `gen-l10n`
- Locale-aware dates and numbers through shared formatters
- Localized RBAC permission names, groups, and descriptions
- Localized audit event labels (`localize_audit_event`)
- Human-friendly error mapping (`localizeAppMessage`) on failure screens
- Complete EN/AR coverage for enterprise voice settings, presets, Configuration Lab, and cellular upload prompts

```bash
cd mobile
flutter gen-l10n
```

---

## Technology Stack

### Frontend

| Technology | Role |
|------------|------|
| **Flutter** | Cross-platform UI (Android, Windows) |
| **Dart** | Client language (^3.12) |
| Material 3 | Design system (light / dark / system) |
| **Cubit** (`flutter_bloc`) | State management |
| **GetIt** | Dependency injection |
| **Dio** | HTTP client |
| **GoRouter** | Navigation (`StatefulShellRoute`) |
| flutter_map | OpenStreetMap rendering |
| geolocator / geocoding | GPS + reverse geocoding |
| record / just_audio | Voice recording & playback |
| just_audio_media_kit | Windows playback backend |
| SharedPreferences | Local preferences & offline caches |
| flutter_secure_storage | Secure token storage |
| image / image_picker | Photo capture & compression |

### Backend

| Technology | Role |
|------------|------|
| **Node.js** | Runtime (≥ 20) |
| **Express** | HTTP API |
| **MongoDB** | Atlas / self-hosted · Mongoose ODM |
| JWT | Access + refresh authentication |
| **Cloudinary** | Cloud image / voice media storage |
| exceljs | Enterprise Excel workbook generation |
| Socket.IO | Realtime foundation |
| Pino | Structured logging |
| Helmet / rate limiting / CORS | API hardening |

---

## Architecture

### Design Principles

```
Presentation  →  Pages / Widgets + Cubits (flutter_bloc)
Domain        →  Entities, Use Cases, Repository interfaces
Data          →  Models, Remote/Local datasources, Repository implementations
Core          →  Config, network, theme, router, localization, DI, shared widgets
Shared        →  Cross-feature presentation (profile, app shell helpers)
```

Each feature module under `mobile/lib/features/` follows this layering. Cross-cutting concerns live in `mobile/lib/core/`. Shared presentation utilities live in `mobile/lib/shared/`.

### Backend Layering

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
Notifications                          Assets
Audit logging                          Preventive Maintenance
File storage (Cloudinary)              Service Reports
Maps / GPS utilities                   Dashboard analytics
Sync foundations                       User Management
```

### Folder Tree

```
infinity-fsm/
├── backend/
│   ├── src/
│   │   ├── config/                    # Env, Cloudinary, database
│   │   ├── modules/
│   │   │   ├── core/                  # auth, rbac, settings, audit, dashboard, users, …
│   │   │   └── business/              # attendance, overtime, work-orders, inventory, …
│   │   ├── routes/                    # /api/v1 mounting
│   │   └── shared/                    # middleware, errors, utils
│   ├── scripts/                       # seed & migrations
│   └── .env.example
├── mobile/
│   ├── lib/
│   │   ├── core/                      # config · network · theme · router · l10n · DI · widgets
│   │   ├── features/                  # Clean Architecture feature modules
│   │   │   ├── auth/
│   │   │   ├── dashboard/
│   │   │   ├── attendance/
│   │   │   ├── overtime/
│   │   │   ├── work_orders/
│   │   │   ├── inventory/
│   │   │   ├── assets/
│   │   │   ├── pm/
│   │   │   ├── service_reports/
│   │   │   ├── reports_center/
│   │   │   ├── notifications/
│   │   │   ├── global_search/
│   │   │   ├── settings/
│   │   │   └── …
│   │   └── shared/                    # profile, cross-feature widgets
│   ├── windows/                       # Desktop runner
│   ├── android/                       # Android runner
│   └── assets/
├── docs/                              # Architecture & API documentation
├── infra/                             # Docker / CI / deployment planning
├── screenshots/                       # README screenshot placeholders
├── README.md
└── LICENSE
```

Routing uses **`go_router`** with a **`StatefulShellRoute.indexedStack`** for the Desktop Shell and phone bottom navigation.

---

## Screenshots

> Replace placeholders in `/screenshots` with real captures before publishing.  
> See [screenshots/README.md](./screenshots/README.md) for suggested filenames.

### Mobile / General

| Screen | Light | Dark |
|--------|-------|------|
| Login | ![Login](./screenshots/login.png) | ![Login Dark](./screenshots/login-dark.png) |
| Dashboard | ![Dashboard](./screenshots/dashboard.png) | ![Dashboard Dark](./screenshots/dashboard-dark.png) |
| Notifications | ![Notifications](./screenshots/notifications.png) | |
| Reports Center | ![Reports Center](./screenshots/reports-center.png) | |
| Attendance | ![Attendance](./screenshots/attendance.png) | |
| Overtime Journey | ![Overtime](./screenshots/overtime.png) | |
| Voice Notes | ![Voice Notes](./screenshots/voice-notes.png) | |
| Work Orders | ![Work Orders](./screenshots/work-orders.png) | |
| Inventory | ![Inventory](./screenshots/inventory.png) | |
| Assets | ![Assets](./screenshots/assets.png) | |
| Preventive Maintenance | ![PM](./screenshots/pm.png) | |
| Service Reports | ![Reports](./screenshots/reports.png) | |
| Roles & Permissions | ![Roles](./screenshots/roles.png) | |
| Settings / Theme | ![Settings](./screenshots/settings.png) | |

### Enterprise Features (placeholders)

| Screen | Capture |
|--------|---------|
| Voice Notes Settings | ![Voice Settings](./screenshots/voice-settings.png) |
| Configuration Testing Lab | ![Config Lab](./screenshots/config-lab.png) |
| Excel Reports | ![Excel Reports](./screenshots/excel-export.png) |

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
- Server-side audit logging for settings and operational events
- Secrets via environment variables only
- Biometric-gated Server Management access on supported devices

---

## Roles & Permissions

| Role | Typical scope |
|------|----------------|
| **Admin** | Company-wide configuration, users, roles, inventory, assets, PM, reports, voice settings |
| **Supervisor** | Team attendance, overtime review, work order oversight, Excel export |
| **Technician** | Self attendance, overtime capture, assigned work orders |

User Management and Roles & Permissions are **top-level Desktop Shell modules**. Settings covers theme, language, notifications, organization, overtime media settings, diagnostics, and about.

The Roles UI presents localized permission groups with searchable titles and one-sentence descriptions so non-technical administrators can understand each grant.

See [docs/RBAC.md](./docs/RBAC.md).

---

## Roadmap

### Completed

- ✅ Enterprise Voice Notes
- ✅ Configuration Lab
- ✅ Enterprise Excel Reports
- ✅ Reports Center
- ✅ Notifications
- ✅ Global Search
- ✅ Platform core (auth, RBAC, organization, settings)
- ✅ Attendance with GPS + live selfie verification
- ✅ Offline-first overtime journey + admin review
- ✅ Work Orders, Inventory, Assets, PM, Service Reports
- ✅ Desktop Shell + responsive Material 3 UI
- ✅ Arabic / English localization with RTL
- ✅ Cloudinary media pipeline
- ✅ Runtime Server Management & diagnostics

### In Progress

- Dashboard Analytics

### Future

- Real-time Monitoring
- Advanced Asset Analytics
- Predictive Maintenance

See [docs/ROADMAP.md](./docs/ROADMAP.md) and [docs/FUTURE_IMPROVEMENTS.md](./docs/FUTURE_IMPROVEMENTS.md).

---

## License

Released under the [MIT License](./LICENSE).

---

## Author

**Mazen Mahmoud** — Total-Com Solutions

Built as an enterprise Field Service Management platform for real-world technician operations.
