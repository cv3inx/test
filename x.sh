#!/bin/bash

# ==============================================================================
# Script untuk membuat link sshx, mengirimkannya ke Telegram,
# dan menjaga sesi tetap aktif sampai dihentikan manual (Ctrl+C).
# ==============================================================================

# --- Konfigurasi Telegram ---
TELEGRAM_BOT_TOKEN="8242643978:AAH9OD2IFcOpWGmUgm1FNb1AYI2ByiHgagQ"
TELEGRAM_CHAT_ID="7277939579"

# --- Variabel Global ---
SSHX_PID=
LOG_FILE=$(mktemp)

# --- Fungsi Cleanup ---
# Fungsi ini akan otomatis dipanggil saat skrip dihentikan (misalnya dengan Ctrl+C).
# Tujuannya adalah untuk memastikan proses sshx juga ikut berhenti.
cleanup() {
    echo -e "\n Menerima sinyal untuk berhenti..."
    if [ ! -z "$SSHX_PID" ]; then
        echo " Menghentikan proses sshx (PID: $SSHX_PID)..."
        # Mengirim sinyal TERM ke proses sshx
        kill $SSHX_PID
    fi
    # Menghapus file log sementara
    rm -f "$LOG_FILE"
    echo " Sesi sshx telah dihentikan. Selamat tinggal!"
    exit 0
}

# --- Menyiapkan 'trap' ---
# 'trap' akan "menangkap" sinyal keluar seperti SIGINT (dari Ctrl+C) atau SIGTERM
# dan menjalankan fungsi 'cleanup' sebelum skrip benar-benar berhenti.
trap cleanup SIGINT SIGTERM EXIT

# --- Proses Utama ---
echo " Menjalankan sshx untuk mendapatkan link..."

# 1. Jalankan sshx di background agar kita bisa mendapatkan PID-nya
#    dan melanjutkan eksekusi skrip untuk mengirim notifikasi.
curl -sSf https://sshx.io/get | sh -s run > "$LOG_FILE" 2>&1 &
SSHX_PID=$!

echo " Sesi sshx dimulai dengan PID: $SSHX_PID"
echo " Menunggu link dibuat (sekitar 7 detik)..."
sleep 7

# 2. Ambil HANYA URL bersih dari file log untuk menghindari error "Bad Request".
SSHX_LINK=$(grep -o 'https://sshx.io/s/[a-zA-Z0-9_-]*' "$LOG_FILE")

# 3. Kirim notifikasi ke Telegram
if [ -n "$SSHX_LINK" ]; then
    echo " Link ditemukan: $SSHX_LINK"
    MESSAGE="✅ Sesi sshx baru telah siap:
$SSHX_LINK"

    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
        -d chat_id="$TELEGRAM_CHAT_ID" \
        -d text="$MESSAGE" > /dev/null
    
    echo -e "\n Link berhasil dikirim ke Telegram!"
    echo "================================================="
    echo " Sesi sshx sekarang aktif."
    echo " Tekan [Ctrl + C] untuk menghentikan sesi ini."
    echo "================================================="

else
    echo " Gagal mendapatkan link sshx."
    MESSAGE="❌ Gagal membuat sesi sshx. Membatalkan..."

    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
        -d chat_id="$TELEGRAM_CHAT_ID" \
        -d text="$MESSAGE" > /dev/null
    
    # Karena gagal, langsung panggil cleanup untuk berhenti
    cleanup
fi

# 4. Tunggu proses sshx selesai.
#    Baris ini akan membuat skrip "berhenti" di sini, menjaga proses sshx
#    tetap berjalan sampai 'trap' dipicu (oleh Ctrl+C).
wait $SSHX_PID
