# Infrastructure

Docker, CI/CD, and deployment configurations.

## Status

**Planning phase** — configurations will be created during Phase 1 and Phase 5.

## Planned Contents

| File/Directory | Purpose | Phase |
|----------------|---------|-------|
| `docker-compose.yml` | Local dev: API + MongoDB (+ Redis) | 1 |
| `docker-compose.prod.yml` | Production stack | 5 |
| `Dockerfile` | Backend container image | 1 |
| `nginx/` | Reverse proxy + TLS config | 5 |
| `.github/workflows/` | CI/CD pipelines | 1 |
| `mongodb/` | Seed scripts, init | 1 |

## Local Development (Future)

```bash
cd infra
docker-compose up -d
# MongoDB available at localhost:27017
# API available at localhost:3000
```
