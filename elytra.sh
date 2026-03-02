#!/bin/bash

# --- Memastikan hak akses root ---
if [ "$EUID" -ne 0 ]; then 
  echo "Harap jalankan sebagai root (sudo bash)"
  exit 1
fi

echo "--- Memulai Instalasi Pterodactyl Wings ---"

# 1. Persiapan Direktori
echo "[1/4] Menyiapkan direktori /etc/pterodactyl..."
mkdir -p /etc/pterodactyl

# 2. Download Wings Binary (Auto Detect Architecture)
echo "[2/4] Mengunduh Wings binary..."
ARCH=$([[ "$(uname -m)" == "x86_64" ]] && echo "amd64" || echo "arm64")
curl -L -o /usr/local/bin/wings "https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_$ARCH"
chmod u+x /usr/local/bin/wings
echo "Wings ($ARCH) berhasil diinstal di /usr/local/bin/wings"

# 3. Membuat systemd service
echo "[3/4] Membuat file wings.service..."

# Menggunakan cat dengan penutup EOF yang bersih (tanpa tab/spasi di depan EOF)
cat <<EOF > /etc/systemd/system/wings.service
[Unit]
Description=Pterodactyl Wings Daemon
After=docker.service
Requires=docker.service
PartOf=docker.service

[Service]
User=root
WorkingDirectory=/etc/pterodactyl
LimitNOFILE=4096
PIDFile=/var/run/wings/daemon.pid
ExecStart=/usr/local/bin/wings
Restart=on-failure
StartLimitInterval=180
StartLimitBurst=30
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

# 4. Aktivasi Service
echo "[4/4] Mengaktifkan dan Menjalankan Wings..."
systemctl daemon-reload
systemctl enable --now wings

echo "------------------------------------------------"
echo "Status Wings:"
systemctl is-active wings
echo "------------------------------------------------"
echo "Instalasi selesai! Jangan lupa letakkan config.yml di /etc/pterodactyl"
