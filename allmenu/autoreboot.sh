#!/bin/bash

# Animasi proses
spinner() {
    local pid=$!
    local delay=0.1
    local spinstr='|/-\\'
    while ps a | awk '{print $1}' | grep -q "$pid"; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "      \b\b\b\b\b\b"
}

# Clear log dan cache
echo -e "\e[1;33m[>] Membersihkan log dan cache...\e[0m"
(journalctl --rotate && journalctl --vacuum-time=1s && rm -rf /var/log/*) & spinner

# Restart layanan
echo -e "\e[1;34m[>] Restart semua layanan penting...\e[0m"
(systemctl daemon-reexec && systemctl restart ssh dropbear stunnel5 xray nginx 2>/dev/null) & spinner

# Kirim notifikasi Telegram
DB_FILE="/etc/bot/autoreboot.db"
if [[ -f $DB_FILE ]]; then
    source $DB_FILE
    if [[ -n $token && -n $id ]]; then
        MESSAGE="*AUTO REBOOT SERVER*

Server berhasil menjalankan proses:
✅ *Pembersihan log & cache*
✅ *Restart layanan inti*
⏱️ *Waktu:* _$(date '+%d-%m-%Y %H:%M:%S')_

_Server akan reboot dalam beberapa saat..._

#AutoReboot"
        curl -s -X POST https://api.telegram.org/bot$token/sendMessage \
            -d chat_id="$id" \
            -d parse_mode="Markdown" \
            -d text="$MESSAGE" > /dev/null 2>&1
    fi
fi

# Reboot sistem
echo -e "\e[1;32m[>] Rebooting sistem...\e[0m"
sleep 2
reboot
