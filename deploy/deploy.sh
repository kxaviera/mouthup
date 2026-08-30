#!/usr/bin/env bash
# MouthUp production deploy — run on VPS from repo root (/var/www/mouthup)
set -euo pipefail

DOMAIN="${DOMAIN:-ogmario64.fun}"
APP_DIR="${APP_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
DB_PASSWORD="${DB_PASSWORD:-}"

echo "==> Deploying MouthUp to ${DOMAIN}"
echo "    App dir: ${APP_DIR}"
cd "${APP_DIR}"

# --- env files ---
if [[ ! -f mouthup-api/.env ]]; then
  echo "ERROR: mouthup-api/.env missing. Copy deploy/env/api.env.example and fill in secrets."
  exit 1
fi

if [[ ! -f mouthup-admin/.env.local ]]; then
  cat > mouthup-admin/.env.local <<EOF
NEXT_PUBLIC_API_URL=https://api.${DOMAIN}/api/v1
EOF
  echo "Created mouthup-admin/.env.local"
fi

# --- deps & build ---
echo "==> API: install & build"
cd mouthup-api
npm ci
npx prisma generate
npm run build
mkdir -p logs uploads
cd "${APP_DIR}"

echo "==> Admin: install & build"
cd mouthup-admin
npm ci
npm run build
mkdir -p ../logs
cd "${APP_DIR}"

# --- database ---
echo "==> Database: push schema & seed"
cd mouthup-api
npx prisma db push --accept-data-loss
npm run db:seed
cd "${APP_DIR}"

# --- PM2 ---
echo "==> PM2 restart"
mkdir -p logs
if pm2 describe mouthup-api >/dev/null 2>&1; then
  pm2 reload deploy/ecosystem.config.js --update-env
else
  pm2 start deploy/ecosystem.config.js
fi
pm2 save

# --- Flutter web (optional) ---
if command -v flutter >/dev/null 2>&1; then
  echo "==> Flutter web build"
  cd mouthup_flutter
  flutter pub get
  flutter build web --release --dart-define=API_URL="https://api.${DOMAIN}/api/v1"
  sudo mkdir -p /var/www/mouthup-web
  sudo rsync -a --delete build/web/ /var/www/mouthup-web/
  cd "${APP_DIR}"
fi

# --- nginx ---
if [[ -f /etc/nginx/sites-available/mouthup.conf ]]; then
  echo "==> Nginx reload"
  sudo nginx -t && sudo systemctl reload nginx
else
  echo "NOTE: Install nginx config first:"
  echo "  sudo cp deploy/nginx/mouthup.conf /etc/nginx/sites-available/mouthup.conf"
  echo "  sudo sed -i 's/DOMAIN/${DOMAIN}/g' /etc/nginx/sites-available/mouthup.conf"
  echo "  sudo ln -sf /etc/nginx/sites-available/mouthup.conf /etc/nginx/sites-enabled/"
  echo "  sudo certbot --nginx -d api.${DOMAIN} -d admin.${DOMAIN} -d app.${DOMAIN}"
fi

echo ""
echo "==> Deploy complete"
echo "    API:   https://api.${DOMAIN}/api/v1/health"
echo "    Admin: https://admin.${DOMAIN}"
echo "    App:   https://app.${DOMAIN}"
pm2 status
