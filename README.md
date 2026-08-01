# Infinity FSM

**Enterprise Field Service Management Platform**

Infinity FSM is a production-oriented Field Service Management (FSM) system built for companies that manage technicians in the field. It combines attendance, overtime, travel overtime, GPS verification, live camera capture, work orders, inventory, assets, preventive maintenance, reporting, and role-based access control into one coherent platform.

Designed for phones and tablets. Built with an offline-ready architecture. Backed by a modular Node.js API and a Clean Architecture Flutter client.

---

## Features

- **Authentication** — JWT access/refresh tokens, secure local session storage
- **Role-based dashboards** — Admin, Supervisor, and Technician executive views
- **Attendance** — Clock in/out, breaks, GPS + live selfie verification
- **Overtime** — Normal overtime with photo and location evidence
- **Travel Overtime** — Dedicated travel OT tracking workflow
- **GPS Tracking** — High-accuracy location capture with reverse geocoding
- **Live Camera Verification** — Mandatory live photo capture (no gallery fallback)
- **Work Orders** — Create, assign, accept, execute, and complete field jobs
- **Inventory** — Warehouses, spare parts, stock movements, low-stock alerts
- **Assets** — Asset registry, categories, history, QR-ready architecture
- **Preventive Maintenance (PM)** — Plans, schedules, checklists, history
- **Service Reports** — Report generation and customer signatures
- **Roles & Permissions** — Fine-grained RBAC (Admin / Supervisor / Technician)
- **Notifications** — In-app notification feed
- **Settings & Profile** — Organization, account, and system preferences
- **Localization** — English and Arabic (RTL-ready)
- **Offline-ready repositories** — Interfaces prepared for offline sync
- **Real-time foundation** — Socket.IO enabled backend

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
Sync & Search foundations
```

### Flutter (Clean Architecture)

```
Presentation  →  Cubits (flutter_bloc)
Domain        →  Entities / Use Cases / Repository interfaces
Data          →  Models / Remote datasources / Repository implementations
```

### Backend

```
Routes → Validators → Controllers → Services → Mongoose Models
```

---

## Tech Stack

| Layer | Technology |
|-------|------------|
| Mobile | Flutter, Material 3, flutter_bloc (Cubit), Clean Architecture |
| Backend | Node.js, Express, MongoDB, Mongoose, JWT, Socket.IO |
| Media | Cloudinary |
| Maps | OpenStreetMap (`flutter_map`) |
| Localization | Flutter gen-l10n (EN / AR) |

---

## Screenshots

> Replace the placeholders in `/screenshots` with real captures before publishing.

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

---

## Project Structure

```
infinity-fsm/
├── backend/                 # Node.js + Express API
│   ├── src/
│   │   ├── config/
│   │   ├── modules/
│   │   │   ├── core/        # auth, rbac, organization, settings, dashboard, ...
│   │   │   └── business/    # attendance, overtime, work-orders, inventory, assets, pm, ...
│   │   └── shared/          # middleware, errors, utils
│   ├── scripts/
│   └── .env.example
├── mobile/                  # Flutter application
│   ├── lib/
│   │   ├── core/            # network, theme, router, localization, services
│   │   ├── features/        # feature modules (Clean Architecture)
│   │   └── shared/
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
- Flutter **3.24+** / Dart **3.5+**
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

---

## Running Locally

```bash
# Terminal 1 — API
cd backend
cp .env.example .env
npm install
npm run dev

# Terminal 2 — Flutter
cd mobile
flutter pub get
flutter run
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
├── /notifications
├── /settings
└── /time
```

See [docs/API.md](./docs/API.md) for the full catalog.

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

See [docs/RBAC.md](./docs/RBAC.md).

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
