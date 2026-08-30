#!/usr/bin/env bash
# Fresh VPS deploy — wipe build caches, hard reset to origin/main, rebuild everything.
# Preserves mouthup-api/.env and mouthup-admin/.env.local.
#
# Run on VPS host:
#   cd /docker/mouthup && bash /workspace/mouthup/deploy/vps-fresh.sh
set -euo pipefail

COMPOSE_DIR="${COMPOSE_DIR:-/docker/mouthup}"
REPO_DIR="${REPO_DIR:-/workspace/mouthup}"
BRANCH="${BRANCH:-main}"

cd "${COMPOSE_DIR}"

fresh_service() {
  local service="$1"
  local app_dir="$2"
  local build_cmd="$3"

  echo ""
  echo "==> Fresh deploy: ${service}"
  docker compose exec -T "${service}" bash -lc "
    set -e
    if [ ! -d '${REPO_DIR}/.git' ]; then
      echo 'ERROR: ${REPO_DIR} not found in ${service} container'
      exit 1
    fi
    cd '${REPO_DIR}'

    # Backup env files before clean
    API_ENV=''
    ADMIN_ENV=''
    [ -f mouthup-api/.env ] && API_ENV=\$(cat mouthup-api/.env)
    [ -f mouthup-admin/.env.local ] && ADMIN_ENV=\$(cat mouthup-admin/.env.local)

    git fetch origin '${BRANCH}'
    git reset --hard 'origin/${BRANCH}'
    git clean -fd

    # Restore env
    [ -n \"\$API_ENV\" ] && printf '%s\n' \"\$API_ENV\" > mouthup-api/.env
    [ -n \"\$ADMIN_ENV\" ] && printf '%s\n' \"\$ADMIN_ENV\" > mouthup-admin/.env.local

    echo \"Commit: \$(git rev-parse --short HEAD) — \$(git log -1 --pretty=%s)\"

    cd '${app_dir}'
    rm -rf node_modules dist .next
    ${build_cmd}
  "
  docker compose restart "${service}"
  echo "==> ${service} restarted"
}

echo "==> MouthUp fresh deploy (${BRANCH})"
echo "    Compose: ${COMPOSE_DIR}"
echo "    Repo:    ${REPO_DIR}"

fresh_service api mouthup-api \
  "npm ci && npx prisma generate && npm run build && npx prisma db push && npm run db:seed"

fresh_service admin mouthup-admin \
  "npm ci && npm run build"

echo ""
echo "==> Fresh deploy complete"
echo "    Verify commit in containers:"
echo "      docker compose exec api git -C ${REPO_DIR} rev-parse --short HEAD"
echo "      docker compose exec admin git -C ${REPO_DIR} rev-parse --short HEAD"
echo ""
echo "    Health:"
echo "      curl -s https://api.ogmario64.fun/api/v1/health"
echo "    Admin (ISZI branding + live posts feed):"
echo "      https://admin.ogmario64.fun/posts"
