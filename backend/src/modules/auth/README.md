# Authentication Module

Handles user authentication and token management.

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| POST | `/api/v1/auth/login` | Login with email/password |
| POST | `/api/v1/auth/refresh` | Refresh access token |
| POST | `/api/v1/auth/logout` | Revoke refresh token |
| GET | `/api/v1/auth/me` | Current user profile |

## Files (Planned)

- `auth.routes.js`
- `auth.controller.js`
- `auth.service.js`
- `auth.repository.js` (refresh tokens)
- `auth.validator.js`
- `auth.dto.js`

## Security

- Passwords hashed with bcrypt (cost 12)
- Access token: 15 min expiry
- Refresh token: 7 days, rotated on use, stored hashed
- Device binding on refresh tokens

**Implementation:** Phase 1
