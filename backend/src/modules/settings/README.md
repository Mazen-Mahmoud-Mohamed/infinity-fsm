# Settings Module

Company-level configuration management.

## Endpoints

| Method | Path | Access |
|--------|------|--------|
| GET | `/api/v1/settings` | Admin |
| PUT | `/api/v1/settings/:key` | Admin |
| GET | `/api/v1/settings/working-hours` | Authenticated |

## Default Settings

| Key | Default | Group |
|-----|---------|-------|
| `working_hours.start` | `"09:00"` | working_hours |
| `working_hours.end` | `"17:00"` | working_hours |
| `overtime.min_job_description_length` | `10` | overtime |
| `overtime.gps_accuracy_threshold_meters` | `100` | overtime |
| `overtime.max_session_hours` | `16` | overtime |

Changes are audit-logged.

**Implementation:** Phase 4
