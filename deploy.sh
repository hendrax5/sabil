#!/bin/bash
set -e

echo "========================================================"
echo " SALFANET RADIUS - DOCKER AUTOMATED DEPLOYMENT"
echo "========================================================"

# 1. Pastikan script bawaan memiliki permission execute
chmod +x init-docker.sh || true

# 2. Inisialisasi Environment jika belum ada (.env)
if [ ! -f ".env" ]; then
    echo -e "\n[1/4] Konfigurasi Awal (.env tidak ditemukan)..."
    read -p "Masukkan nama Domain Anda (contoh: radius.domain.com): " DOMAIN_INPUT
    read -p "Masukkan Email untuk SSL (contoh: admin@domain.com): " EMAIL_INPUT
    
    # Berikan fallback jika input kosong
    DOMAIN_INPUT=${DOMAIN_INPUT:-"localhost"}
    EMAIL_INPUT=${EMAIL_INPUT:-"admin@localhost"}

    ./init-docker.sh "$DOMAIN_INPUT" "$EMAIL_INPUT"
else
    echo -e "\n[1/4] File .env sudah ada, mempertahankan konfigurasi Anda yang sekarang..."
fi

# Mengambil variabel lokal untuk keperluan ping ke database
source .env

# 3. Build & Up Docker Containers
echo -e "\n[2/4] Membangun dan menyalakan container (bisa memakan waktu beberapa menit untuk Next.js)..."
docker compose build
docker compose up -d

# 4. Tunggu MariaDB Siap
echo -e "\n[3/4] Menunggu database MariaDB hidup dan siap menerima koneksi..."
until docker compose exec -T mariadb mysqladmin ping -u root -p"$MYSQL_ROOT_PASSWORD" --silent; do
    echo "Masih menunggu database..."
    sleep 3
done

# 5. Migrasi & Sinkronisasi Database (Idempotent - aman dijalankan berulang kali saat update)
echo -e "\n[4/4] Sinkronisasi, Migrasi, dan Seeding Database..."

echo " -> Mendorong skema tabel (Prisma v6)..."
docker compose exec -T app npx prisma@6.19.0 db push --accept-data-loss

echo " -> Menanamkan perbaikan pandangan (SQL views) FreeRADIUS..."
cat ./salfanet-radius/prisma/migrations/fix_radacct_groupname/migration.sql | docker compose exec -T mariadb mysql -u root -p"$MYSQL_ROOT_PASSWORD" "$MYSQL_DATABASE"

echo " -> Menanamkan seed dasar (Akun admin, dsb)..."
docker compose exec -T cron npx tsx prisma/seeds/seed-all.ts

echo "========================================================"
echo " DEPLOYMENT SELESAI DAN BERHASIL!"
echo " Aplikasi Anda dapat diakses di: https://$DOMAIN"
echo " (Untuk pertama kali, Traefik mungkin butuh ~1 menit untuk menerbitkan SSL Let's Encrypt)"
echo "========================================================"
