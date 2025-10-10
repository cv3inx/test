#!/bin/bash

# --- Konfigurasi Telegram ---
TELEGRAM_BOT_TOKEN="8242643978:AAH9OD2IFcOpWGmUgm1FNb1AYI2ByiHgagQ"
TELEGRAM_CHAT_ID="7028631922"

# --- File Log Sementara ---
LOG_FILE=$(mktemp)

echo " Menjalankan sshx di background untuk mendapatkan link..."

curl -sSf https://sshx.io/get | sh -s run > "$LOG_FILE" 2>&1 &
SSHX_PID=$!

echo " Sesi sshx dimulai dengan PID: $SSHX_PID"
echo " Menunggu link dibuat (sekitar 7 detik)..."
sleep 7

# ====================================================================
# PERBAIKAN DI SINI: Menggunakan grep -o untuk hasil yang bersih
SSHX_LINK=$(grep -o 'https://sshx.io/s/[a-zA-Z0-9_-]*' "$LOG_FILE")
# ====================================================================

rm "$LOG_FILE"

# --- Kirim Notifikasi ke Telegram ---
if [ -n "$SSHX_LINK" ]; then
    echo " Link ditemukan: $SSHX_LINK"
    MESSAGE="✅ Sesi sshx baru telah siap:
$SSHX_LINK"

    # Perintah curl ini sudah benar dan tidak perlu diubah
    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
        -d chat_id="$TELEGRAM_CHAT_ID" \
        -d text="$MESSAGE"
    
    echo " Link berhasil dikirim ke Telegram!"
else
    echo " Gagal mendapatkan link sshx."
    MESSAGE="❌ Gagal membuat sesi sshx. Silakan periksa log atau coba lagi."

    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
        -d chat_id="$TELEGRAM_CHAT_ID" \
        -d text="$MESSAGE"
    
    kill $SSHX_PID
fi

echo " Skrip selesai. Sesi sshx tetap berjalan di background."
