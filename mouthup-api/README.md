# MouthUp API

Production backend for the MouthUp anonymous social app.

## Stack

- **NestJS** — API framework
- **PostgreSQL** — primary database (indexed for feed at scale)
- **Prisma** — ORM + migrations
- **Redis** — caching, queues, realtime pub/sub (Phase 2)
- **JWT** — access + refresh tokens
- **Rate limiting** — `@nestjs/throttler`

## Quick start

```bash
# 1. Start database
docker compose up -d

# 2. Configure env
cp .env.example .env

# 3. Install & migrate
npm install
npx prisma migrate dev --name init
npx prisma db seed

# 4. Run API
npm run start:dev
```

API: `http://localhost:3000/api/v1`  
Health: `http://localhost:3000/api/v1/health`

## Default accounts (after seed)

| Role | Email | Password |
|------|-------|----------|
| Admin | admin@mouthup.app | admin123change |

## API modules

| Module | Endpoints |
|--------|-----------|
| Auth | register, login, verify, refresh, reset password |
| Users | profile, username, block/unblock |
| Posts | feed (cursor), create, edit, delete, save, trending |
| Comments | list, add, delete |
| Messages | conversations, DM thread, send |
| Notifications | list, mark read |
| Reports | report post/user/comment |
| Admin | dashboard, reports queue, ban, delete |

## Scale design

- **Cursor pagination** on feed (not offset) — stable under heavy load
- **Indexes** on `posts.created_at`, `posts.author_id`, `hashtag_stats.post_count`
- **Soft deletes** on posts/comments — safe admin recovery
- **Blocked user filter** at query level — not client-side
- **Per-user saves** — proper `saves` join table
- **Rate limiting** — 120 req/min in production

## Project structure

```
mouthup-api/
├── prisma/schema.prisma   # Database schema
├── docker-compose.yml     # Postgres + Redis
├── src/
│   ├── auth/
│   ├── users/
│   ├── posts/             # Feed + CRUD
│   ├── comments/
│   ├── messages/
│   ├── notifications/
│   ├── reports/
│   ├── admin/
│   └── moderation/
```

## Next steps

- [ ] S3 media upload (presigned URLs)
- [ ] WebSocket DMs (Socket.io + Redis adapter)
- [ ] Email queue (Resend via Bull)
- [ ] FCM push notifications
- [ ] Flutter app integration (`lib/services/api/`)
