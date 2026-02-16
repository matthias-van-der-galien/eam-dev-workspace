# EAM Dev Workspace

This repository is a unified workspace that hosts the EAM platform frontend and backend side-by-side. The goal is to let an AI agent (or a developer) edit both codebases in a single place, keeping changes coordinated across the stack.

## What is inside

- `frontend/` - Next.js web application (see [frontend/README.md](frontend/README.md)).
- `backend/` - NestJS API and worker services (see [backend/README.md](backend/README.md)).

## When to use this workspace

- You want to make a change that touches both UI and API.
- You want shared context (docs, tests, config) while editing in parallel.
- You are running the app locally with the frontend and backend together.

## Quick navigation

- Frontend docs: [frontend/README.md](frontend/README.md)
- Backend docs: [backend/README.md](backend/README.md)

## Local full-stack run (ports: backend 8000, frontend 3000)

Use the helper script to start everything at once (it will create local env files from the examples if missing):

```bash
chmod +x ./scripts/dev.sh
./scripts/dev.sh
```

### Backend

```bash
cd backend
cp .env.example .env
pnpm install
pnpm docker:up
pnpm db:migrate
pnpm dev:api
```

In another terminal:

```bash
cd backend
pnpm dev:worker
```

### Frontend

```bash
cd frontend
cp .env.local.example .env.local
npm install
npm run dev
```

Verify:

- API health: http://localhost:8000/health
- Frontend: http://localhost:3000