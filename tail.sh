#!/usr/bin/env bash
set -euo pipefail

# ========== KONFIGURASI ==========
TELEGRAM_BOT_TOKEN="8242643978:AAH9OD2IFcOpWGmUgm1FNb1AYI2ByiHgagQ"
TELEGRAM_CHAT_ID="7028631922"
TIMEOUT_SECS=30
# =================================

TMP_OUT=$(mktemp)
trap 'rm -f "$TMP_OUT"' EXIT

echo "🚀 Menjalankan SSHX session..."
if ! timeout "${TIMEOUT_SECS}s" bash -c 'curl -sSf https://sshx.io/get | sh -s run' >"$TMP_OUT" 2>&1; then
  echo "❌ Gagal menjalankan sshx (timeout atau error)"
  echo "---- LOG ----"
  cat "$TMP_OUT"
  exit 1
fi

# Ambil URL sshx (bisa http/https/sshx://)
URL=$(grep -Eo '(sshx://|https://)[^[:space:]]+' "$TMP_OUT" | head -n1 || true)

if [[ -z "$URL" ]]; then
  echo "⚠️ Tidak menemukan URL SSHX dalam output:"
  cat "$TMP_OUT"
  exit 2
fi

echo "✅ URL SSHX ditemukan: $URL"

# Format pesan Telegram
TEXT="🔐 <b>SSHX session aktif!</b>%0A🌐 <a href=\"${URL}\">${URL}</a>"

# Kirim pesan ke Telegram
API_URL="https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage"

echo "📤 Mengirim URL ke Telegram..."
curl -sS -X POST "$API_URL" \
  -d chat_id="$TELEGRAM_CHAT_ID" \
  -d text="$TEXT" \
  -d parse_mode=HTML \
  -d disable_web_page_preview=true >/dev/null \
  && echo "✅ URL berhasil dikirim ke Telegram." \
  || echo "⚠️ Gagal mengirim pesan ke Telegram."

echo "🎉 Selesai!"
