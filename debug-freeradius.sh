#!/bin/bash
echo "=========================================================="
echo "      FreeRADIUS Debugger / Logging Interceptor"
echo "=========================================================="
echo ">>> Menghentikan container freeradius yang crash-looping..."
docker compose stop freeradius 2>/dev/null
docker compose rm -f freeradius 2>/dev/null

echo ""
echo ">>> Mencetak LOG terakhir jika ada (sebelum dhapus):"
docker logs freeradius --tail 50 2>/dev/null
echo ""
echo ">>> Menjalankan mode Deteksi Error Ekstrem (Foreground Debugging)..."
echo ">>> (Silakan copy-paste teks merah terbawah yang muncul setelah ini!)"
echo ""

# Menjalankan freeradius dalam container Ubuntu yang kita buat dengan Extreme Debug mode (-X)
docker compose run --rm freeradius freeradius -X
