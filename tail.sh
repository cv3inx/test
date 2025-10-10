#!/bin/bash

# Menghentikan skrip jika terjadi error (best practice)
set -e

# --- Konfigurasi ---
# Auth key untuk otentikasi otomatis ke akun Tailscale Anda.
# PERINGATAN: Kunci ini bersifat rahasia. Jangan bagikan skrip ini dengan kunci di dalamnya.
AUTH_KEY="tskey-auth-ktNazoGrQE11CNTRL-nJNawmE9TJTNtRSs65UHJTCXaXkzHGxH"

# --- 1. Instalasi Tailscale ---
echo " Men-download dan menjalankan skrip instalasi Tailscale..."
curl -fsSL https://tailscale.com/install.sh | sh

# --- 2. Menghubungkan Tailscale ---
echo " Menjalankan 'tailscale up' untuk menghubungkan perangkat ke jaringan Anda..."
# Opsi --hostname akan memberi nama unik pada perangkat di dashboard Tailscale Anda
# Contoh nama: my-server-1665401828
sudo tailscale up --authkey="$AUTH_KEY" --hostname="$(hostname)-$(date +%s)"

echo ""
echo "✅ Selesai! Tailscale telah terinstal dan berhasil terhubung."
echo "Untuk memeriksa status, jalankan: tailscale status"
