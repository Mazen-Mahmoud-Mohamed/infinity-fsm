# Maps Module

Google Maps Platform integration for geocoding and map data.

## Endpoints

| Method | Path | Access |
|--------|------|--------|
| POST | `/api/v1/maps/reverse-geocode` | Authenticated |
| GET | `/api/v1/maps/overtime/:id` | Role-based |

## Responsibilities

- Reverse geocode lat/lng → readable address (server-side for consistency)
- Assemble map pin data for overtime records (start + end locations)
- Cache geocoding results to reduce API costs

## Google APIs Used

- Geocoding API (reverse geocoding)
- Static Maps API (future PDF reports)

**Implementation:** Phase 2
