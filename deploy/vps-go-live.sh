#!/usr/bin/env bash
# ISZI / MouthUp — go live on VPS (PM2 on host + Postgres in Docker).
# Run from repo root on the server:
#   cd /var/www/mouthup && bash deploy/vps-go-live.sh
set -euo pipefail

DOMAIN="${DOMAIN:-ogmario64.fun}"
APP_DIR="${APP_DIR:-/var/www/mouthup}"
WEB_ROOT="${WEB_ROOT:-/var/www/mouthup-web}"

cd "${APP_DIR}"

echo "==> ISZI go-live (${DOMAIN})"
echo "    App dir: ${APP_DIR}"

# --- prerequisites ---
for cmd in node npm pm2 nginx certbot; do
  if ! command -v "${cmd}" >/dev/null 2>&1; then
    echo "ERROR: ${cmd} not found. Run: DOMAIN=${DOMAIN} bash deploy/setup-vps.sh"
    exit 1
  fi
done

if [[ ! -f mouthup-api/.env ]]; then
  echo "ERROR: mouthup-api/.env missing. Copy deploy/env/api.env.example and fill secrets."
  exit 1
fi

# --- admin env (baked into Next build) ---
if [[ ! -f mouthup-admin/.env.local ]]; then
  cp deploy/env/admin.env.example mouthup-admin/.env.local
  sed -i "s/ogmario64.fun/${DOMAIN}/g" mouthup-admin/.env.local
  echo "Created mouthup-admin/.env.local"
fi

# --- build API + admin ---
echo "==> API: install & build"
cd mouthup-api
npm ci
npx prisma generate
npm run build
npx prisma db push
npm run db:seed
mkdir -p logs uploads
cd "${APP_DIR}"

echo "==> Admin: install & build"
cd mouthup-admin
npm ci
npm run build
mkdir -p ../logs
cd "${APP_DIR}"

# --- PM2 ---
echo "==> PM2"
mkdir -p logs
pm2 delete mouthup-api mouthup-admin 2>/dev/null || true
pm2 start deploy/ecosystem.config.js
pm2 save
pm2 startup systemd -u root --hp /root 2>/dev/null | tail -1 | bash || true

# --- nginx ---
echo "==> Nginx"
if ss -tlnp 2>/dev/null | grep -qE ':80 .*traefik|:443 .*traefik'; then
  echo "WARNING: Traefik is listening on 80/443. Stop Traefik or configure it to proxy"
  echo "         api.${DOMAIN} -> 127.0.0.1:3000, admin.${DOMAIN} -> 127.0.0.1:3001"
  echo "         Skipping nginx install."
else
  sudo cp deploy/nginx/mouthup.conf /etc/nginx/sites-available/mouthup.conf
  sudo sed -i "s/DOMAIN/${DOMAIN}/g" /etc/nginx/sites-available/mouthup.conf
  sudo ln -sf /etc/nginx/sites-available/mouthup.conf /etc/nginx/sites-enabled/mouthup.conf
  sudo rm -f /etc/nginx/sites-enabled/default
  sudo nginx -t
  sudo systemctl reload nginx

  if [[ ! -d /etc/letsencrypt/live/api.${DOMAIN} ]]; then
    echo "==> SSL (Let's Encrypt)"
    sudo certbot --nginx -d "api.${DOMAIN}" -d "admin.${DOMAIN}" -d "app.${DOMAIN}" \
      --non-interactive --agree-tos -m "admin@${DOMAIN}" || {
      echo "Certbot failed — ensure DNS A records point to this server, then run:"
      echo "  sudo certbot --nginx -d api.${DOMAIN} -d admin.${DOMAIN} -d app.${DOMAIN}"
    }
  fi
fi

# --- Flutter web (static) ---
sudo mkdir -p "${WEB_ROOT}"
if [[ -d mouthup_flutter/build/web ]]; then
  echo "==> Deploying Flutter web from mouthup_flutter/build/web"
  sudo rsync -a --delete mouthup_flutter/build/web/ "${WEB_ROOT}/"
else
  echo "NOTE: Flutter web not built on server."
  echo "      Build on your PC, then upload:"
  echo "        cd mouthup_flutter && flutter build web --release"
  echo "        rsync -avz build/web/ root@YOUR_VPS:${WEB_ROOT}/"
fi

echo ""
echo "==> Go-live checks"
curl -sf "http://127.0.0.1:3000/api/v1/health" && echo "  local API: ok" || echo "  local API: FAIL"
curl -sf "http://127.0.0.1:3001" >/dev/null && echo "  local admin: ok" || echo "  local admin: FAIL"
curl -sf "https://api.${DOMAIN}/api/v1/health" && echo "  public API: ok" || echo "  public API: FAIL (DNS/SSL/nginx)"
echo ""
echo "  API:   https://api.${DOMAIN}/api/v1/health"
echo "  Admin: https://admin.${DOMAIN}"
echo "  App:   https://app.${DOMAIN}"
pm2 status
