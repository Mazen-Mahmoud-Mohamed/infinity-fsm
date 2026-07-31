# Dashboard Module

Aggregated KPI provider. Collects metrics from all registered business modules.

## Endpoints

| Method | Path | Permission |
|--------|------|------------|
| GET | `/dashboard` | `dashboard:view` |
| GET | `/dashboard/technician-status` | `dashboard:view` |

## KPI Providers

Each business module registers KPI calculators:

```javascript
dashboardRegistry.register('overtime', {
  kpis: ['running', 'pendingReview', 'approvedToday', ...],
  calculator: async (scope) => { ... }
});
```

## MVP KPIs

Running overtime, pending reviews, approved/rejected today, today/monthly hours (regular + travel), online/offline technicians, org counts.

**Implementation:** Phase 4
