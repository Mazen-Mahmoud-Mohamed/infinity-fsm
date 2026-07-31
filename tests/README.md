# Cross-Cutting Test Assets

E2E, load, and security tests that span backend and mobile.

## Structure (Planned)

```
tests/
├── e2e/                    # Full user journey tests
│   ├── overtime-lifecycle/
│   ├── offline-sync/
│   └── role-workflows/
├── load/                   # k6 performance scripts
│   ├── login-burst.js
│   ├── overtime-concurrent.js
│   └── dashboard-polling.js
├── security/               # OWASP, RBAC bypass, JWT tampering
│   ├── jwt-tampering.test.js
│   ├── rbac-bypass.test.js
│   └── injection.test.js
└── specialized/            # Domain-specific comprehensive suites
    ├── overtime-calculator/
    ├── gps-validation/
    └── offline-sync/
```

See [TESTING.md](../docs/TESTING.md) for complete strategy.

**Implementation:** Phase 0 (structure), Phase 2+ (test suites)
