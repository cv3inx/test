#!/usr/bin/env bash
set -euo pipefail

# ========== KONFIGURASI ==========
TELEGRAM_BOT_TOKEN="8242643978:AAH9OD2IFcOpWGmUgm1FNb1AYI2ByiHgagQ"
TELEGRAM_CHAT_ID="7028631922"
LOG_FILE="/tmp/sshx_session.log"
# =================================

rm -f "$LOG_FILE"
touch "$LOG_FILE"

(
  echo "🚀 Menjalankan SSHX session..." | tee -a "$LOG_FILE"

  # Jalankan sshx di background dan simpan output
  (curl -sSf https://sshx.io/get | sh -s run) >"$LOG_FILE" 2>&1 &

  # Tunggu sampai URL muncul
  echo "⏳ Menunggu URL SSHX muncul..." | tee -a "$LOG_FILE"
  for i in {1..15}; do
    if grep -Eq '(sshx://|https://)' "$LOG_FILE"; then
      break
    fi
    sleep 1
  done

  # Ambil URL SSHX
  URL=$(grep -Eo '(sshx://|https://)[^[:space:]]+' "$LOG_FILE" | head -n1 || true)

  if [[ -z "$URL" ]]; then
    echo "⚠️ Tidak menemukan URL SSHX dalam output!" | tee -a "$LOG_FILE"
    exit 2
  fi

  echo "✅ URL SSHX ditemukan: $URL" | tee -a "$LOG_FILE"

  # Kirim ke Telegram
  TEXT="🔐 <b>SSHX session aktif di background!</b>%0A🌐 <a href=\"${URL}\">${URL}</a>"
  API_URL="https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage"

  echo "📤 Mengirim URL ke Telegram..." | tee -a "$LOG_FILE"
  if curl -sS -X POST "$API_URL" \
    -d chat_id="$TELEGRAM_CHAT_ID" \
    -d text="$TEXT" \
    -d parse_mode=HTML \
    -d disable_web_page_preview=true >/dev/null; then
    echo "✅ URL berhasil dikirim ke Telegram." | tee -a "$LOG_FILE"
  else
    echo "⚠️ Gagal mengirim pesan ke Telegram." | tee -a "$LOG_FILE"
  fi

  echo "🎉 SSHX session sekarang aktif di background!" | tee -a "$LOG_FILE"
) & disown

echo "✅ SSHX session sedang dijalankan di background."
echo "📄 Cek log di: $LOG_FILE"
