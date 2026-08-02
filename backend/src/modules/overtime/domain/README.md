# Overtime Domain Layer

Authoritative overtime duration logic lives in the business overtime module:

| File | Purpose |
|------|---------|
| `../business/overtime/working-hours.policy.js` | Official hours `09:00–17:00`, `Africa/Cairo`, Friday = full OT |
| `../business/overtime/overtime.calculation.js` | `calculateOvertimeDurations` (single backend calculator) |

Do **not** add a parallel calculator here.

Flutter mirrors the same rules in `mobile/lib/features/overtime/domain/services/overtime_calculator.dart` for offline preview only. After sync, the API values are authoritative.
