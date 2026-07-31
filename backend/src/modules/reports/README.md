# Reports Module

Monthly overtime aggregation and export.

## Endpoints

| Method | Path | Access |
|--------|------|--------|
| GET | `/api/v1/reports/monthly` | Supervisor+ |
| GET | `/api/v1/reports/monthly/export` | Supervisor+ |
| GET | `/api/v1/reports/employee/:userId` | Role-based |

## Report Structure

Per employee, per month:
- Regular Overtime: approved / rejected / pending hours
- Travel Overtime: approved / rejected / pending hours
- Session counts by status

## Implementation

Uses MongoDB aggregation pipeline on `overtime_records` collection.

**Implementation:** Phase 4
