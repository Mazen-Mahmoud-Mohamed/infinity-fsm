# Overtime Domain Layer

Pure business logic with no framework dependencies.

## Files (Planned)

| File | Purpose |
|------|---------|
| `overtime.entity.js` | Domain entity with business methods |
| `overtime-calculator.service.js` | Calculate overtime minutes from start/end times |
| `working-hours.policy.js` | Official hours configuration and exclusion logic |

## Overtime Calculator

Input: `startDateTime`, `endDateTime`, `WorkingHoursPolicy`  
Output: `{ rawDurationMinutes, excludedMinutes, overtimeMinutes }`

Must handle:
- Same-day sessions
- Multi-day sessions (split per calendar day)
- Timezone-aware calculations
- All business rule examples from requirements

**Implementation:** Phase 2 (with comprehensive unit tests)
