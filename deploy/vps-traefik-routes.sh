#!/usr/bin/env bash
# Wire Traefik (Docker) to PM2 apps on the host.
# Run on VPS: cd /var/www/mouthup && bash deploy/vps-traefik-routes.sh
set -euo pipefail

DOMAIN="${DOMAIN:-ogmario64.fun}"
APP_DIR="${APP_DIR:-/var/www/mouthup}"
TRAEFIK_DIR="${TRAEFIK_DIR:-/docker/traefik}"
HOST_GATEWAY="${HOST_GATEWAY:-172.17.0.1}"

cd "${APP_DIR}"

if ! ss -tlnp 2>/dev/null | grep -q traefik; then
  echo "ERROR: Traefik is not listening on 80/443."
  exit 1
fi

echo "==> Stop old MouthUp Docker api/admin (Traefik was routing to these)"
if [[ -d /docker/mouthup ]]; then
  cd /docker/mouthup
  docker compose stop api admin 2>/dev/null || true
  cd "${APP_DIR}"
fi

echo "==> Install Traefik dynamic routes for PM2"
mkdir -p "${TRAEFIK_DIR}/dynamic"
sed "s/172.17.0.1/${HOST_GATEWAY}/g; s/ogmario64.fun/${DOMAIN}/g" \
  deploy/traefik/mouthup.yml > "${TRAEFIK_DIR}/dynamic/mouthup.yml"

# Simple static file server for Flutter web (optional)
if [[ ! -d /var/www/mouthup-web ]] || [[ -z "$(ls -A /var/www/mouthup-web 2>/dev/null)" ]]; then
  echo "NOTE: /var/www/mouthup-web is empty — app.ogmario64.fun will 502 until Flutter web is uploaded."
  mkdir -p /var/www/mouthup-web
  echo '<!DOCTYPE html><html><body><h1>ISZI</h1><p>Flutter web build pending.</p></body></html>' \
    > /var/www/mouthup-web/index.html
fi

if ! docker ps --format '{{.Names}}' | grep -qi traefik; then
  echo "WARNING: No traefik container found. Copy ${TRAEFIK_DIR}/dynamic/mouthup.yml manually."
else
  TRAEFIK_CONTAINER=$(docker ps --format '{{.Names}}' | grep -i traefik | head -1)
  echo "==> Restart ${TRAEFIK_CONTAINER}"
  docker restart "${TRAEFIK_CONTAINER}"
fi

# Serve Flutter static files on host :8080 via Python (lightweight)
if ! ss -tlnp | grep -q ':8080'; then
  if command -v python3 >/dev/null 2>&1; then
    nohup python3 -m http.server 8080 --directory /var/www/mouthup-web >/var/log/mouthup-web.log 2>&1 &
    echo "Started static file server on :8080 for app.${DOMAIN}"
  fi
fi

echo ""
echo "==> Verify PM2 is running"
pm2 status || true
curl -sf "http://127.0.0.1:3000/api/v1/health" && echo "  local API: ok" || echo "  local API: FAIL"
curl -sf -o /dev/null "http://127.0.0.1:3001/login" && echo "  local admin: ok" || echo "  local admin: FAIL"

sleep 3
echo ""
echo "==> Public checks"
curl -sf "https://api.${DOMAIN}/api/v1/health" && echo "  public API: ok" || echo "  public API: FAIL"
curl -sf -o /dev/null -w "  public admin HTTP %{http_code}\n" "https://admin.${DOMAIN}/login"

echo ""
echo "  Admin: https://admin.${DOMAIN}/login"
echo "  API:   https://api.${DOMAIN}/api/v1/health"
