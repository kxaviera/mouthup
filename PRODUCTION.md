# MouthUp — Production Monorepo

Three projects for production launch:

| Project | Path | Purpose |
|---------|------|---------|
| **Flutter App** | `mouthup_flutter/` | User-facing mobile/web app |
| **API** | `mouthup-api/` | NestJS backend (PostgreSQL + Redis) |
| **Admin** | `mouthup-admin/` | Moderation dashboard (Next.js) |

## Why this stack (scale-ready)

- **PostgreSQL** with indexed cursor pagination — feed stays fast at millions of posts
- **NestJS** modular API — auth, posts, DMs, reports separated cleanly
- **Redis** (Docker ready) — for caching, queues, WebSocket scaling (Phase 2)
- **Rate limiting** — 120 req/min per IP in production
- **Soft deletes** — admin can recover mistaken deletions
- **Per-user saves/blocks** — proper relational model, not mock flags

## Quick start (local)

### 1. Database
```bash
cd mouthup-api
docker compose up -d
cp .env.example .env
npm install
npx prisma migrate dev --name init
npx prisma db seed
npm run start:dev
```

### 2. Admin panel
```bash
cd mouthup-admin
cp .env.local.example .env.local
npm install
npm run dev
```

### 3. Flutter app (still on mock data until Phase 4)
```bash
cd mouthup_flutter
flutter run -d chrome --web-port=57400
```

## Default accounts

| Role | Email | Password |
|------|-------|----------|
| Admin | admin@mouthup.app | admin123change |
| Demo user | demo@mouthup.app | demo123 |

## Build order (remaining)

1. ✅ **Backend API** — auth, users, posts, comments, DMs, notifications, reports, admin
2. ✅ **Admin panel UI** — dashboard, reports, users, posts
3. ⏳ **Flutter integration** — replace `AppState` mocks with API repositories
4. ⏳ **Media upload** — S3 presigned URLs + video playback
5. ⏳ **Realtime** — WebSocket DMs + push notifications (FCM)
6. ⏳ **Deploy** — Railway/Render + Cloudflare R2 + production env

## API base URL

- Local: `http://localhost:3000/api/v1`
- Health: `GET /api/v1/health`

## Flutter integration (next session)

Add to `mouthup_flutter`:
- `dio` + `flutter_secure_storage`
- `lib/services/api/` client matching API routes
- `lib/repositories/` — swap AppState mock calls
- `--dart-define=API_URL=...` for dev/staging/prod flavors
