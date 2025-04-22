#!/bin/bash

user="$1"
LOCK_DURATION_FILE="/etc/klmpk/limit/ssh/lock_duration"
BOT_FILE="/etc/bot/limitip.db"

# Unlock akun
passwd -u "$user" > /dev/null

# Ambil token dan ID
[[ -f "$BOT_FILE" ]] || exit
read -r _ bottoken idtelegram < <(grep '^#bot#' "$BOT_FILE")
[[ -z "$bottoken" || -z "$idtelegram" ]] && exit

# Ambil durasi
if [[ -f "$LOCK_DURATION_FILE" ]]; then
    LOCK_DURATION=$(cat "$LOCK_DURATION_FILE")
else
    LOCK_DURATION=15
fi

# Kirim notifikasi ke Telegram
curl -s -X POST https://api.telegram.org/bot${bottoken}/sendMessage \
    -d chat_id="${idtelegram}" \
    -d text="✅ *SSH User:* \`$user\` telah *dibuka kembali* setelah *$LOCK_DURATION menit* dikunci." \
    -d parse_mode="Markdown" > /dev/null
