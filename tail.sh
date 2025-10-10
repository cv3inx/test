#!/usr/bin/env bash
set -euo pipefail

# -----------------------
# Pilihan 1: Hardcoded (sesuai token yang kamu kirim)
# -----------------------
TG_TOKEN_HARDCODED="8242643978:AAH9OD2IFcOpWGmUgm1FNb1AYI2ByiHgagQ"
TG_CHAT_ID_HARDCODED="7277939579"

# -----------------------
# Pilihan 2: Atau gunakan env vars (lebih aman)
# export TELEGRAM_BOT_TOKEN="xxx"
# export TELEGRAM_CHAT_ID="yyy"
# -----------------------
TG_TOKEN="${TELEGRAM_BOT_TOKEN:-$TG_TOKEN_HARDCODED}"
TG_CHAT_ID="${TELEGRAM_CHAT_ID:-$TG_CHAT_ID_HARDCODED}"

# Timeout untuk proses sshx (detik)
TIMEOUT_SECS=60

# File sementara untuk menyimpan output
OUT="$(mktemp /tmp/sshx_out.XXXXXX)"
trap 'rm -f "$OUT"' EXIT

echo "Menjalankan sshx... (timeout ${TIMEOUT_SECS}s)"
# Jalankan installer/runner sshx, tangkap output
if ! timeout "${TIMEOUT_SECS}s" bash -c 'curl -sSf https://sshx.io/get | sh -s run' >"$OUT" 2>&1; then
  echo "Gagal menjalankan sshx atau proses melebihi ${TIMEOUT_SECS}s. Log (potongan):" >&2
  sed -n '1,200p' "$OUT" >&2
  exit 1
fi

# Parsing URL: cari http/https yang mengandung sshx atau domain lain bila ada
URL="$(grep -Eo 'https?://[^[:space:]]+' "$OUT" | grep -Ei 'sshx\.io|sshx' || true)"
URL="$(echo "$URL" | head -n1 || true)"

if [[ -z "$URL" ]]; then
  # Kadang sshx menampilkan scheme custom (sshx://...), coba cari juga
  URL_ALT="$(grep -Eo 'sshx://[^[:space:]]+' "$OUT" || true)"
  URL="${URL_ALT:-}"
fi

if [[ -z "$URL" ]]; then
  echo "Gagal menemukan URL session di output sshx. Log output (potongan):" >&2
  sed -n '1,200p' "$OUT" >&2
  exit 2
fi

echo "Ditemukan URL: $URL"

# Kirim ke Telegram
TG_API="https://api.telegram.org/bot${TG_TOKEN}/sendMessage"
TEXT="🔐 SSHX session started:%0A${URL}"

echo "Mengirim URL ke Telegram (chat_id=${TG_CHAT_ID})..."
curl -sS --fail -X POST "${TG_API}" \
  -d chat_id="${TG_CHAT_ID}" \
  -d text="${TEXT}" \
  -d disable_web_page_preview=true >/dev/null || {
    echo "Gagal kirim ke Telegram." >&2
    exit 3
  }

echo "Sukses dikirim ke Telegram."
echo "$URL"
