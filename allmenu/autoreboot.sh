#!/bin/bash

# === Konfigurasi file token bot ===
db_file="/etc/bot/autoreboot.db"

# === Fungsi kirim notifikasi Telegram ===
send_telegram() {
    [[ ! -f $db_file ]] && return
    BOT_TOKEN=$(awk -F= '/token/{print $2}' "$db_file")
    CHAT_ID=$(awk -F= '/id/{print $2}' "$db_file")
    [[ -z "$BOT_TOKEN" || -z "$CHAT_ID" ]] && return

    TEXT="$1"
    curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
        -d chat_id="${CHAT_ID}" \
        -d parse_mode="Markdown" \
        -d text="$TEXT" >/dev/null 2>&1
}

# === Fungsi utama autoreboot ===
autoreboot_script() {
    # Daftar file log utama
    LOGS=(
        /var/log/syslog
        /var/log/auth.log
        /var/log/daemon.log
        /var/log/kern.log
        /var/log/dpkg.log
        /var/log/alternatives.log
        /var/log/ufw.log
        /var/log/bootstrap.log
        /var/log/messages
        /var/log/fail2ban.log
    )

    echo -e "\nMembersihkan log file:"
    for log_file in "${LOGS[@]}"; do
        if [[ -f "$log_file" ]]; then
            echo -n "  > $log_file..."
            cat /dev/null > "$log_file"
            echo " Bersih!"
        fi
    done

    echo -n "Memutar ulang journalctl... "
    journalctl --rotate &>/dev/null
    journalctl --vacuum-time=1s &>/dev/null
    echo "Selesai!"

    echo -n "Menghapus log lama & cache... "
    rm -rf /var/crash/*
    find /var/log -type f -name "*.gz" -delete
    find /var/log -type f -name "*.1" -delete
    find /var/log -type f -name "*.old" -delete
    sync
    echo "Selesai!"

    # Restart layanan penting
    services=("nginx" "dropbear" "ssh" "stunnel5" "stunnel4" "vnstat" "squid" "xray" "openvpn" "fail2ban")
    echo -e "\nRestart layanan penting:"
    for svc in "${services[@]}"; do
        if systemctl is-active --quiet "$svc"; then
            echo -n "  > $svc... "
            systemctl restart "$svc" &>/dev/null
            echo "Restarted!"
        fi
    done

    # Kirim notifikasi sebelum reboot
    send_telegram "♻️ *[AUTO REBOOT]*  
Log & cache telah dibersihkan, layanan telah direstart.

⏰ Waktu: $(date +"%d-%m-%Y %H:%M:%S")  
Server akan direboot otomatis sekarang.

#AutoReboot"

    echo -e "\nRebooting system now..."
    reboot
}

# Jalankan
autoreboot_script
