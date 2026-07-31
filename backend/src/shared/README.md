# Shared Utilities

Cross-cutting concerns used by all modules.

## Subdirectories

| Directory | Purpose |
|-----------|---------|
| `middleware/` | Auth, RBAC, validation, idempotency, error handler, request ID |
| `errors/` | Custom error classes (AppError, ValidationError, etc.) |
| `utils/` | Date/time helpers, pagination, response formatter |
| `constants/` | Enums, status codes, role definitions |

## Key Middleware (Planned)

- `authenticate.js` — JWT verification
- `authorize.js` — RBAC role/permission check
- `validate.js` — Joi schema validation wrapper
- `idempotency.js` — X-Idempotency-Key deduplication
- `errorHandler.js` — Global error handler
- `requestId.js` — X-Request-Id correlation
- `rateLimiter.js` — express-rate-limit config
