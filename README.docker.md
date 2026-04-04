# Docker Deployment Guide for Salfanet-Radius

Proyek ini sekarang mendukung deployment modern menggunakan **Docker** dan **Docker Compose**. Ini secara otomatis menggantikan script bash yang sebelumnya digunakan dan mengisolasi semua layanan dengan rapi.

## Keunggulan Versi Docker
1. **Otomatisasi SSL**: Traefik secara otomatis me-request sertifikat SSL/TLS (HTTPS) dari Let's Encrypt (tanpa perlu Certbot manual).
2. **Isolasi Layanan**: MariaDB, Redis, FreeRADIUS, Cron, dan App dipisahkan dalam container masing-masing.
3. **Keamanan Maksimal**: Script inisialisasi akan men-generate password acak untuk MariaDB & secrets (`openssl rand`).
4. **Optimasi**: Next.js disetel ke mode `standalone` yang ukurannya sangat minimalis.

## Langkah Deployment

### 1. Inisialisasi Konfigurasi (.env)
Gunakan script `init-docker.sh` untuk men-generate semua kredensial rahasia secara otomatis.
Jalankan di root folder proyek:

```bash
./init-docker.sh [DOMAIN_ANDA] [EMAIL_ANDA]
# Contoh:
# ./init-docker.sh radius.kisp.id admin@kisp.id
```

Ini akan menghasilkan file `.env` yang lengkap. Anda bisa mengecek isinya dengan `cat .env` jika ingin melihat password yang diterapkan.

### 2. Mulai Container
Jalankan Docker Compose untuk mulai membangun dan menjalankan layanan:

```bash
docker compose build
docker compose up -d
```
*Proses build pertama ini akan memakan beberapa menit untuk men-compile Next.js (Turbo/Standalone).*

### 3. Migrasi Database (Pertama Kali)
Setelah layanan berjalan, database MariaDB masih kosong. Lakukan migrasi dengan menentukan versi Prisma 6 secara spesifik (karena versi 7 memiliki struktur file config yang berbeda):

```bash
docker compose exec -T app npx prisma@6.19.0 db push --accept-data-loss

# Jalankan skrip fix RADIUS (injeksi SQL langsung ke container mariadb)
source .env
cat ./salfanet-radius/prisma/migrations/fix_radacct_groupname/migration.sql | docker compose exec -T mariadb mysql -u root -p"$MYSQL_ROOT_PASSWORD" "$MYSQL_DATABASE"

# Terakhir, masukkan data template dasar dan akun superadmin dari layanan cron (yang memiliki semua cache module lokal)
docker compose exec -T cron npx tsx prisma/seeds/seed-all.ts
```

### 4. Selesai
Sistem siap diakses di domain Anda (misal `https://radius.kisp.id`).
Traefik secara otomatis meneruskan trafffic SSL.

## Arsitektur Container
- **traefik**: Reverse proxy modern (port 80 & 443).
- **mariadb**: Database di port internal 3306.
- **redis**: Cache di port internal 6379.
- **freeradius**: FreeRADIUS Server (menggunakan port luar UDP 1812, 1813, 3799).
- **salfanet-app**: Dashboard & API Next.js.
- **salfanet-cron**: Service khusus background worker.

## Manajemen Service
- **Melihat Log App**: `docker compose logs -f app`
- **Melihat Log Cron**: `docker compose logs -f cron`
- **Melihat Log FreeRADIUS**: `docker compose logs -f freeradius`
- **Restart Aplikasi**: `docker compose restart app cron`
- **Berhenti**: `docker compose down`
