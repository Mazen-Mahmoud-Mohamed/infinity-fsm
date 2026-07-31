# Development & Operations Scripts

Utility scripts for development workflow.

## Status

**Planning phase** — scripts will be created during implementation phases.

## Planned Scripts

| Script | Purpose | Phase |
|--------|---------|-------|
| `seed-database.js` | Seed default company, admin user, departments | 1 |
| `reset-database.js` | Drop and re-seed (dev only) | 1 |
| `generate-test-data.js` | Generate sample overtime records | 2 |
| `verify-calculations.js` | Run overtime calculation test cases | 2 |
| `export-openapi.js` | Generate OpenAPI spec from routes | 4 |

## Usage (Future)

```bash
# Seed database with default data
node scripts/seed-database.js

# Generate test overtime records
node scripts/generate-test-data.js --count 50
```
