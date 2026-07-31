# Core Layer

Shared infrastructure used across all features.

## Subdirectories

| Directory | Purpose |
|-----------|---------|
| `constants/` | API URLs, enums, app constants |
| `errors/` | Failure classes, exception handling |
| `network/` | Dio client, interceptors, API response wrapper |
| `storage/` | Hive boxes, secure storage, SQLite database |
| `services/` | Location, camera, device info, connectivity |
| `socket/` | Socket.IO client wrapper |
| `utils/` | Date formatting, validators, extensions |
| `widgets/` | Shared UI components (buttons, loaders, dialogs) |

## Key Components (Planned)

### Network
- `api_client.dart` — Dio instance with base URL, timeouts
- `auth_interceptor.dart` — Attach JWT, handle 401 refresh
- `retry_interceptor.dart` — Retry on network failure
- `api_response.dart` — Standard response wrapper

### Storage
- `hive_service.dart` — Active overtime, user prefs, settings cache
- `secure_storage_service.dart` — JWT tokens
- `sync_database.dart` — SQLite sync queue (drift)

### Services
- `location_service.dart` — GPS with accuracy
- `camera_service.dart` — Camera-only capture
- `device_info_service.dart` — Platform, model, OS version
- `connectivity_service.dart` — Online/offline detection

**Implementation:** Phase 1 (network, storage), Phase 2 (services), Phase 3 (sync DB)
