# INFINITY

Enterprise Field Service Management for workforce operations — work orders, overtime journeys, attendance, notifications, and administration.

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Node.js](https://img.shields.io/badge/Node.js-339933?style=for-the-badge&logo=nodedotjs&logoColor=white)
![Express](https://img.shields.io/badge/Express-000000?style=for-the-badge&logo=express&logoColor=white)
![MongoDB](https://img.shields.io/badge/MongoDB-47A248?style=for-the-badge&logo=mongodb&logoColor=white)
![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)
![Windows](https://img.shields.io/badge/Windows-0078D6?style=for-the-badge&logo=windows&logoColor=white)

**INFINITY** (Infinity FSM) is a production-oriented Field Service Management platform developed for **Total-Com Solutions** and maintenance companies with field teams. One Flutter client and one Node.js API cover technician capture, supervisor review, and admin configuration — in **English (LTR)** and **Arabic (RTL)** on **Android**, **tablets**, and **Windows**.

**Current production client release:** **v1.0.12** (build **13**, channel **stable**). Version/build live in `mobile/pubspec.yaml` and are published through the GitHub Actions release pipeline.

On viewports **≥ 900 px**, the client activates a **dedicated Windows desktop experience** — sidebar navigation, global top bar, desktop page layouts, data tables, and fixed bottom action footers. Mobile and tablet layouts remain **responsive first-class flows**; they are not stretched desktop layouts.

---

## Table of Contents

1. [Overview](#1-overview)
2. [Main Features](#2-main-features)
   - [Windows Desktop Experience](#windows-desktop-experience)
3. [User Roles](#3-user-roles)
4. [Technician Experience](#4-technician-experience)
5. [Technician Interface Control](#5-technician-interface-control)
6. [Overtime Workflow](#6-overtime-workflow)
7. [Notifications](#7-notifications)
8. [Update Center & Auto Update](#8-update-center--auto-update)
9. [Offline & Sync](#9-offline--sync)
10. [Performance Optimizations](#10-performance-optimizations)
11. [Localization](#11-localization)
12. [Security](#12-security)
13. [Technology Stack](#13-technology-stack)
14. [Project Structure](#14-project-structure)
15. [Development Setup](#15-development-setup)
16. [Testing](#16-testing)
17. [Build & Release](#17-build--release)
18. [Environment Variables](#18-environment-variables)
19. [Firebase Integration](#19-firebase-integration)
20. [Deployment](#20-deployment)
21. [API Overview](#21-api-overview)
22. [Performance Notes](#22-performance-notes)
23. [Important Implementation Notes](#23-important-implementation-notes)
24. [Recent Updates](#24-recent-updates)
25. [Troubleshooting](#25-troubleshooting)
26. [Documentation](#26-documentation)
27. [License](#27-license)
28. [Author](#28-author)

---

## 1. Overview

**INFINITY** helps organizations run field operations from a single full-stack platform:

- Create, assign, and complete **work orders** with customer context and optional location address/link
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
| **Current client** | **v1.0.12+13** · channel **stable** · GitHub Releases primary |

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
- **Log out all devices** (revokes refresh tokens + deactivates push device tokens)
- Role- and permission-based access (RBAC / dynamic roles)

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

#### Desktop Overtime Management (Windows)

| Feature | Behavior |
|---------|----------|
| **Layout** | Title → search → status filters → expanded table → fixed bottom **Export Excel** |
| **Search** | Technician search (same desktop toolbar pattern as Work Orders) |
| **Status filters** | All · Pending · Approved · Rejected |
| **Table columns** | Technician · Type · Status · **Per Diem** · Start · End · Overtime Hours |
| **Technician column** | Shows **`OvertimeTechnicianSummary.displayName` only** (email is not shown in the desktop table; it remains in models, API, and search logic) |
| **Per Diem column** | Uses the existing **`OvertimeSession.isOvernight`** boolean (travel overnight / per-diem condition). Rendered as compact **Yes** / **No** badges — **no new backend field** |
| **Export** | **Export Excel** stays in the fixed bottom footer (not above search) |

Mobile/tablet admin overtime continues to use responsive session cards (`AppResponsiveCardList`).

### 📝 Work Orders

- Create, list, assign, accept, reject, complete, and cancel work orders
- Status flow: `PENDING` → `ASSIGNED` → `ACCEPTED` / `REJECTED` → `IN_PROGRESS` → `COMPLETED` / `CANCELLED`
- Priorities: `LOW` · `MEDIUM` · `HIGH` · `CRITICAL`
- **Multiple technician assignees** (`assignedTechnicianIds`) with a primary assignee
- Scheduled date/time and customer information
- **Location model** — plain-text address + optional map URL (see below)
- **Customer phone numbers** (optional, zero or more per work order)
- Notes, voice notes, attachments, and execution photos (before / during / after where supported)
- Timeline-oriented detail flows
- Technician execution workflow with permission-aware UI (admin vs technician views)

#### Work Order location (address + optional link)

| Field | Purpose |
|-------|---------|
| **`locationLabel`** | Normal text address (street / site description) |
| **`locationUrl`** | Optional HTTP/HTTPS map or location link |

| Behavior | Detail |
|----------|--------|
| **Create / edit** | Address and optional “location link” are separate form fields; removing the link does not clear the address |
| **Technician overview** | Address text is shown when a human-readable label is available |
| **Location action** | Open-location button appears **only** when a valid `http`/`https` URL exists (`hasOpenableLocationUrl`) |
| **Legacy data** | Older records that stored a URL in `locationLabel` with an empty `locationUrl` are split for editing so the URL is not silently lost |
| **Validation** | Backend accepts independent label + URL; URL must be valid `http(s)` when provided |

#### Desktop Work Orders (Windows)

| Feature | Behavior |
|---------|----------|
| **List** | `WorkOrdersDesktopView` — searchable table with status filter chips |
| **Columns** | Job number, title, customer, location, technicians (admin), priority, status, scheduled date |
| **Search** | Technician/job search field (max width 480 px, aligned with page title) |
| **Actions** | **Create Order** and **Refresh** in a fixed bottom footer (compact buttons, right-aligned) |
| **Create / edit** | Desktop form layout in `work_order_form_page.dart` with fixed bottom **Close** / **Save** |
| **Refresh** | Pull-to-refresh on the table; footer Refresh always available |

Mobile and tablet continue to use the existing card/list presentation on narrower viewports.

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
- Structured `data` payload for navigation (`workOrderId`, `overtimeId`, `jobNumber`, `type=app_update`, etc.)
- **Deep-link navigation** to work-order, overtime admin detail, and Update Center routes
- Pending navigation queue until auth/router bootstrap completes
- Mark-as-read when a notification is opened
- Idempotent navigation (duplicate tap protection)
- **App-update notifications** when a GitHub Release is published (see [§8](#8-update-center--auto-update))

See [§7 Notifications](#7-notifications) for platform behavior (Android FCM, Windows Socket.IO, deep links).

### 🕐 Attendance

- Attendance dashboard (clock in/out, breaks where implemented)
- Shared `AttendanceCubit` (single status / today fetch and poll)
- Attendance sync with connectivity awareness
- GPS accuracy gates on the backend
- **Desktop admin table** (`AttendanceAdminDesktopTable`) for reviewing sessions on wide viewports
- **`AppDesktopDataTable`** uses matching **min/max row height (52 px)** so desktop DataTable rendering stays stable on Windows

### 📦 Inventory · Assets · PM · Reports

- Inventory (warehouses, parts, low-stock style alerts on dashboard)
- Assets registry
- Preventive maintenance plans / schedules
- Service reports (list, detail, generation/download, customer signature support)
- Reports Center hub and overtime Excel Save As flow on desktop

### ⚙️ Settings

- Language, theme, and notification preferences
- Sync settings (auto sync, interval, Wi‑Fi-only)
- Overtime media settings + Configuration Testing Lab (local preview; no Cloudinary upload from the lab)
- **Technician Interface** controls (Admin)
- **Update Center** (check / download / install; Auto Update toggle — default **OFF**)
- Account overview, password change, and **Log out all devices** (revokes refresh tokens and deactivates registered push tokens)
- About / package **version + build** from the installed application (`package_info_plus`)
- Storage guidance and update-artifact cleanup (honest status — no fake storage meters)
- Support contact flows that open real system actions (not placeholder UI)
- Server Management API base override (admin-protected)
- Settings reachable from technician main sections when profile/settings is enabled

Placeholder / mock settings tiles that previously appeared as incomplete UI have been removed.

### 🔄 App updates

- **Update Center** — latest release check, download, verify, and install for Android APK and Windows installer
- **Auto Update** — optional; default OFF; see [§8 Update Center & Auto Update](#8-update-center--auto-update)
- **GitHub Releases** — primary release source via backend `/releases/latest` and `release-manifest.json`
- **Automated release notes** — short user-facing GitHub Release body (and matching `releaseNotes` in the manifest)
- **Release webhook** — GitHub → backend HMAC-verified notify path for `app_update` notifications

### 🌐 Connectivity & Offline

- API health–based connectivity (authoritative sync gate)
- Offline mode for overtime pending actions
- **Cached technician interface configuration** (per company) for offline navigation
- Retry synchronization on reconnect
- Configurable sync interval (`5 / 15 / 30 / 60` minutes)
- Wi‑Fi-only sync for overtime (when enabled)
- Global search palette across existing module APIs (no dedicated `/search` API)

> **Vehicles** is schema-ready documentation only and is **not** implemented in the API or UI.

### Windows Desktop Experience

Activated at **`AppBreakpoints.tabletMax` (900 px+)** on Windows (and wide desktop viewports). Shared building blocks live under `mobile/lib/core/widgets/desktop/`.

| Area | Desktop behavior |
|------|------------------|
| **Shell** | Collapsible **sidebar** navigation + global **top bar** inside `MainNavigationShell` |
| **Page layout** | Title, search, filters, and scrollable content aligned to the desktop workspace width |
| **Tables** | `AppDesktopDataTable` — rounded surface, normalized **52 px** row/header height, horizontal scroll for wide datasets |
| **Empty / loading** | Desktop empty states and refresh bars; existing data stays visible during refresh (`isRefreshing`) |
| **Action footers** | Fixed bottom **SafeArea** footers for primary actions (Work Orders, Overtime, Work Order form) |

**Module desktop surfaces (current):**

| Module | Desktop presentation |
|--------|----------------------|
| **Work Orders** | Full-width table, search, status filters, **Create Order** + **Refresh** in fixed bottom footer |
| **Work Order create/edit** | Desktop form layout with fixed bottom **Close** / **Save** |
| **Overtime Management** | Table with technician search, status filters, **Export Excel** in fixed bottom footer |
| **Attendance (admin)** | Desktop data table for session review |
| **Users / Roles** | Desktop tables for list management |
| **Notifications** | Desktop list view |
| **Dashboard, Inventory, Assets, PM, Reports, Settings, Profile** | Desktop-aware page layouts and spacing |

Mobile/tablet code paths are unchanged for modules that branch on `AppBreakpoints.isDesktopOf(context)`.

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
- **Location address** text when a human-readable label is available
- **Open Location** action only when a valid HTTP/HTTPS location URL exists
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
| `/settings/updates` | Update Center (app-update notifications) |

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
- Production Android APKs receive Firebase client config via **CI secret injection** (see [§19 Firebase Integration](#19-firebase-integration)); local developers may place `google-services.json` under `mobile/android/app/` (**gitignored**)
- Backend Firebase Admin credentials via environment (see [§18 Environment Variables](#18-environment-variables) / [§19](#19-firebase-integration))
- `FCM_ENABLED=true` on the API
- Android 13+ notification permission granted by the user
- Channels created at push init: `infinity_default` and `infinity_updates` (HIGH importance for update pushes)

Android release builds use **core library desugaring** (`desugar_jdk_libs`) required by `flutter_local_notifications`.

### App-update notifications

| Topic | Behavior |
|-------|----------|
| **Trigger** | GitHub Release webhook (`release` event, actions `published` / `released` / `created`) |
| **Persistence** | One `app_update` notification per active user (dedupe key `app-update:v{version}:{build}`) |
| **Android** | FCM notification + data (`type=app_update`, route `/settings/updates`) |
| **Windows** | Socket.IO + local toast **while the app process is running** (no terminated Windows push) |
| **Reconciliation** | Connectivity / resume / Update Center checks can surface a newer release if a push was missed |
| **Auto Update ON** | Suppresses competing standard update banner/notification while auto-flow owns the release |
| **Idempotency** | Duplicate webhook deliveries for the same version+build do not create duplicate rows |

---

## 8. Update Center & Auto Update

Settings → **Updates** (`UpdateCenterPage` / `UpdateCenterCubit`). Releases are discovered from the backend **`GET /api/v1/releases/latest?channel=stable`**, which prefers **GitHub Releases** (`release-manifest.json`) with optional **`APP_RELEASE_*`** env fallback.

### Update Center

| Capability | Behavior |
|------------|----------|
| **Latest check** | Fetches the stable-channel release manifest from the API |
| **Version compare** | Semantic version + integer build (`compareAppVersions`) |
| **Artifacts** | Android **APK** and Windows **Inno Setup installer** when marked available |
| **Manifest** | Version, build, channel, **userNotes**, download URLs, **SHA-256**, **file size** |
| **Verification** | Downloaded files verified for size and SHA-256 before install |
| **Cache** | Last successful manifest cached locally for offline display |
| **Artifacts on disk** | Versioned filenames under the app updates directory |
| **Stale cleanup** | Startup / post-download cleanup removes installed and older APKs/EXEs so old installers do not accumulate |
| **Android install** | Opens the **system package installer** — **no silent install** and no bypass of Android security prompts |
| **Windows install** | Launches the downloaded installer; does **not** overwrite the running executable in-place |

### Auto Update

| Topic | Behavior |
|-------|----------|
| **Toggle** | Inside Update Center; preference persisted |
| **Default** | **OFF** |
| **When ON** | Detects available updates and drives download → verify → install orchestration (`AppAutoUpdateManager`) |
| **UI competition** | Suppresses the standard update available banner/notification while auto-update owns the flow |
| **Background download** | Continues while navigating away from Update Center **as long as the app process remains alive** |
| **Triggers** | Startup, resume, connectivity restore, and periodic/auto checks where wired |
| **Deduplication / backoff** | Per version+platform locks and failure backoff avoid duplicate downloads |
| **Android** | Still uses the system package installer (user confirmation required) |
| **Windows** | Uses the installer flow without replacing the live EXE mid-run |

> Auto Update does **not** guarantee continued work after the OS fully terminates the app process. Terminated Android devices rely on **FCM** for update *notifications*; download/install still requires a running app (and user confirmation on Android).

### Release notification architecture (backend)

```
GitHub Release published
        ↓
POST /api/v1/releases/webhook/github
  · HMAC SHA-256 (X-Hub-Signature-256)
  · Original raw body preserved for verification
        ↓
Exact release from payload.release / tag
  · Prefer release-manifest.json for that tag
  · May fetch /releases/tags/{tag} if needed
  · Does not rely on /releases/latest during publish
  (GitHub /releases/latest can briefly lag)
        ↓
notifyUsers → persist app_update + Socket.IO + FCM
  · Dedupe: app-update:v{version}:{build}
```

Client discovery (`/releases/latest`) continues to use GitHub’s latest release (with short-lived cache) for Update Center checks after publication has settled.

---

## 9. Offline & Sync

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

## 10. Performance Optimizations

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

## 11. Localization

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

## 12. Security

Verified behavior only:

- JWT access + refresh; passwords hashed with **bcrypt**
- Role-based permissions on protected backend routes and client gates (dynamic roles + static fallback)
- Admin settings authorization (`settings:manage` for Technician Interface, etc.)
- Secure token storage (`flutter_secure_storage`)
- Remember Me stores **session/refresh tokens** (and remembered email) — **never the password**
- Logout clears persisted session where applicable (Windows Remember Me policy clears tokens)
- **Log out all devices** revokes refresh tokens server-side and deactivates registered device push tokens
- DB-authoritative user validation (`isActive`, `deletedAt`, company, roles)
- JWT is **not** the sole authorization source after verify
- Helmet, CORS allow-list, rate limiting
- Device clock skew checks; GPS accuracy thresholds
- Client log sanitization for tokens / passwords
- **GitHub Release webhook** authenticated with **HMAC SHA-256** over the original raw request body
- Secrets via environment / CI only — never commit `.env`, service-account JSON, or `google-services.json`

> **Never commit** Firebase service-account JSON files, private keys, API secrets, database credentials, JWT secrets, webhook secrets, FCM tokens, or other sensitive credentials to Git. **Never paste credentials into this README.** Production credentials belong in **Render** and **GitHub Actions** secret stores.

### Secrets inventory (names only)

| Secret / env (name) | Where |
|---------------------|--------|
| `MONGODB_URI`, JWT secrets, Cloudinary, `FIREBASE_SERVICE_ACCOUNT_JSON` | Render (API) |
| `GITHUB_RELEASE_WEBHOOK_SECRET` | Render + matching GitHub webhook secret |
| `GOOGLE_SERVICES_JSON_BASE64`, Android keystore secrets | GitHub Actions |
| Optional `GITHUB_RELEASE_TOKEN` | Render (GitHub API rate limits / private repos) |

### Windows Remember Me (summary)

1. Sign in with Remember Me → tokens in secure storage (serialized writes).
2. Password never stored.
3. Full restart restores session from refresh/session tokens; expired access refreshes automatically.
4. Invalid refresh → session cleared → Sign in.
5. Remember Me **off** → tokens in memory only for the live process.
6. Android keeps existing always-persist-to-secure-storage behavior; Windows policy does not change mobile auth.

---

## 13. Technology Stack

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

## 14. Project Structure

```
infinity-fsm/
├── backend/                 # Node.js / Express API
│   ├── src/
│   │   ├── config/
│   │   ├── modules/
│   │   │   ├── core/        # auth, rbac, dashboard, users, settings, releases, …
│   │   │   ├── business/    # attendance, overtime, work-orders, inventory, assets, pm, reports
│   │   │   └── notifications/  # in-app + FCM + device tokens + hooks
│   │   ├── routes/          # /api/v1
│   │   ├── shared/          # middleware, utils
│   │   └── __tests__/
│   ├── scripts/             # seed & migrations
│   └── .env.example
├── mobile/                  # Flutter client (Android + Windows)
│   ├── lib/
│   │   ├── core/            # theme, router, l10n, DI, network, storage, push
│   │   │   └── widgets/desktop/  # AppDesktopDataTable, sidebar, top bar, …
│   │   ├── features/        # auth, dashboard, attendance, overtime, notifications,
│   │   │                    # work_orders, inventory, assets, pm, reports, users, roles,
│   │   │                    # settings, app_update, …
│   │   └── shared/
│   ├── android/
│   ├── windows/             # runner title: INFINITY
│   ├── tool/                # sync/verify firebase_options helpers (CI)
│   ├── test/
│   └── assets/
├── .github/workflows/
│   └── release.yml          # Android APK + Windows installer + GitHub Release
├── docs/                    # Architecture, API, RBAC, roadmap, …
│   └── releases/            # Optional per-version release-notes overrides
├── infra/                   # Deployment planning notes
├── scripts/release/         # Version resolve, release notes, release-manifest
├── tests/                   # Shared / auxiliary test assets (where present)
├── installer.iss            # Windows Inno Setup installer
├── LICENSE
└── README.md
```
**Architecture (Flutter):** Presentation (pages/widgets + Cubits) → Domain (entities, use cases, repository interfaces) → Data (models, datasources, repositories). Feature folders under `mobile/lib/features/*`.

**Architecture (Backend):** Routes → Validators → Controllers → Services → Mongoose models. Modules under `backend/src/modules/*`.

---

## 15. Development Setup

### Requirements

- Flutter SDK with Dart **^3.12**
- Node.js **≥ 20**
- npm
- MongoDB (local or Atlas) / configured backend
- Cloudinary account for production media uploads
- Windows desktop: Visual Studio **Desktop development with C++** workload
- Android push: Firebase project; production APKs get client config via CI secrets (local optional `google-services.json`, gitignored)
- Backend push: Firebase Admin service-account credentials via environment (see §18–§19)

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

## 16. Testing

### Backend (Jest)

Under `backend/src/__tests__/`, including:

- Overtime calculation, calendar-day split, end-duration policy
- Dashboard overtime trends / live-activity / list-projection
- Overtime Excel export / timeline / approved hours
- Auth parallel role prefetch · **logout-all devices**
- RBAC
- Notification hooks and push delivery
- Work order customer phones / multi-assignee
- Technician interface settings
- **Releases** — GitHub manifest parsing, env fallback, webhook HMAC/raw-body, race-safe webhook resolution

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
- **App Update** — Update Center cubit, artifact verification, stale cleanup, Auto Update locks
- Push notification navigation / pending intent mapping
- Work orders, attendance, desktop shell / Work Orders / Overtime table tests

```bash
cd mobile
flutter test
flutter analyze
```

**Latest full Flutter suite:** **353 / 353** tests passed (local verification).

> Do not treat analyzer “issue count” as error count — most findings are info/style; compile errors are separate. Release CI and the Flutter test suite are the authoritative validation gates for client changes.

---

## 17. Build & Release

### Current production client

| Field | Value |
|-------|--------|
| **Version** | **1.0.12** |
| **Build** | **13** (`1.0.12+13` in `mobile/pubspec.yaml`) |
| **Channel** | **stable** |
| **Distribution** | GitHub Release assets (APK + Windows installer + `release-manifest.json`) |

### Automated release pipeline (primary)

Workflow: [`.github/workflows/release.yml`](./.github/workflows/release.yml)

Triggered by pushing a tag matching `v*.*.*` (or `workflow_dispatch` rebuild of an existing tag).

| Step | What happens |
|------|----------------|
| **Resolve version** | Tag `vX.Y.Z` must match `mobile/pubspec.yaml` `version: X.Y.Z+N` |
| **Android APK** | `flutter build apk --release` with signing secrets |
| **Firebase (CI)** | Decodes `GOOGLE_SERVICES_JSON_BASE64`, syncs/validates `firebase_options.dart`, cleans secrets from the runner afterward |
| **Signing check** | Verifies APK certificate SHA-256 against the expected production fingerprint |
| **Windows** | `flutter build windows --release` + **Inno Setup** (`installer.iss`) |
| **Release notes** | `scripts/release/generate-release-notes.mjs` — short **user-facing** notes from commits since the previous `v*.*.*` tag (CI/test/infra commits omitted) |
| **Manual notes override** | Optional `docs/releases/vX.Y.Z.md` replaces generated notes when present |
| **Manifest** | `scripts/release/generate-release-manifest.mjs` — SHA-256 + sizes; `releaseNotes` matches the GitHub Release body |
| **Publish** | GitHub Release with `app-release.apk`, `INFINITY-Setup-{version}.exe`, `release-manifest.json` |

Empty or boilerplate-only release notes fail the publish job. See [docs/releases/README.md](./docs/releases/README.md).

### Recommended release process

```text
1. Bump mobile/pubspec.yaml → version: X.Y.Z+N
2. Commit and push to main
3. Create and push tag vX.Y.Z  (must match pubspec version)
4. GitHub Actions builds Android + Windows, generates release notes, and publishes the GitHub Release
5. Backend discovers the release via GitHub (Update Center /releases/latest)
6. GitHub webhook notifies clients (app_update) using the exact release tag/payload
```

```bash
# Example — after pubspec is already 1.0.12+13 on main:
git tag v1.0.12
git push origin v1.0.12
```

Do **not** create a tag whose semver does not match `mobile/pubspec.yaml` — the workflow will fail resolve-version.

### Local / manual builds (optional)

```bash
cd mobile
flutter clean && flutter pub get
flutter build apk --release
flutter build windows --release
```

Typical outputs:

- `mobile/build/app/outputs/flutter-apk/app-release.apk`
- `mobile/build/windows/x64/runner/Release/` (executable `mobile.exe`; window title **INFINITY**)

Optional local installer: root `installer.iss` (Inno Setup).

Windows builds require Visual Studio C++ tooling. **`firebase_core`** may download the Firebase C++ SDK during Windows builds — see `mobile/windows/FIREBASE_CPP_SDK.md` if extraction fails (disk space / OneDrive paths).

Do not commit signing keystores, API secrets, `.env`, `google-services.json`, or Firebase service-account JSON files.

---

## 18. Environment Variables

Copy `backend/.env.example` → `backend/.env`. **Never commit real secrets.**

| Variable | Purpose |
|----------|---------|
| `NODE_ENV` | `development` / `production` / `test` |
| `PORT` | API port (default `3000`) |
| `API_VERSION` | Version segment (default `v1`) |
| `MONGODB_URI` | MongoDB URI |
| `JWT_ACCESS_SECRET` / `JWT_REFRESH_SECRET` | Token secrets (≥ 32 chars) |
| `JWT_ACCESS_EXPIRY` / `JWT_REFRESH_EXPIRY` | Defaults `15m` / `7d` |
| `CORS_ORIGINS` | Allowed origins (comma-separated) |
| `RATE_LIMIT_WINDOW_MS` / `RATE_LIMIT_MAX` / `RATE_LIMIT_AUTH_MAX` | Rate limiting |
| `LOG_LEVEL` | Pino level |
| `CLOUDINARY_CLOUD_NAME` / `CLOUDINARY_API_KEY` / `CLOUDINARY_API_SECRET` | Media uploads |
| `SOCKET_CORS_ORIGINS` | Socket.IO CORS |
| `FCM_ENABLED` | `true` / `false` — disable push without removing code |
| `FIREBASE_SERVICE_ACCOUNT_JSON` | **Option A:** full service-account JSON as one line (recommended on Render) |
| `FIREBASE_SERVICE_ACCOUNT_PATH` | **Option B:** absolute path to service-account JSON file (local dev) |
| `APP_RELEASE_SOURCE` | `auto` (default) · `github` · `env` |
| `APP_RELEASE_GITHUB_ENABLED` | `true` / `false` |
| `APP_RELEASE_GITHUB_OWNER` / `APP_RELEASE_GITHUB_REPO` | GitHub repository for releases |
| `APP_RELEASE_GITHUB_CACHE_TTL_MS` | In-memory GitHub latest cache (default `300000`) |
| `GITHUB_RELEASE_TOKEN` | Optional GitHub API token |
| `APP_RELEASE_VERSION` / `APP_RELEASE_BUILD` / … | **Fallback** manifest when GitHub is unavailable |
| `APP_RELEASE_CHANNEL` | Default `stable` |
| `GITHUB_RELEASE_WEBHOOK_SECRET` | Shared secret for GitHub Release webhook HMAC |
| `DEVICE_CLOCK_SKEW_SECONDS` | Clock drift allowance |
| `ATTENDANCE_GPS_ACCURACY_THRESHOLD_METERS` | Attendance GPS gate |
| `OVERTIME_MAX_SESSION_HOURS` | Soft review threshold (default `16`) |
| `OVERTIME_MAX_REQUEST_HOURS` / `OVERTIME_MIN_REQUEST_HOURS` | Request bounds |
| `OVERTIME_GPS_ACCURACY_THRESHOLD_METERS` | Overtime GPS gate |

**FCM credentials:** provide **either** `FIREBASE_SERVICE_ACCOUNT_JSON` **or** `FIREBASE_SERVICE_ACCOUNT_PATH`. Push is enabled when `FCM_ENABLED` is not `false` and credentials resolve.

**Client:** `--dart-define=API_BASE_URL=...` and `--dart-define=ENV=development|production`.

### GitHub Actions release secrets (names only)

| Secret | Purpose |
|--------|---------|
| `GOOGLE_SERVICES_JSON_BASE64` | Base64 `google-services.json` for CI Android builds |
| `ANDROID_KEYSTORE_BASE64` | Release keystore |
| `ANDROID_KEYSTORE_PASSWORD` / `ANDROID_KEY_ALIAS` / `ANDROID_KEY_PASSWORD` | Signing |

---

## 19. Firebase Integration

| Component | Configuration |
|-----------|---------------|
| **Android app ID** | `com.example.mobile` |
| **Android client config** | Provided to CI via `GOOGLE_SERVICES_JSON_BASE64` — **not** committed |
| **Flutter Firebase options** | Generated/validated in CI (`mobile/tool/sync_firebase_options.js`, `verify_firebase_options.js --require-configured`) |
| **Tracked template** | Placeholder `firebase_options.dart` in git; production values are CI-injected |
| **Android FCM** | `firebase_core` + `firebase_messaging`; channels `infinity_default` / `infinity_updates` |
| **Backend FCM** | Firebase Admin SDK — `fcm.service.js` (service-account env only) |
| **Windows** | `firebase_core` may be present for plugin compatibility; **Windows push uses Socket.IO**, not FCM |

### Local Android Firebase (optional)

1. Add Android app **`com.example.mobile`** in Firebase Console.
2. Place `google-services.json` in `mobile/android/app/` (**gitignored**).
3. Optionally run `node mobile/tool/sync_firebase_options.js` for local options.
4. Backend: set `FIREBASE_SERVICE_ACCOUNT_JSON` or `FIREBASE_SERVICE_ACCOUNT_PATH` and `FCM_ENABLED=true`.

**Do not** commit service-account JSON, private keys, or `google-services.json` contents.

---

## 20. Deployment

| Component | Current state |
|-----------|---------------|
| **Backend API** | `https://infinity-fsm-api.onrender.com/api/v1` on **Render**. Configure MongoDB, JWT, Cloudinary, CORS, Socket.IO, Firebase Admin, release GitHub settings, and webhook secret via Render env. |
| **Client artifacts** | **GitHub Releases** (primary) — Android APK + Windows installer + manifest via Actions |
| **Update discovery** | Backend GitHub Releases integration; optional `APP_RELEASE_*` fallback |
| **`infra/`** | Planning notes only |

```
Client release:  pubspec bump → push main → tag vX.Y.Z → GitHub Actions → GitHub Release
Backend:         push main → Render deploy (service-connected) → live API
Notify:          GitHub webhook → Render API → FCM / Socket.IO
```

Bind the API to `PORT` (`0.0.0.0` on Render). Keep secrets in the host environment — never in the repository.

---

## 21. API Overview

Primary mount: **`/api/v1`**

| Group | Path prefix | Notes |
|-------|-------------|--------|
| Health | `/health`, `/health/ready` | Liveness / readiness |
| Auth | `/auth` | Login, refresh, logout, **logout-all**, `/me` |
| Dashboard | `/dashboard` | Role summary & related stats |
| Overtime | `/overtime` | Journey, review, export |
| Attendance | `/attendance` | Clock / history / admin |
| Work Orders | `/work-orders` | CRUD & workflow |
| **Notifications** | `/notifications` | Inbox, unread, mark-as-read, device tokens |
| **Releases** | `/releases` | `GET /latest` (auth); `POST /webhook/github` (HMAC, no JWT) |
| Settings | `/settings` | Including technician interface config |
| Organization | `/organization` | Company / org |
| Users / Roles | `/users`, `/roles` | Admin RBAC |
| Inventory / Assets / PM | `/inventory`, `/assets`, `/pm` | Operations modules |
| Reports | `/reports` | Operational reports |
| Time / Security | `/time`, `/security` | Platform helpers |

Fuller catalog: [docs/API.md](./docs/API.md). Prefer **mounted routes in code** over older planned docs. There is **no** dedicated `/search` API; global search queries existing module endpoints client-side.

Realtime notification events are emitted on Socket.IO (`notification:new`) to authenticated user rooms.

---

## 22. Performance Notes

- Avoid global caching of **real-time** overtime running state
- Dashboard uses **controlled, short-lived** deduplication (in-flight + ~5s fresh reuse) — not a long-lived stale cache
- List endpoints use **lightweight projections**; detail endpoints retain full data
- Auth parallelization reduces sequential Mongo round-trips; DB validation stays authoritative
- Load balancing / Redis are **not** part of the current required architecture based on measured bottlenecks (Atlas RTT + sequential client calls remain the primary latency drivers)

---

## 23. Important Implementation Notes

| Topic | Guarantee |
|-------|-----------|
| Overtime math | Calculation logic lives in backend policy/calculator — separate from UI formatting |
| Admin review | Approve / Partial / Reject behavior preserved |
| Technician UI | Hides technical metadata where designed; admin retains detailed review data |
| Rejection reason | Visible to technician in history when present |
| Offline | Overtime actions persisted and retried; reconciliation when server already confirmed a stage |
| Technician Interface | Company-scoped; Admin/Supervisor navigation unrestricted; **offline cache per company** |
| Notifications | Persist → Socket.IO → FCM (Android); push failures do not fail business operations |
| App updates | Manifest verify (SHA-256 + size); Android uses system installer (**no silent install**) |
| Work Order location | Address (`locationLabel`) + optional URL (`locationUrl`); open-location only for valid `http(s)` |
| Release webhook | Exact tag/payload resolution; HMAC over raw body; dedupe `app-update:v{version}:{build}` |
| Maps | OpenStreetMap only |
| SessionQueryCache | Used to avoid duplicate network fetches where wired |
| Dashboard loading | Prefer `isRefreshing` / cached summary over full-page loaders when data exists |
| Desktop UI | Activated at 900 px+; mobile/tablet layouts remain separate responsive paths |
| Overtime Per Diem (desktop) | **`isOvernight`** only — no new API field |
| Product name | **INFINITY** in UI / Windows title; package `mobile` unchanged; Android `applicationId` `com.example.mobile` |

---

## 24. Recent Updates

### v1.0.12 (current)

- **Work Order location** — separate plain-text address (`locationLabel`) and optional map/location URL (`locationUrl`); Location action only when a valid HTTP/HTTPS link exists; legacy URL-in-label records handled safely on edit
- **Release notes automation** — GitHub Releases publish short user-facing notes from the previous tag; optional override via `docs/releases/vX.Y.Z.md`; same notes stored in `release-manifest.json` for Update Center

### App updates & release automation

- **Update Center** with stable-channel discovery, SHA-256 / size verification, versioned artifacts, and stale APK/EXE cleanup
- **Auto Update** toggle (default OFF) with background download while the process is alive
- **GitHub Actions** release workflow — Android APK (CI Firebase inject + signing check), Windows Inno Setup installer, `release-manifest.json`, GitHub Release publish
- **GitHub Release webhook** — HMAC raw-body verification; race-safe exact tag/payload notify path
- **App-update notifications** — FCM (Android) + Socket.IO (Windows while running); dedupe by version+build
- **Settings cleanup** — removed placeholder tiles; **Log out all devices**; package-backed version/build; honest storage/update messaging

### Windows desktop UI

- Dedicated Windows desktop shell — sidebar, global top bar, desktop page layouts
- Desktop data tables (`AppDesktopDataTable`) with stable row height
- Work Orders / Overtime / Attendance / Users / Roles desktop surfaces
- Work Orders and Overtime fixed bottom action footers polished for desktop

### Earlier improvements

- Work order **customer phone numbers** + Call action
- Technician-simplified work-order detail (permission-aware)
- Admin-controlled technician interface visibility with offline per-company cache
- Notifications module — in-app center, FCM, Socket.IO, deep links
- Clear overtime wording: site finished-work vs journey end
- Android core library desugaring for local notifications
- Optional Windows Firebase C++ SDK path (`mobile/windows/FIREBASE_CPP_SDK.md`)

---

## 25. Troubleshooting

| Symptom | Likely cause / check |
|---------|----------------------|
| Android push never arrives | CI/local Firebase client not configured; `DefaultFirebaseOptions.isConfigured` false; backend `FCM_ENABLED` or Admin credentials missing; notification permission denied |
| FCM works but no tap navigation | Auth/router not ready — pending navigation should consume after login |
| Windows no notifications when app closed | Expected — Windows uses Socket.IO while the process is running, not FCM background push |
| Update Center says up to date but GitHub has a newer tag | Confirm backend can reach GitHub Releases; check `APP_RELEASE_*` fallback is not pinning an older version; re-check after cache TTL |
| App-update push shows wrong version | Ensure Render is running webhook code that resolves the webhook tag/payload (not a stale `/releases/latest` only path) |
| Android install requires confirmation | Expected — system package installer; no silent install |
| Auto Update did nothing after kill | Expected if the process was terminated; FCM may still notify on Android, but download needs a running app |
| Windows build fails on Firebase SDK extract | Low `C:` disk space or OneDrive path — see `mobile/windows/FIREBASE_CPP_SDK.md` |
| Technician sees all tabs offline | Ensure prior online sync stored technician interface config for the company |
| Render push skipped | Set `FIREBASE_SERVICE_ACCOUNT_JSON`; confirm `FCM_ENABLED=true` |
| Release workflow fails resolve-version | Tag `vX.Y.Z` must match `mobile/pubspec.yaml` version |
| Webhook returns 401 | Signature secret mismatch or raw-body parsing broken on the deployed API |

---

## 26. Documentation

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
| [Release notes overrides](./docs/releases/README.md) | Optional manual GitHub Release notes |

> Prefer this README for **current shipped behavior**. Some docs may still describe planned phases; when in doubt, trust `mobile/` and `backend/src/`.

---

## 27. License

Released under the [MIT License](./LICENSE).

---

## 28. Author

**Mazen Mahmoud** — Total-Com Solutions

Built as an enterprise Field Service Management platform for real-world technician and workforce operations.
