#!/bin/bash

db_file="/etc/bot/autoreboot.db"

send_telegram() {
    [[ ! -f $db_file ]] && return
    BOT_TOKEN=$(awk -F= '/token/{print $2}' "$db_file")
    CHAT_ID=$(awk -F= '/id/{print $2}' "$db_file")
    [[ -z "$BOT_TOKEN" || -z "$CHAT_ID" ]] && return

    TEXT="🚀 *AUTO REBOOT TELAH BERJALAN*

Server telah menjalankan proses:
• Bersih-bersih log & cache
• Restart layanan penting
• Reboot sistem

⏰ Jadwal: $(date +"%d-%m-%Y %H:%M:%S")

#AutoReboot #ServerClean"
    
    curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
        -d chat_id="${CHAT_ID}" \
        -d parse_mode="Markdown" \
        -d text="$TEXT" >/dev/null 2>&1
}

# Clear log & cache
journalctl --rotate
journalctl --vacuum-time=1s
rm -rf /var/log/*

# Restart layanan penting
systemctl daemon-reexec
systemctl restart ssh dropbear stunnel5 xray nginx 2>/dev/null

# Kirim notifikasi
send_telegram

# Reboot sistem
reboot
