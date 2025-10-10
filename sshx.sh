#!/usr/bin/env bash
set -euo pipefail

# ========== KONFIGURASI ==========
TELEGRAM_BOT_TOKEN="8242643978:AAH9OD2IFcOpWGmUgm1FNb1AYI2ByiHgagQ"
TELEGRAM_CHAT_ID="7028631922"
TIMEOUT_SECS=20
# =================================

TMP_OUT=$(mktemp)
trap 'rm -f "$TMP_OUT"' EXIT

echo "🚀 Menjalankan SSHX session..."
# Jalankan sshx dan simpan output
if ! timeout "${TIMEOUT_SECS}s" bash -c 'curl -sSf https://sshx.io/get | sh -s run >"$TMP_OUT" 2>&1' _; then
  echo "❌ Gagal menjalankan sshx (timeout atau error)"
  cat "$TMP_OUT"
  exit 1
fi

# Coba ambil URL sshx dari output
URL=$(grep -Eo '(sshx://|https://)[^[:space:]]+' "$TMP_OUT" | head -n1 || true)

# Kalau belum ketemu, coba cek log sshx di background
if [[ -z "$URL" ]]; then
  URL=$(grep -Eo '(sshx://|https://)[^[:space:]]+' <<< "$(tail -n 20 "$TMP_OUT")" | head -n1 || true)
fi

if [[ -z "$URL" ]]; then
  echo "⚠️ Tidak menemukan URL SSHX dalam output:"
  cat "$TMP_OUT"
  exit 2
fi

echo "✅ URL SSHX ditemukan: $URL"

# Format pesan Telegram (HTML)
TEXT="🔐 <b>SSHX session aktif!</b>%0A🌐 <a href=\"${URL}\">${URL}</a>"

# Kirim ke Telegram
API_URL="https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage"
echo "📤 Mengirim URL ke Telegram..."
if curl -sS -X POST "$API_URL" \
  -d chat_id="$TELEGRAM_CHAT_ID" \
  -d text="$TEXT" \
  -d parse_mode=HTML \
  -d disable_web_page_preview=true >/dev/null; then
  echo "✅ URL berhasil dikirim ke Telegram."
else
  echo "⚠️ Gagal mengirim pesan ke Telegram."
fi

echo "🎉 Selesai!"
