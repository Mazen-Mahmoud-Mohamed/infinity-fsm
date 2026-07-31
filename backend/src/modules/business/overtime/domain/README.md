# Overtime Domain Layer

Pure business logic — zero framework dependencies.

## Files

| File | Purpose |
|------|---------|
| `overtime.entity.js` | Domain entity |
| `overtime-calculator.service.js` | Server-side overtime calculation |
| `overtime-state-machine.service.js` | 6-state transition validation |
| `working-hours.policy.js` | Official hours + holiday exclusion |
| `gps-quality.policy.js` | GPS accuracy threshold evaluation |
| `travel-metadata.validator.js` | Travel field validation |

## State Machine

Valid transitions enforced here — not in controller:

```javascript
const TRANSITIONS = {
  DRAFT:           ['RUNNING'],
  RUNNING:         ['PENDING_REVIEW', 'DRAFT'],
  PENDING_REVIEW:  ['APPROVED', 'REJECTED'],
  APPROVED:        ['ARCHIVED'],
  REJECTED:        ['ARCHIVED'],
  ARCHIVED:        []
};
```

## Test Requirements

- 10+ calculator test cases (mandatory business examples)
- Every valid transition tested
- Every invalid transition rejected
- Holiday exclusion tests
- Multi-day session tests
- Timezone tests

See [TESTING.md](../../../../../docs/TESTING.md).

**Implementation:** Phase 0 (tests), Phase 2 (implementation)
