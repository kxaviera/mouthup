# MouthUp Admin Panel

Dark-themed admin dashboard for moderating MouthUp.

## Run

```bash
# Start API first (see mouthup-api/README.md)
cp .env.local.example .env.local
npm run dev
```

Open http://localhost:3001 (or the port Next.js assigns)

## Login

Use the admin account seeded by `mouthup-api` (set `ADMIN_EMAIL` / `ADMIN_PASSWORD` in the API `.env` before running `npx prisma db seed`):

- Email: value of `ADMIN_EMAIL` (default `admin@mouthup.app`)
- Password: value of `ADMIN_PASSWORD` (change the default before production deploy)

## Screens

| Screen | Purpose |
|--------|---------|
| Dashboard | User/post/report/message counts |
| Reports | Review and resolve flagged content |
| Users | Search, verify badges, ban users |
| Posts | Search, delete posts |

## Stack

- Next.js 15 + TypeScript + Tailwind
- Connects to NestJS admin API at `/api/v1/admin/*`
