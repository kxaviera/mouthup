#!/usr/bin/env bash
# Wire Traefik (Docker) to PM2 apps on the host via nginx proxy containers.
# Run on VPS: cd /var/www/mouthup && bash deploy/vps-traefik-routes.sh
set -euo pipefail

DOMAIN="${DOMAIN:-ogmario64.fun}"
APP_DIR="${APP_DIR:-/var/www/mouthup}"
PROXY_DIR="${APP_DIR}/deploy/traefik"

cd "${APP_DIR}"

if ! ss -tlnp 2>/dev/null | grep -q traefik; then
  echo "ERROR: Traefik is not listening on 80/443."
  exit 1
fi

TRAEFIK_CONTAINER=$(docker ps --format '{{.Names}}' | grep -i traefik | head -1 || true)
if [[ -z "${TRAEFIK_CONTAINER}" ]]; then
  echo "ERROR: No Traefik container running."
  exit 1
fi

TRAEFIK_NETWORK=$(docker inspect "${TRAEFIK_CONTAINER}" --format '{{range $name, $_ := .NetworkSettings.Networks}}{{$name}} {{end}}' | tr ' ' '\n' | grep -i traefik | head -1 || true)
if [[ -z "${TRAEFIK_NETWORK}" ]]; then
  TRAEFIK_NETWORK=$(docker inspect "${TRAEFIK_CONTAINER}" --format '{{range $name, $_ := .NetworkSettings.Networks}}{{$name}} {{end}}' | awk '{print $1}')
fi
echo "Traefik container: ${TRAEFIK_CONTAINER}"
echo "Traefik network:   ${TRAEFIK_NETWORK}"

echo "==> Remove old MouthUp Docker api/admin (stale Traefik backends)"
if [[ -d /docker/mouthup ]]; then
  cd /docker/mouthup
  docker compose stop api admin 2>/dev/null || true
  docker compose rm -f api admin 2>/dev/null || true
  cd "${APP_DIR}"
fi

echo "==> Static placeholder for app.${DOMAIN}"
mkdir -p /var/www/mouthup-web
if [[ ! -f /var/www/mouthup-web/index.html ]]; then
  echo '<!DOCTYPE html><html><body><h1>ISZI</h1><p>Flutter web build pending.</p></body></html>' \
    > /var/www/mouthup-web/index.html
fi

if ! ss -tlnp | grep -q ':8080'; then
  if command -v python3 >/dev/null 2>&1; then
    nohup python3 -m http.server 8080 --directory /var/www/mouthup-web >/var/log/mouthup-web.log 2>&1 &
    echo "Started static file server on :8080"
  fi
fi

echo "==> Start nginx proxy containers (Traefik Docker provider)"
WORK="${PROXY_DIR}/.runtime"
mkdir -p "${WORK}"
cp "${PROXY_DIR}/nginx-api.conf" "${PROXY_DIR}/nginx-admin.conf" "${PROXY_DIR}/nginx-app.conf" "${WORK}/"
sed "s/DOMAIN/${DOMAIN}/g; s/TRAEFIK_NETWORK/${TRAEFIK_NETWORK}/g" \
  "${PROXY_DIR}/pm2-proxy-compose.yml" > "${WORK}/docker-compose.yml"
cd "${WORK}"
docker compose pull
docker compose up -d --force-recreate

echo ""
echo "==> Test PM2 from proxy container"
docker compose exec -T mouthup-api-proxy wget -qO- http://host.docker.internal:3000/api/v1/health \
  && echo "  proxy -> PM2 API: ok" || echo "  proxy -> PM2 API: FAIL"

echo ""
echo "==> Verify PM2"
pm2 status || true
curl -sf "http://127.0.0.1:3000/api/v1/health" && echo "  local API: ok" || echo "  local API: FAIL"
curl -sf -o /dev/null "http://127.0.0.1:3001/login" && echo "  local admin: ok" || echo "  local admin: FAIL"

sleep 5
echo ""
echo "==> Public checks"
curl -sk "https://api.${DOMAIN}/api/v1/health" && echo "" && echo "  public API: ok" || echo "  public API: FAIL"
curl -sk -o /dev/null -w "  public admin HTTP %{http_code}\n" "https://admin.${DOMAIN}/login"

if ! curl -sk "https://api.${DOMAIN}/api/v1/health" | grep -q '"status":"ok"'; then
  echo ""
  echo "DEBUG — Traefik logs:"
  docker logs "${TRAEFIK_CONTAINER}" --tail 20 2>&1 || true
  echo "DEBUG — proxy containers:"
  docker compose ps
fi

echo ""
echo "  Admin: https://admin.${DOMAIN}/login"
echo "  API:   https://api.${DOMAIN}/api/v1/health"
