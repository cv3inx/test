#!/usr/bin/env bash
# remove_all_docker_portainer.sh
# HATI-HATI: Script ini akan menghentikan & menghapus semua container, images, volumes, networks
# serta menghapus file Docker/Portainer umum dan (opsional) paket Docker. Sangat destruktif.
# Jalankan hanya jika kamu yakin.

set -euo pipefail
trap 'echo "Aborted."; exit 1' INT

# Must run as root
if [ "$(id -u)" -ne 0 ]; then
  echo "Script must be run as root. Use sudo."
  exit 2
fi

echo
echo "################################################################################"
echo "!!!  PERINGATAN !!!"
echo "Script ini akan MENGHAPUS SEMUA container, image, volume, network, dan file Docker"
echo "Termasuk Portainer containers/volumes if present."
echo
echo "Jika kamu yakin, ketik: DELETE (huruf besar) dan tekan ENTER"
echo "Jika tidak, tekan CTRL+C"
echo "################################################################################"
read -r CONFIRM
if [ "$CONFIRM" != "DELETE" ]; then
  echo "Konfirmasi tidak diberikan. Keluar."
  exit 0
fi

echo
echo "Mulai proses pembersihan Docker & Portainer..."
echo

# Helper: run docker commands only if docker exists and daemon reachable
has_docker() {
  command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1
}

if has_docker; then
  echo "[1/9] Stop semua container (jika ada)..."
  docker ps -q | xargs -r -n 1 docker stop || true

  echo "[2/9] Remove semua container..."
  docker ps -aq | xargs -r -n 1 docker rm -f || true

  echo "[3/9] Remove semua stack (swarm) jika ada..."
  # Try to remove stacks (best-effort) - list stack names if docker stack available
  if docker stack ls >/dev/null 2>&1; then
    docker stack ls --format '{{.Name}}' | xargs -r -n 1 docker stack rm || true
    sleep 3
  fi

  echo "[4/9] Leave swarm (if part of one)..."
  # graceful: only if this node is part of swarm
  if docker info --format '{{.Swarm.LocalNodeState}}' 2>/dev/null | grep -qi active; then
    docker swarm leave --force || true
  fi

  echo "[5/9] Remove all images..."
  docker images -q | xargs -r -n 1 docker rmi -f || true

  echo "[6/9] Remove all volumes (DANGER: deletes persistent data!)"
  docker volume ls -q | xargs -r -n 1 docker volume rm -f || true

  echo "[7/9] Remove all custom networks (keep default: bridge, host, none) ---"
  # Remove all networks except bridge/host/none
  docker network ls --format '{{.Name}}' | while read -r NET; do
    case "$NET" in
      bridge|host|none) echo "Skipping default network: $NET";;
      *) echo "Removing docker network: $NET"; docker network rm "$NET" >/dev/null 2>&1 || true;;
    esac
  done

  echo "[8/9] Prune any leftover system objects (best-effort)..."
  docker system prune -af --volumes || true
else
  echo "Docker tidak tersedia atau daemon tidak merespon. Lewati langkah docker CLI."
fi

# Remove Linux network interfaces that are typical docker-created bridges
echo "[9/9] Hapus interface bridge/virtual yang berkaitan dengan Docker dari kernel (ip link)."
# List candidate interface names to delete: docker0, docker_gwbridge, br-*, pterodactyl*, veth* (if master is removed)
# We will attempt to delete: docker0, docker_gwbridge, pterodactyl0/pterodactyl*, br-*, if they exist.
# WARNING: This may remove interfaces; it's intended for cleaning leftover docker bridges.
CANDIDATES=()
while read -r IF; do
  CANDIDATES+=("$IF")
done < <(ip -o link show | awk -F': ' '{print $2}' | grep -E '^(docker0|docker_gwbridge|pterodactyl|br-|veth)' || true)

if [ "${#CANDIDATES[@]}" -eq 0 ]; then
  echo "Tidak ditemukan interface Docker-typical untuk dihapus."
else
  echo "Akan mencoba menghapus interface berikut (jika ada):"
  for i in "${CANDIDATES[@]}"; do
    echo "  - $i"
  done

  # Try to delete each interface (best-effort)
  for IF in "${CANDIDATES[@]}"; do
    # skip if it's the physical interface (just in case) or loopback
    if [[ "$IF" =~ ^(eth|en|ens|lo) ]]; then
      echo "Skip interface host-critical: $IF"
      continue
    fi
    echo "Deleting interface: $IF"
    ip link delete "$IF" || echo " - gagal menghapus $IF (mungkin sudah hilang)"
  done
fi

# Remove common Portainer on-disk directories and systemd unit if present
echo
echo "Menghapus file/dir Portainer & Docker yang umum (best-effort)..."
PORTAINER_DIRS=(
  "/var/lib/portainer"
  "/var/lib/portainer-ce"
  "/opt/portainer"
  "/etc/portainer"
)

for d in "${PORTAINER_DIRS[@]}"; do
  if [ -e "$d" ]; then
    echo "Removing $d"
    rm -rf "$d" || echo " - gagal menghapus $d"
  fi
done

# Remove systemd units that might have been created
if [ -f /etc/systemd/system/portainer.service ]; then
  echo "Removing systemd unit /etc/systemd/system/portainer.service"
  systemctl stop portainer.service >/dev/null 2>&1 || true
  systemctl disable portainer.service >/dev/null 2>&1 || true
  rm -f /etc/systemd/system/portainer.service
  systemctl daemon-reload || true
fi

# Remove Docker configuration & data directories (destructive)
DOCKER_PATHS=(
  "/var/lib/docker"
  "/var/lib/containerd"
  "/etc/docker"
  "/run/docker"
)
for p in "${DOCKER_PATHS[@]}"; do
  if [ -e "$p" ]; then
    echo "Removing path $p"
    rm -rf "$p" || echo " - gagal menghapus $p"
  fi
done

# Optionally remove packages (uncomment to enable)
echo
echo "Jika kamu ingin menghapus paket Docker dari sistem, jalankan perintah ini MANUALLY:"
echo "  apt-get remove --purge -y docker-ce docker-ce-cli containerd.io docker-compose-plugin || true"
echo "  apt-get autoremove -y"
echo "  rm -rf /var/lib/docker /var/lib/containerd /etc/docker"

echo
echo "Selesai. Silakan verifikasi:"
echo "  docker ps -a || true"
echo "  docker images || true"
echo "  docker network ls || true"
echo "  ip a | grep -E 'docker|br-|pterodactyl|veth' || true"
echo
echo "CATATAN: Jika masih ada network/iface yang tertinggal, reboot sistem akan memastikan interface virtual yang tidak lagi dipakai dibersihkan."

