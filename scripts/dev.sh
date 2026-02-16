#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if ! command -v pnpm >/dev/null 2>&1; then
  echo "pnpm is required but not found. Install pnpm and try again." >&2
  exit 1
fi

if ! command -v npm >/dev/null 2>&1; then
  echo "npm is required but not found. Install Node.js and try again." >&2
  exit 1
fi

if ! command -v docker >/dev/null 2>&1; then
  echo "docker is required but not found. Install Docker and try again." >&2
  exit 1
fi

if ! command -v ssh-keygen >/dev/null 2>&1; then
  echo "ssh-keygen is required but not found. Install OpenSSH and try again." >&2
  exit 1
fi

if ! command -v openssl >/dev/null 2>&1; then
  echo "openssl is required but not found. Install OpenSSL and try again." >&2
  exit 1
fi

if [[ ! -f "$ROOT_DIR/backend/.env" ]]; then
  if [[ -f "$ROOT_DIR/backend/.env.example" ]]; then
    echo "Backend .env not found. Creating from .env.example."
    cp "$ROOT_DIR/backend/.env.example" "$ROOT_DIR/backend/.env"
  else
    echo "Backend .env not found and .env.example is missing." >&2
    exit 1
  fi
fi

if [[ ! -f "$ROOT_DIR/frontend/.env.local" ]]; then
  if [[ -f "$ROOT_DIR/frontend/.env.local.example" ]]; then
    echo "Frontend .env.local not found. Creating from .env.local.example."
    cp "$ROOT_DIR/frontend/.env.local.example" "$ROOT_DIR/frontend/.env.local"
  else
    echo "Frontend .env.local not found and .env.local.example is missing." >&2
    exit 1
  fi
fi

if [[ ! -d "$ROOT_DIR/backend/node_modules" ]]; then
  echo "Installing backend dependencies..."
  (
    cd "$ROOT_DIR/backend"
    pnpm install
  )
fi

if [[ ! -d "$ROOT_DIR/frontend/node_modules" ]]; then
  echo "Installing frontend dependencies..."
  (
    cd "$ROOT_DIR/frontend"
    npm install
  )
fi

if [[ ! -f "$ROOT_DIR/backend/keys/jwt.private.pem" || ! -f "$ROOT_DIR/backend/keys/jwt.public.pem" ]]; then
  echo "Generating backend JWT keys..."
  (
    cd "$ROOT_DIR/backend"
    mkdir -p keys
    ssh-keygen -t rsa -b 4096 -m PEM -f keys/jwt.private.pem -N ""
    openssl rsa -in keys/jwt.private.pem -pubout -outform PEM -out keys/jwt.public.pem
  )
fi

echo "Starting backend dependencies (Postgres/Redis)..."
(
  cd "$ROOT_DIR/backend"
  pnpm docker:up
)

echo "Running database migrations..."
(
  cd "$ROOT_DIR/backend"
  pnpm db:migrate
)

cleanup() {
  echo "Shutting down dev processes..."
  jobs -p | xargs -r kill
}
trap cleanup INT TERM

echo "Starting backend API and worker..."
(
  cd "$ROOT_DIR/backend"
  pnpm dev:api
) &
API_PID=$!

(
  cd "$ROOT_DIR/backend"
  pnpm dev:worker
) &
WORKER_PID=$!

echo "Starting frontend dev server..."
(
  cd "$ROOT_DIR/frontend"
  npm run dev
) &
FRONTEND_PID=$!

echo "All services started. Press Ctrl+C to stop."
wait "$API_PID" "$WORKER_PID" "$FRONTEND_PID"
