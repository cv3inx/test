#!/bin/bash
set -e


echo "🛑 Stop dan hapus semua container..."
docker ps -aq | xargs -r docker rm -f
echo "🌐 Hapus semua network..."
docker network ls -q | xargs -r docker network rm 2>/dev/null
echo "🖼️ Hapus semua image..."
docker image ls -q | xargs -r docker image rm -f 2>/dev/null
echo "📦 Hapus semua volume..."
docker volume ls -q | xargs -r docker volume rm -f 2>/dev/null
echo "🧹 Hapus semua dangling objects..."
docker system prune -af --volumes

echo "✅ Docker super cleanup selesai!"
echo "🔧 Membuat sertifikat SSL..."
mkdir -p /etc/certs && cd /etc/certs/
openssl req -new -newkey rsa:4096 -days 3650 -nodes -x509 \
  -subj "/C=NA/ST=NA/L=NA/O=NA/CN=Generic SSL Certificate" \
  -keyout privkey.pem -out fullchain.pem

echo "📦 Mengunduh dan memasang Wings..."
mkdir -p /etc/pterodactyl
curl -L -o /usr/local/bin/wings "https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_$([[ "$(uname -m)" == "x86_64" ]] && echo "amd64" || echo "arm64")"
chmod u+x /usr/local/bin/wings

echo "⚙️ Membuat file service systemd..."
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

echo "🚀 Mengaktifkan dan menjalankan Wings..."
systemctl daemon-reload
systemctl enable --now wings

echo "✅ Instalasi selesai! Wings sudah aktif."
systemctl status wings --no-pager
