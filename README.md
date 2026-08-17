# Infinity FSM

**Enterprise Field Service Management for maintenance companies and field workforce teams**

Infinity FSM (Infinity Field Service Management) is a production-oriented **employee / workforce management** and Field Service Management platform. It helps organizations manage technicians in the field with attendance, overtime journeys, work orders, inventory, assets, preventive maintenance, service reports, dashboards, and role-based administration — from a single Flutter client and Node.js API.

| Layer | Stack |
|-------|--------|
| **Client** | Flutter · Material 3 · Clean Architecture · Cubit (`flutter_bloc`) · Repository Pattern |
| **API** | Node.js · Express · MongoDB (Mongoose) · JWT · Socket.IO |
| **Media** | Cloudinary |
| **Locales** | English (LTR) · Arabic (RTL) |
| **Targets** | Android · Windows Desktop |

The Windows desktop window title and product metadata display as **INFINITY**. The Flutter package name remains `mobile` so Android/mobile packaging is unchanged.

---

## Table of Contents

- [Project Overview](#project-overview)
- [Applications](#applications)
- [Main Features](#main-features)
- [Authentication & Security](#authentication--security)
- [Overtime Management](#overtime-management)
- [Dashboard](#dashboard)
- [Mobile UI](#mobile-ui)
- [Windows / Desktop](#windows--desktop)
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
- [Build / Release](#build--release)
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

- Technicians capture evidence on **Android** or **Windows desktop**.
- Supervisors review and approve overtime and oversee operations.
- Administrators configure users, roles, settings, media policy, and organization structure.

The Flutter app shares one codebase for **phone, tablet, and Windows desktop** (NavigationRail on wide layouts; bottom navigation on phones). Backend REST APIs are versioned under `/api/v1`.

---

## Applications

| Application | How it is delivered |
|-------------|---------------------|
| **Windows / Desktop** | Flutter Windows runner (`mobile/windows/`). OS window title and product name: **INFINITY**. Native save dialogs, dense dashboard, and Windows-specific Remember Me session persistence. |
| **Android / Mobile** | Flutter Android app. Field capture (GPS, camera, voice), compact dashboard, and existing mobile session behavior (unchanged by Windows-only auth rules). |
| **Responsive dashboard** | Phone, tablet, and desktop layouts with compact breakpoints for workforce cards, overtime charts, and technician summary. |
| **Localization** | English (LTR) and Arabic (RTL) throughout the Flutter UI, including dashboard charts and overtime Excel exports. |

Flutter also contains `ios/`, `macos/`, `linux/`, and `web/` runner folders as standard platform scaffolding. The product targets documented here are **Android** and **Windows**.

---

## Main Features

Features below are present in the repository (`mobile/lib/features/*` and `backend/src/modules/*`).

### Platform & access

| Feature | What exists |
|---------|-------------|
| **Authentication** | JWT access + refresh, login/logout, session restore, secure token storage. See [Authentication & Security](#authentication--security). |
| **User management** | Admin user CRUD, password change/reset flows |
| **Roles & permissions** | RBAC with Admin / Supervisor / Technician scopes and granular permission checks |
| **Organization** | Company/organization hierarchy and settings |
| **Profile** | User profile and related settings |
| **Settings** | Theme, language, notifications preferences, overtime media settings, diagnostics / server management |
| **Localization** | Full English & Arabic via Flutter ARB / `gen-l10n`, including RTL |
| **Global search** | Client-side palette that searches across existing module APIs (users, work orders, assets, inventory, overtime, PM, reports). A dedicated `/search` API is not mounted. |
| **Notifications (UI)** | In-app notification center and bell; feed currently sourced from dashboard live activity / audit projections (dedicated `/notifications` API is not mounted) |
| **Reports Center** | Hub for operational reports and export entry points |
| **Audit logging** | Server-side audit trail for settings and operational events |

### Operations modules

| Module | Capabilities |
|--------|--------------|
| **Attendance** | GPS clock in/out, selfie verification, personal/team history, admin review, connectivity-aware UX |
| **Work orders** | Create, assign, track, complete; attachments and timeline-oriented flows |
| **Overtime** | Multi-stage journeys, Normal & Travel types, GPS/maps/photos/voice, approval workflow, company overtime policy, multi-day calendar-day calculations, offline queue + sync. See [Overtime Management](#overtime-management). |
| **Inventory** | Warehouses, parts, stock visibility (including low-stock style alerts on dashboard) |
| **Assets** | Asset registry and related workflows |
| **Preventive maintenance** | PM plans / schedules / history-oriented UI |
| **Service reports** | List, detail, generation/download, customer signature support |

Vehicles is schema-ready documentation only and is **not** implemented in the API or UI.

### Offline

- **Overtime** has the most complete offline path: local pending actions, sync on reconnect, upload-policy awareness.
- Attendance and other modules use offline banners / caching patterns where implemented.
- Repository interfaces are prepared for broader offline expansion.

---

## Authentication & Security

Authentication uses the existing backend JWT architecture. There is a single login/refresh/logout flow — not a second auth system.

### Login and logout

| Endpoint | Purpose |
|----------|---------|
| `POST /api/v1/auth/login` | Email + password. Returns access token, refresh token, and user. |
| `POST /api/v1/auth/refresh` | Exchange a valid refresh token + device id for new tokens. |
| `POST /api/v1/auth/logout` | Invalidate the refresh session (authenticated). |
| `GET /api/v1/auth/me` | Current authenticated user. |

Passwords are hashed with **bcrypt**. Tokens are JWTs (`JWT_ACCESS_SECRET` / `JWT_REFRESH_SECRET`). The client never persists the password.

### Remember Me

Remember Me stores the **email** (and a remember-me flag) in SharedPreferences so the login form can be pre-filled. **The password is never written** to SharedPreferences, secure storage, files, JSON, or SQLite.

Session persistence is done with **access + refresh tokens**, not saved credentials.

### Windows persistent session

On **Windows only**:

1. User signs in with email + password and Remember Me enabled.
2. The app stores access/refresh tokens in **`flutter_secure_storage`** (Windows DPAPI-backed storage). Writes are serialized so the single Windows storage file cannot drop the refresh token.
3. The password is discarded and never stored.
4. After a full application close and reopen, the app restores the session from the persisted refresh/session tokens.
5. If the access token is expired, the client refreshes it automatically with the refresh token (`RefreshTokenInterceptor` and `restoreSession`).
6. If the refresh token is expired, revoked, or invalid, the stored session is cleared and the Sign in screen is shown. There is no infinite refresh loop (refresh failures on `/auth/refresh` are not retried as 401 refresh).
7. Logout clears local tokens. Reopening the app does **not** automatically sign the user back in.

When Remember Me is **disabled** on Windows, tokens stay in memory for the live process only. Closing the app requires authentication again.

Android/iOS keep the existing behavior: tokens are always written to secure storage regardless of the Remember Me checkbox. Windows-only session policy lives in `DesktopSessionPolicy` and does not change mobile authentication.

### Token handling

- Access tokens are attached as `Authorization: Bearer …`.
- Refresh uses the existing `/auth/refresh` contract.
- Sensitive values are redacted by `sanitizeLogMessage` before debug/error logs (passwords, tokens, Authorization headers).

---

## Overtime Management

```
Start Journey → Arrived at Work Site → Finished Work → End Journey
```

Each stage can capture GPS (accuracy, battery, network), reverse-geocoded address, photos, and an **independent stage voice note**. Maps use OpenStreetMap (`flutter_map`). Administrators configure voice duration/quality, photo compression, and upload policy under **Settings → Overtime Settings**, including an admin **Configuration Testing Lab** for safe local previews (no Cloudinary upload from the lab).

Types: **Normal** and **Travel** (including overnight travel). Duration uses the same official working-hours algorithm for both.

### Approval workflow

Admins/supervisors with overtime approve/reject permissions can:

| Action | Behavior |
|--------|----------|
| **Approve (full)** | Approves the session; backend sets approved hours from worked/eligible calculation when `approvedHours` is omitted. |
| **Partial approve** | Reviewer enters approved hours (HH:MM UI, sent as the existing `approvedHours` API field). |
| **Reject** | Rejects the session with a reason. |
| **Manual review** | Sessions flagged `requiresManualReview` (for example duration beyond company policy) stay available for human review instead of being auto-rejected. |

### Company overtime policy

| Rule | Current behavior |
|------|------------------|
| Soft duration threshold | Default **16 hours** (`OVERTIME_MAX_SESSION_HOURS`). Ending a longer session is **allowed**. |
| Manual review flag | Sessions longer than the soft threshold are flagged (`requiresManualReview`) with a review reason such as exceeding company policy of 16 hours. |
| Hard maximum | **There is no hard 48-hour (or similar) cap.** Ending a session does not fail with `SESSION_TOO_LONG`. Multi-day and very long sessions calculate normally. |
| Minimum request | `OVERTIME_MIN_REQUEST_HOURS` (default 0.5). |

### Official working hours and calendar-day split

Authoritative calculator: `backend/src/modules/business/overtime/overtime.calculation.js` with policy in `working-hours.policy.js`. Calendar days and weekdays are resolved in **Africa/Cairo**, not the host process timezone.

| Policy | Detail |
|--------|--------|
| Working days | **Saturday–Thursday** |
| Official window | **09:00–17:00** (half-open: 17:00 is outside working hours) |
| Friday | Full day off. Eligible overtime can count the **full 24 hours** of Friday. |
| Eligible overtime | Session time **outside** official hours. Working duration = overlap with 09:00–17:00 on working days. Eligible = total − working (never negative). |
| Weekday full calendar day | 24h − 8h official window = **16 eligible hours**. |
| Multi-day sessions | Split by calendar day using the same overtime rules (not raw wall-clock and not an equal split of the total). |

Example used in dashboard trend tests: a session from Aug 12 10:00 to Aug 17 14:00 distributes as **7 / 16 / 24 / 16 / 16 / 9** eligible hours (Friday = 24).

---

## Dashboard

The **executive dashboard** (admin-focused layout; supervisor/technician variants also exist) is a dense, two-column analytics surface on desktop and a stacked, compact layout on phones.

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

Durations are shown as **hours + minutes** (for example `14 hours 57 minutes`), not decimal hours like `14.95`. Chart axes use compact duration labels (for example `122:42 h`).

### Main layout (desktop / tablet)

**Main column**

- **Workforce overview** (totals, active, currently working, average hours)
- **Overtime Analytics** (KPI row + embedded charts + technician summary)
- **Trends** (attendance / work orders / overtime / PM where series exist) with 7 / 30 day window

**Side column**

- **Operations** (work order + PM status list with status colors)
- **Resources** (inventory / asset alerts and counts)
- **Recent notifications / activity** feed

On compact/phone widths the same sections stack; workforce overview uses a 2×2 icon grid.

### Overtime analytics on dashboard

- Approved hours, trips, overnight trips, technicians
- Charts: **hours per technician**, **trips per technician**, **hours over time**
- **Technician Summary**
  - Desktop/tablet: compact table (name, approved hours, trips, overnight, avg hours/trip)
  - Compact/mobile: per-technician **cards** instead of a dense table

**Hours over time** distributes multi-day overtime by **actual eligible overtime per calendar day** (official OT rules), not by putting the whole total on the start date and not by dividing the total equally across days. Friday buckets can be 24 hours; weekday buckets follow 09:00–17:00 exclusion.

### Charts and RTL

- Bar labels stay aligned with bars in **LTR and RTL** (Arabic).
- Charts remain usable on phone widths (360 / 390 / 430) without clipping duration labels into values such as `8…`.
- Tooltips for hour series use human-readable durations, not decimals.

### Typography & data behavior

- Dashboard text uses **`DashboardTypography`** (`mobile/lib/features/dashboard/presentation/widgets/dashboard_typography.dart`) on the app `Theme` / `AppTypography`.
- Uses existing executive dashboard Cubit + summary APIs (lightweight statistics, not full collections for counts).
- Prefers cached data / refresh indicators (`isRefreshing`) over full-page loading when data already exists.
- Role-aware sections (admin dense layout; other roles keep their section builders).

---

## Mobile UI

Android/phone layouts are tuned for RTL Arabic and narrow widths without changing desktop information density.

| Area | Mobile behavior |
|------|-----------------|
| **Arabic RTL dashboard** | Localized strings, RTL direction, chart label/bar alignment for Arabic. |
| **Workforce overview** | Compact 2×2 card grid with icons (phone widths such as 360–430). |
| **Technician summary** | Card list on compact widths; table on wider layouts. |
| **Overtime analytics charts** | Responsive embedded charts; duration formatting; no decimal-hour axis labels. |
| **Admin overtime review** | On **phones**, Approve / Partial Approve / Reject appear at the **end of the scrollable page**, not pinned over the content. On **tablet/desktop**, review actions stay pinned outside the scroll view. |

---

## Windows / Desktop

| Topic | Current behavior |
|-------|------------------|
| **Window title** | OS title bar is **INFINITY** (`mobile/windows/runner/main.cpp`). |
| **Desktop metadata** | `FileDescription` and `ProductName` in `Runner.rc` are **INFINITY**. Internal/original filenames remain `mobile` / `mobile.exe` so the Flutter package/binary name is not renamed. |
| **Material app title** | `AppConfig.appName` is `INFINITY`. |
| **Remember Me** | Persists refresh/access tokens in secure storage when enabled; never stores the password. Restores the authenticated session after a full restart. |
| **Remember Me off** | Live session only; closing the app requires sign-in again. |
| **Logout** | Clears persisted tokens; next launch is signed out. |
| **Android** | Window title, package name, and mobile Remember Me / token persistence are not changed by the Windows session policy. |

Rebuild the Windows app after native runner changes (`flutter run -d windows` or `flutter build windows --release`).

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
| flutter_secure_storage | Access/refresh tokens (Android EncryptedSharedPreferences, iOS Keychain, Windows DPAPI) |
| shared_preferences | Preferences, remembered email, local caches |
| path_provider / path / share_plus / file_selector | File IO, share, native Save As |
| url_launcher | Open files / URLs |
| connectivity_plus / internet_connection_checker_plus | Connectivity |
| local_auth / device_info_plus / permission_handler / battery_plus | Device capabilities |
| timezone / intl | Time & formatting |
| cached_network_image / flutter_svg | Images |
| logger | Client logging (messages sanitized) |

### Backend (`backend/package.json`)

| Technology | Role |
|------------|------|
| Node.js ≥ 20 | Runtime |
| Express | HTTP API |
| Mongoose / MongoDB | Persistence |
| jsonwebtoken / bcrypt | Auth |
| Cloudinary | Media storage |
| exceljs | Overtime Excel workbooks |
| Socket.IO | Authenticated realtime foundation (user/company rooms; ping/pong) |
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
├── backend/                          # Node.js / Express API
│   ├── src/
│   │   ├── config/                   # Env, Cloudinary, multer
│   │   ├── modules/
│   │   │   ├── core/                 # auth, rbac, dashboard, users, settings, …
│   │   │   └── business/             # attendance, overtime, work-orders, inventory, …
│   │   ├── routes/                   # /api/v1
│   │   ├── shared/                   # middleware, utils
│   │   └── __tests__/                # Jest suites
│   ├── scripts/                      # seed & migrations
│   └── .env.example
├── mobile/                           # Flutter client (Android + Windows)
│   ├── lib/
│   │   ├── core/                     # theme, router, l10n, DI, network, storage, widgets
│   │   ├── features/                 # auth, dashboard, attendance, overtime, …
│   │   └── shared/
│   ├── android/                      # Android embedding
│   ├── windows/                      # Windows runner (title INFINITY)
│   ├── ios/ · macos/ · linux/ · web/ # Flutter platform folders
│   ├── test/                         # Flutter tests
│   └── assets/
├── docs/                             # Architecture, API, RBAC, roadmap, …
├── infra/                            # Deployment notes (planning)
├── tests/                            # Planned cross-cutting E2E/load assets
├── screenshots/                      # Optional captures for docs
├── LICENSE
└── README.md
```

---

## UI / Design

- Dark-friendly **desktop-style** shell with NavigationRail on wide screens
- Compact, data-dense **executive dashboard** with consistent typography
- Material 3 theming (no hard-coded one-off dashboard font family)
- Responsive breakpoints (`AppBreakpoints`): phone `< 600`, tablet `600–900`, desktop `≥ 900`; dashboard compact `≤ 768`
- Charts and operational lists designed for quick scanning
- Full **Arabic RTL** and **English LTR** support across UI and Excel exports

---

## Important Implementation Notes

| Topic | Detail |
|-------|--------|
| **RBAC** | Permissions checked on client and protected backend routes |
| **Remember Me** | Email only in preferences; session via refresh tokens. Password is never stored. |
| **Windows session** | Tokens persist only when Remember Me is on; Android token persistence is unchanged. |
| **Overtime policy** | 16-hour soft review flag; no hard 48-hour session cap. |
| **Calendar-day OT** | Africa/Cairo; Sat–Thu 09:00–17:00; Friday 24h eligible. |
| **Dashboard trends** | Multi-day hours split by eligible overtime per day, not equal division. |
| **Excel BiDi** | Arabic durations protected for Excel display; English unchanged |
| **Save As** | Native dialog via `file_selector` on desktop; cancel is silent |
| **Offline overtime** | Local queue + reconciliation/sync schedulers with forensic/trace helpers in tests |
| **SessionQueryCache** | Shared query cache to avoid duplicate network fetches |
| **Media** | Cloudinary for production uploads; Configuration Lab stays local-only |
| **Maps** | OpenStreetMap — not Google Maps SDK |

---

## Testing

### Backend (Jest)

Located under `backend/src/__tests__/`:

| Suite | Focus |
|-------|--------|
| `overtime.calculation.test.js` | Eligible vs working duration; sessions longer than 48 hours still calculate; 16-hour review threshold |
| `overtime.calendar-day-split.test.js` | Multi-day split; Friday 24h; weekday 16h eligible for a full day |
| `overtime.end-duration.test.js` | No `SESSION_TOO_LONG` / no hard 48-hour cap; soft 16-hour manual review |
| `dashboard.overtime-trends.test.js` | Hours-over-time buckets follow eligible OT per calendar day (e.g. 7 / 16 / 24 / 16 / 16 / 9) |
| `overtime.approved-hours.test.js` | Approval hours |
| `overtime.timeline.test.js` | Journey timeline |
| `overtime.excel.export.test.js` | Workbook structure, i18n, Arabic durations, no Branch/Department columns |
| `rbac.test.js` | Role/permission checks |

```bash
cd backend
npm test
# focused examples:
npm test -- --testPathPattern=overtime.calendar-day-split
npm test -- --testPathPattern=dashboard.overtime-trends
npm test -- --testPathPattern=overtime.excel.export
```

### Flutter

Located under `mobile/test/`:

| Area | Examples |
|------|----------|
| **Overtime calculation / duration** | `overtime_calculator_test.dart`, `approved_hours_hhmm_test.dart` |
| **Duration formatter** | `test/core/localization/duration_formatter_test.dart` (hours + minutes, Arabic prose) |
| **Dashboard widgets** | `dashboard_workforce_overview_test.dart` (Arabic RTL compact grid), `dashboard_mini_chart_test.dart` (duration labels, LTR/RTL bar alignment, phone widths) |
| **Admin overtime review layout** | `overtime_admin_detail_actions_layout_test.dart` (phone: actions in scroll; tablet/desktop: pinned) |
| **Remember Me / session** | `windows_remember_me_session_test.dart`, `token_manager_test.dart` (persist vs memory-only, no password storage, invalid refresh clears session) |
| **Log sanitization** | `log_sanitizer_test.dart` |
| **Overtime offline / sync** | lifecycle, scheduler, reconciliation, photo compressor, forensic traces |
| **Partial approve UI** | `overtime_partial_approve_dialog_test.dart` |

```bash
cd mobile
flutter test
flutter analyze

# focused examples:
flutter test test/core/storage/token_manager_test.dart test/features/auth/windows_remember_me_session_test.dart
flutter test test/features/dashboard
flutter test test/features/overtime/overtime_admin_detail_actions_layout_test.dart
flutter test test/core/localization/duration_formatter_test.dart
```

Run the commands locally to obtain current pass/fail results for your environment.

---

## Setup / Installation

### Prerequisites

- **Node.js 20+**
- **MongoDB 6+** (local or Atlas)
- **Flutter SDK** with Dart **3.12+** (see `mobile/pubspec.yaml`)
- **Cloudinary** account for production media uploads
- Windows desktop: Visual Studio with the **Desktop development with C++** workload (Flutter Windows requirements)

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

### Flutter (shared)

```bash
cd mobile
flutter pub get
flutter gen-l10n
```

### Android

```bash
cd mobile
flutter run -d android
```

### Windows

```bash
cd mobile
flutter run -d windows
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
| Flutter run (connected device) | `cd mobile && flutter run` |
| Flutter Android | `cd mobile && flutter run -d android` |
| Flutter Windows | `cd mobile && flutter run -d windows` |
| Flutter analyze | `cd mobile && flutter analyze` |
| Flutter test | `cd mobile && flutter test` |

---

## Build / Release

```bash
# Android APK
cd mobile
flutter build apk --release

# Android App Bundle (Play Store)
flutter build appbundle --release

# Windows desktop
flutter build windows --release
```

Windows output is under `mobile/build/windows/x64/runner/Release/` (executable name remains `mobile.exe`; window title is **INFINITY**).

Do not commit signing keystores, API secrets, or `.env` files.

---

## Environment Variables

Copy `backend/.env.example` → `backend/.env`. **Never commit real secrets.** Use placeholders only.

| Variable | Purpose |
|----------|---------|
| `NODE_ENV` | `development` / `production` / `test` |
| `PORT` | API port (default `3000`) |
| `API_VERSION` | Version segment (default `v1`) |
| `MONGODB_URI` | MongoDB connection string (example: `mongodb://localhost:27017/infinity_fsm`) |
| `JWT_ACCESS_SECRET` / `JWT_REFRESH_SECRET` | Token secrets (≥ 32 chars). Do not use example values in production. |
| `JWT_ACCESS_EXPIRY` / `JWT_REFRESH_EXPIRY` | Token TTLs (defaults `15m` / `7d`) |
| `CORS_ORIGINS` | Allowed origins |
| `RATE_LIMIT_*` | Rate limiting |
| `LOG_LEVEL` | Pino level |
| `CLOUDINARY_CLOUD_NAME` / `CLOUDINARY_API_KEY` / `CLOUDINARY_API_SECRET` | Media uploads |
| `SOCKET_CORS_ORIGINS` | Socket.IO CORS |
| `DEVICE_CLOCK_SKEW_SECONDS` | Clock drift allowance |
| `ATTENDANCE_GPS_ACCURACY_THRESHOLD_METERS` | Attendance GPS gate |
| `OVERTIME_MAX_SESSION_HOURS` | Soft review threshold (default `16`). Not a hard reject cap. |
| `OVERTIME_MAX_REQUEST_HOURS` / `OVERTIME_MIN_REQUEST_HOURS` | Request bounds |
| `OVERTIME_GPS_ACCURACY_THRESHOLD_METERS` | Overtime GPS gate |

Client: `--dart-define=API_BASE_URL=...` and `--dart-define=ENV=development|production`.

---

## API Surface

Primary mount: **`/api/v1`**

```
/health
/health/ready
/auth                 # login, refresh, logout, me
/organization
/attendance
/overtime             # start, checkpoints, end, approve, reject, export
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

See [docs/API.md](./docs/API.md) for the fuller catalog. Some docs modules (e.g. dedicated notifications/search/vehicles services) describe future endpoints that are not yet mounted in `routes/v1`.

---

## Security & Roles

- JWT access + refresh, bcrypt password hashing
- Helmet, CORS allow-list, rate limiting
- RBAC on protected routes
- Device clock skew checks
- GPS accuracy thresholds for attendance / overtime
- Audit logging for sensitive settings changes
- Secrets via environment only
- Client log sanitization for tokens and passwords
- Windows Remember Me uses OS-backed secure storage for tokens only

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

> Prefer this README for the **current shipped UI, overtime policy, dashboard, and Windows auth behavior**. Some docs may still describe planned phases; when in doubt, trust the code under `mobile/` and `backend/src/`.

---

## License

Released under the [MIT License](./LICENSE).

---

## Author

**Mazen Mahmoud** — Total-Com Solutions

Built as an enterprise Field Service Management platform for real-world technician and workforce operations.
