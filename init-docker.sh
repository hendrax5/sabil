#!/bin/bash
# Initialize Docker configuration for Salfanet-Radius
set -e

ENV_FILE=".env"
if [ -f "$ENV_FILE" ]; then
    echo "File $ENV_FILE sudah ada. Melewati proses pembuatan..."
else
    echo "Membuat file konfigurasi $ENV_FILE baru..."
    
    # Generate secure random passwords
    MYSQL_ROOT_PASSWORD=$(openssl rand -hex 16)
    MYSQL_PASSWORD=$(openssl rand -hex 16)
    RADIUS_SECRET=$(openssl rand -hex 12)
    NEXTAUTH_SECRET=$(openssl rand -base64 32)
    
    DOMAIN=${1:-"yourdomain.com"}
    SSL_EMAIL=${2:-"admin@yourdomain.com"}

    cat > $ENV_FILE <<EOF
# ==========================================
# AUTO-GENERATED CONFIGURATION
# ==========================================

# Let's Encrypt / Certbot Configuration
DOMAIN=${DOMAIN}
SSL_EMAIL=${SSL_EMAIL}

# Database Credentials
MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}
MYSQL_DATABASE=radius
MYSQL_USER=radius
MYSQL_PASSWORD=${MYSQL_PASSWORD}

# Application Secrets
NEXTAUTH_SECRET=${NEXTAUTH_SECRET}
NEXTAUTH_URL=https://${DOMAIN}

# Application settings
NEXT_PUBLIC_APP_NAME="Radius Hotspot"
NEXT_PUBLIC_APP_URL=https://${DOMAIN}
TZ=Asia/Jakarta
NEXT_PUBLIC_TIMEZONE=Asia/Jakarta

# Local Services configured via Docker network
DATABASE_URL="mysql://radius:${MYSQL_PASSWORD}@mariadb:3306/radius?connection_limit=10&pool_timeout=20"
REDIS_URL="redis://redis:6379"

# API URL for Cron
API_URL=http://app:3000
EOF

    echo "Berhasil! Konfigurasi aman tekah dibuat. Silahkan edit $ENV_FILE jika ingin menyesuaikan domain, lalu jalankan:"
    echo "docker compose up -d"
fi
