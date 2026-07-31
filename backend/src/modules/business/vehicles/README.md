# Vehicles Module (Schema-Ready)

Not implemented in MVP. Database schema and assignment tracking designed.

## Entity

Vehicle Code, Plate Number, Type (CAR/VAN/TRUCK/MOTORCYCLE), Make, Model, Year, Status, Branch.

## Endpoints (Return 501 until IN_DEV)

| Method | Path | Permission |
|--------|------|------------|
| GET/POST | `/vehicles` | `vehicles:view` / `vehicles:manage` |
| POST | `/vehicles/:id/assign` | `vehicles:assign` |
| POST | `/vehicles/:id/unassign` | `vehicles:assign` |
| GET | `/vehicles/my-assignment` | `vehicles:view` |

## Assignment Model

`vehicle_assignments` tracks technician ↔ vehicle with assignedAt/unassignedAt.

## Overtime Integration

Overtime records accept optional `vehicleId`. Reports filterable by vehicle (future).

**Implementation:** Phase 6 (full UI). Schema seeded in Phase 4.
