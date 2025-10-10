#!/bin/bash
set -e

# --- Konfigurasi ---
AUTH_KEY="tskey-auth-kfgxygS6tF11CNTRL-jnmV9xXCJFRfkdmvsirAFR1difbGx9Eg2"

echo "🚀 Mengecek instalasi Tailscale..."

# --- 1. Cek apakah Tailscale sudah terinstal ---
if command -v tailscale >/dev/null 2>&1; then
  echo "⚙️  Tailscale sudah terinstal. Menghentikan service dan reset konfigurasi..."
  sudo systemctl stop tailscaled || true
  sudo tailscale logout || true
  sudo rm -rf /var/lib/tailscale
  sudo systemctl start tailscaled
else
  echo "⬇️  Tailscale belum terinstal. Menginstal sekarang..."
  curl -fsSL https://tailscale.com/install.sh | sh
fi

# --- 2. Jalankan Tailscale dengan auth key ---
echo "🔐 Menghubungkan ke Tailscale..."
sudo tailscale up --ssh --authkey="$AUTH_KEY" --hostname="$(hostname)-$(date +%s)" || {
  echo "❌ Gagal menghubungkan ke Tailscale. Periksa apakah AUTH_KEY valid."
  exit 1
}

# --- 3. Tampilkan status ---
echo ""
echo "✅ Selesai! Tailscale aktif di mesin ini."
echo "📡 Status koneksi:"
sudo tailscale status
