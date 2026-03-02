#!/bin/bash

# --- Memastikan hak akses root ---
if [ "$EUID" -ne 0 ]; then 
  echo "Harap jalankan sebagai root (sudo ./elytra.sh)"
  exit 1
fi

echo "--- Memulai Automasi Elytra & Rustic ---"

# 1. Troubleshooting & Setup User pyrodactyl
echo "[1/5] Checking/Creating user pyrodactyl..."
if getent passwd pyrodactyl > /dev/null 2>&1; then
    echo "User 'pyrodactyl' sudah tersedia."
else
    useradd --system --create-home --shell /usr/sbin/nologin --comment "Elytra system user" pyrodactyl
    echo "User 'pyrodactyl' berhasil dibuat."
fi

# 2. Elytra Install Binary
echo "[2/5] Mengunduh Elytra binary..."
curl -L -o /usr/local/bin/elytra https://github.com/pyrohost/elytra/releases/latest/download/elytra_linux_amd64 
chmod u+x /usr/local/bin/elytra

# 3. Installing Rustic
echo "[3/5] Menginstall Rustic v0.10.0..."
mkdir -p /tmp/rustic-install
curl -L https://github.com/rustic-rs/rustic/releases/download/v0.10.0/rustic-v0.10.0-x86_64-unknown-linux-musl.tar.gz | tar -zx -C /tmp/rustic-install

if [ -f "/tmp/rustic-install/rustic" ]; then
    mv /tmp/rustic-install/rustic /usr/local/bin/
    chmod +x /usr/local/bin/rustic
    rm -rf /tmp/rustic-install
    echo "Rustic berhasil diinstal."
else
    echo "Gagal menginstal Rustic. Cek koneksi internet Anda."
    exit 1
fi

# 4. Create systemd config
echo "[4/5] Menyiapkan unit file systemd..."
mkdir -p /etc/elytra

cat <<EOF > /etc/systemd/system/elytra.service
[Unit]
Description=Elytra Daemon
After=docker.service
Requires=docker.service
PartOf=docker.service

[Service]
User=root
WorkingDirectory=/etc/elytra
LimitNOFILE=4096
RuntimeDirectory=elytra
PIDFile=/run/elytra/daemon.pid
ExecStart=/usr/local/bin/elytra
Restart=on-failure
StartLimitInterval=180
StartLimitBurst=30
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

# 5. Reload, Enable, and Start
echo "[5/5] Mengaktifkan dan Menjalankan Service..."
systemctl daemon-reload
systemctl enable --now elytra

echo "------------------------------------------------"
echo "Status Service Elytra:"
systemctl is-active elytra
echo "------------------------------------------------"
echo "Setup selesai! Elytra kini berjalan di background."
