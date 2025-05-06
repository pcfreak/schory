#!/bin/bash

CONFIG="/etc/bot/autoreboot.db"

# Fungsi untuk mengirim notifikasi ke Telegram
send_telegram_notif() {
    if [[ -f $CONFIG ]]; then
        source $CONFIG
        if [[ -z $BOT_TOKEN || -z $CHAT_ID ]]; then
            echo "Token atau ID kosong! Notifikasi gagal dikirim."
            return
        fi

        MESSAGE="Autoreboot Proses!

Hostname: $(hostname)
IP VPS : $(curl -s ipv4.icanhazip.com)
Waktu  : $(date '+%d-%m-%Y %H:%M:%S')"

        curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
             -d chat_id="${CHAT_ID}" \
             -d text="${MESSAGE}" >/dev/null 2>&1
        echo "✓ Notifikasi dikirim ke Telegram."
    else
        echo "File $CONFIG tidak ditemukan. Notifikasi gagal."
    fi
}

# Membersihkan log dan cache
clear_logs_cache() {
    echo "=> Membersihkan log dan cache..."
    journalctl --rotate
    journalctl --vacuum-time=1s
    rm -f /var/log/*.log /var/log/syslog* /var/log/wtmp /var/log/btmp
    sync; echo 3 > /proc/sys/vm/drop_caches
}

# Restart semua layanan
restart_services() {
    echo "=> Merestart semua service..."
    systemctl restart ssh dropbear stunnel4 openvpn xray udp-custom 2>/dev/null
}

# Reboot sistem
reboot_system() {
    echo "=> Reboot sistem sekarang..."
    reboot
}

# Jalankan fungsi sesuai urutan
clear_logs_cache
restart_services
send_telegram_notif
reboot_system
