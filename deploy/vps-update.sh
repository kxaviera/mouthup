#!/usr/bin/env bash
# Update MouthUp admin + API on VPS (Docker Compose at /docker/mouthup).
# Run: bash deploy/vps-update.sh
set -euo pipefail

COMPOSE_DIR="${COMPOSE_DIR:-/docker/mouthup}"
REPO_DIR="${REPO_DIR:-/workspace/mouthup}"
BRANCH="${BRANCH:-main}"

cd "${COMPOSE_DIR}"

echo "==> Pulling latest code inside containers (${BRANCH})"

update_service() {
  local service="$1"
  local app_dir="$2"
  local build_cmd="$3"
  local start_cmd="$4"

  docker compose exec -T "${service}" bash -lc "
    set -e
    if [ ! -d '${REPO_DIR}/.git' ]; then
      echo 'ERROR: ${REPO_DIR} not found in ${service} container'
      exit 1
    fi
    cd '${REPO_DIR}'
    git fetch origin '${BRANCH}'
    # Discard container-local edits (e.g. npm install changing package-lock.json)
    git reset --hard 'origin/${BRANCH}'
    git clean -fd
    cd '${app_dir}'
    ${build_cmd}
  "
  docker compose restart "${service}"
  echo "==> ${service} restarted"
}

update_service api mouthup-api "npm ci && npx prisma generate && npm run build" "node dist/main"
update_service admin mouthup-admin "npm ci && npm run build" "npm start"

echo ""
echo "==> Done. Wait 30-60s, then verify:"
echo "    curl -s https://api.ogmario64.fun/api/v1/health"
echo "    Open https://admin.ogmario64.fun/posts (look for 'Live feed refreshes every 10 seconds')"
