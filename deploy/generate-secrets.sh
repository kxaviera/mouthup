#!/usr/bin/env bash
# Print secrets to paste into mouthup-api/.env
echo "JWT_ACCESS_SECRET=$(openssl rand -base64 48)"
echo "JWT_REFRESH_SECRET=$(openssl rand -base64 48)"
echo "ADMIN_PASSWORD=$(openssl rand -base64 24 | tr -d '/+=' | head -c 20)"
