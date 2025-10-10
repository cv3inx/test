#!/bin/bash

# ==============================================================================
# Script untuk membuat link sshx dan mengirimkannya ke Telegram
# ==============================================================================

# --- Konfigurasi Telegram ---
# Ganti dengan token bot dan ID chat Anda jika perlu
TELEGRAM_BOT_TOKEN="8242643978:AAH9OD2IFcOpWGmUgm1FNb1AYI2ByiHgagQ"
TELEGRAM_CHAT_ID="7028631922"

# --- File Log Sementara ---
# Membuat file sementara yang aman untuk menyimpan output sshx
LOG_FILE=$(mktemp)

# --- Proses Utama ---
echo " Menjalankan sshx di background untuk mendapatkan link..."

# 1. Jalankan perintah sshx di background (&).
#    Output (stdout & stderr) akan dialihkan ke file log.
curl -sSf https://sshx.io/get | sh -s run > "$LOG_FILE" 2>&1 &

# 2. Simpan Process ID (PID) dari proses sshx yang baru saja dijalankan.
#    Ini berguna jika Anda ingin menghentikan sesi nanti.
SSHX_PID=$!
echo " Sesi sshx dimulai dengan PID: $SSHX_PID"
echo " (Anda bisa menghentikannya nanti dengan perintah 'kill $SSHX_PID')"

# 3. Tunggu beberapa detik agar sshx selesai inisialisasi dan mencetak link.
echo " Menunggu link dibuat (sekitar 5-7 detik)..."
sleep 7

# 4. Cari baris yang berisi link di dalam file log menggunakan 'grep'.
#    Filter ini akan mengambil teks lengkap dari baris yang cocok.
SSHX_LINK=$(grep 'https://sshx.io/s/' "$LOG_FILE")

# 5. Hapus file log sementara karena sudah tidak diperlukan lagi.
rm "$LOG_FILE"

# --- Kirim Notifikasi ke Telegram ---
if [ -n "$SSHX_LINK" ]; then
    # Jika link berhasil ditemukan
    echo " Link ditemukan: $SSHX_LINK"
    MESSAGE="✅ Sesi sshx baru telah siap:
$SSHX_LINK"

    # Kirim notifikasi sukses ke Telegram
    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
        -d chat_id="$TELEGRAM_CHAT_ID" \
        -d text="$MESSAGE"
    
    echo " Link berhasil dikirim ke Telegram!"
else
    # Jika link tidak ditemukan setelah menunggu
    echo " Gagal mendapatkan link sshx."
    MESSAGE="❌ Gagal membuat sesi sshx. Silakan periksa log atau coba lagi."

    # Kirim notifikasi error ke Telegram
    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
        -d chat_id="$TELEGRAM_CHAT_ID" \
        -d text="$MESSAGE"
    
    # Hentikan proses sshx yang gagal
    kill $SSHX_PID
fi

echo " Skrip selesai. Sesi sshx tetap berjalan di background."
