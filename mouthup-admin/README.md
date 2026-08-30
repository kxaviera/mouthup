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

Use the seeded admin account from `mouthup-api`:

- Email: `admin@mouthup.app`
- Password: `admin123change`

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
