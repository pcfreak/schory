#!/bin/bash

# === Konfigurasi file token bot ===
db_file="/etc/bot/autoreboot.db"

# === Fungsi kirim notifikasi Telegram ===
send_telegram() {
    [[ ! -f $db_file ]] && return
    BOT_TOKEN=$(awk -F= '/token/{print $2}' "$db_file")
    CHAT_ID=$(awk -F= '/id/{print $2}' "$db_file")
    [[ -z "$BOT_TOKEN" || -z "$CHAT_ID" ]] && return

    HOSTNAME=$(hostname)
    IPVPS=$(curl -s ifconfig.me || curl -s ipinfo.io/ip)

    curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
        -d chat_id="${CHAT_ID}" \
        -d parse_mode="Markdown" \
        --data-urlencode "text=$1

*Hostname:* \`$HOSTNAME\`
*IP VPS:* \`$IPVPS\`" >/dev/null 2>&1
}

# === Fungsi animasi loading sederhana ===
loading() {
    delay=0.1
    spin=( '|' '/' '-' '\' )
    for ((i = 0; i < 10; i++)); do
        printf "\r[%s] $1" "${spin[$i % 4]}"
        sleep $delay
    done
    printf "\r[✔] $1\n"
}

# === Fungsi utama autoreboot ===
autoreboot_script() {
    echo -e "\n\e[1;32m=== AUTO REBOOT PROCESS STARTED ===\e[0m\n"

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
        /var/log/cloud-init-output.log
        /var/log/apt/term.log
        /var/log/apt/history.log
        /var/log/nginx/access.log
        /var/log/nginx/error.log
        /var/log/squid/access.log
        /var/log/squid/cache.log
        /var/log/landscape/sysinfo.log
        /var/log/unattended-upgrades/unattended-upgrades-shutdown.log
        /var/log/ubuntu-advantage-apt-hook.log
        /var/log/stunnel4/stunnel.log
        /var/log/ubuntu-advantage.log
        /var/log/kern.log
        /var/log/cloud-init.log
        /var/log/xray/access.log
        /var/log/xray/access2.log
        /var/log/xray/error2.log
        /var/log/xray/error.log
    )

    echo -e "\e[1;34m>> Membersihkan file log:\e[0m"
    for log_file in "${LOGS[@]}"; do
        if [[ -f "$log_file" ]]; then
            echo -n "  > $log_file "
            : > "$log_file"
            loading "Dibersihkan"
        fi
    done

    echo -n -e "\n\e[1;34m>> Memutar & vakum journalctl... \e[0m"
    journalctl --rotate &>/dev/null
    journalctl --vacuum-time=1s &>/dev/null
    loading "Journal dibersihkan"

    echo -n -e "\n\e[1;34m>> Menghapus log lama & cache... \e[0m"
    rm -rf /var/crash/*
    find /var/log -type f -name "*.gz" -delete
    find /var/log -type f -name "*.1" -delete
    find /var/log -type f -name "*.old" -delete
    sync
    loading "Selesai"

    services=("nginx" "dropbear" "ssh" "stunnel5" "stunnel4" "vnstat" "squid" "xray" "openvpn" "fail2ban")
    echo -e "\n\e[1;34m>> Restart layanan penting:\e[0m"
    for svc in "${services[@]}"; do
        if systemctl list-unit-files | grep -qw "$svc"; then
            echo -n "  > $svc "
            systemctl restart "$svc" &>/dev/null
            loading "Restarted"
        fi
    done

    send_telegram "$(cat <<EOF
♻️ *[AUTO REBOOT]*

Log & cache telah dibersihkan, layanan telah direstart.

⏰ Waktu: $(date +"%d-%m-%Y %H:%M:%S")
Server akan *reboot* dalam 10 detik...

#AutoReboot
EOF
)"

    echo -e "\n\e[1;33m>> Menunggu 10 detik sebelum reboot...\e[0m"
    sleep 10

    echo -e "\n\e[1;31m>> Rebooting system now...\e[0m"
    /sbin/reboot
}

# Jalankan
autoreboot_script
