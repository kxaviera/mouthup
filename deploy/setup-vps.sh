#!/usr/bin/env bash
# First-time VPS setup for Ubuntu 24.04
set -euo pipefail

DOMAIN="${DOMAIN:-mouthup.app}"
APP_DIR="${APP_DIR:-/var/www/mouthup}"

echo "==> MouthUp VPS setup (${DOMAIN})"

# Node 20 LTS
if ! command -v node >/dev/null 2>&1; then
  curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
  sudo apt-get install -y nodejs
fi

# PM2
if ! command -v pm2 >/dev/null 2>&1; then
  sudo npm install -g pm2
  pm2 startup systemd -u "$USER" --hp "$HOME" | tail -1 | bash || true
fi

# Nginx + certbot
sudo apt-get update
sudo apt-get install -y nginx certbot python3-certbot-nginx rsync

# App directory
sudo mkdir -p "${APP_DIR}" /var/www/mouthup-web
sudo chown -R "$USER:$USER" "${APP_DIR}" /var/www/mouthup-web

# Firewall (keep CyberPanel ports if used)
if command -v ufw >/dev/null 2>&1; then
  sudo ufw allow OpenSSH
  sudo ufw allow 80/tcp
  sudo ufw allow 443/tcp
  sudo ufw --force enable || true
fi

# Nginx site
if [[ -d "${APP_DIR}/deploy/nginx" ]]; then
  sudo cp "${APP_DIR}/deploy/nginx/mouthup.conf" /etc/nginx/sites-available/mouthup.conf
  sudo sed -i "s/DOMAIN/${DOMAIN}/g" /etc/nginx/sites-available/mouthup.conf
  sudo ln -sf /etc/nginx/sites-available/mouthup.conf /etc/nginx/sites-enabled/mouthup.conf
  sudo rm -f /etc/nginx/sites-enabled/default
  sudo nginx -t && sudo systemctl reload nginx
fi

echo ""
echo "==> Next steps:"
echo "1. Clone/copy repo to ${APP_DIR}"
echo "2. cp deploy/env/api.env.example ${APP_DIR}/mouthup-api/.env  # fill secrets"
echo "3. Point DNS: api.${DOMAIN} admin.${DOMAIN} app.${DOMAIN} -> this server IP"
echo "4. sudo certbot --nginx -d api.${DOMAIN} -d admin.${DOMAIN} -d app.${DOMAIN}"
echo "5. cd ${APP_DIR} && bash deploy/deploy.sh"
