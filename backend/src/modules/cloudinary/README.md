# Cloudinary Module

Image upload management via Cloudinary.

## Endpoints

| Method | Path | Access |
|--------|------|--------|
| POST | `/api/v1/cloudinary/sign-upload` | Authenticated |
| POST | `/api/v1/cloudinary/verify` | Authenticated |

## Upload Flow

1. Client requests signed upload URL from backend
2. Client uploads photo directly to Cloudinary
3. Client sends Cloudinary URL in overtime start/end request
4. Backend stores URL in MongoDB (never stores binary)

## Folders

- `overtime/start/` — Start photos
- `overtime/end/` — End photos
- `avatars/` — User avatars

**Implementation:** Phase 2
