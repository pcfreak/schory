#!/bin/bash

SCRIPT="/usr/bin/autoreboot"
CRON_FILE="/etc/cron.d/autoreboot"
CONFIG="/etc/bot/autoreboot.db"

function set_cron() {
    echo "$1 root $SCRIPT" > $CRON_FILE
    chmod 644 $CRON_FILE
    echo "✓ Autoreboot aktif dengan jadwal: $1"
}

function disable_cron() {
    rm -f $CRON_FILE
    echo "✓ Autoreboot dinonaktifkan."
}

function ubah_bot() {
    echo -n "Masukkan BOT TOKEN: "
    read BOT_TOKEN
    echo -n "Masukkan CHAT ID : "
    read CHAT_ID
    mkdir -p /etc/bot
    echo "BOT_TOKEN=$BOT_TOKEN" > $CONFIG
    echo "CHAT_ID=$CHAT_ID" >> $CONFIG
    echo "✓ Konfigurasi disimpan di $CONFIG"
}

function tes_notif() {
    if [[ ! -f $CONFIG ]]; then
        echo "File $CONFIG tidak ditemukan!"
        return
    fi

    source $CONFIG
    [[ -z $BOT_TOKEN || -z $CHAT_ID ]] && echo "Token atau ID kosong!" && return

    MESSAGE="Tes Notifikasi Telegram Berhasil!
Dari: $(hostname) / $(curl -s ipv4.icanhazip.com)
Waktu: $(date '+%d-%m-%Y %H:%M:%S')"

    curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
         -d chat_id="${CHAT_ID}" \
         -d text="${MESSAGE}" >/dev/null 2>&1

    echo "✓ Notifikasi dikirim (jika token dan ID benar)"
}

function manual_reboot() {
    echo "=> Membersihkan log dan cache..."
    journalctl --rotate
    journalctl --vacuum-time=1s
    rm -f /var/log/*.log /var/log/syslog* /var/log/wtmp /var/log/btmp
    sync; echo 3 > /proc/sys/vm/drop_caches

    echo "=> Merestart service..."
    systemctl restart ssh dropbear stunnel4 openvpn xray udp-custom 2>/dev/null

    if [[ -f $CONFIG ]]; then
        source $CONFIG
        MESSAGE="Manual Reboot Diproses!

Hostname: $(hostname)
IP VPS : $(curl -s ipv4.icanhazip.com)
Waktu  : $(date '+%d-%m-%Y %H:%M:%S')"

        curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
             -d chat_id="${CHAT_ID}" \
             -d text="${MESSAGE}" >/dev/null 2>&1
    fi

    echo "=> Reboot sekarang..."
    sleep 2
    reboot
}

function tampilkan_status() {
    if [[ -f $CRON_FILE ]]; then
        JADWAL=$(cat $CRON_FILE | awk '{print $1, $2, $3, $4, $5}')
        echo "Status : AKTIF"
        echo "Jadwal : $JADWAL"
    else
        echo "Status : NONAKTIF"
    fi
}

clear
echo "=== MENU AUTOREBOOT ==="
tampilkan_status
echo "-------------------------"
echo "1. Setiap 10 Menit"
echo "2. Setiap 1 Jam"
echo "3. Setiap 6 Jam"
echo "4. Setiap 12 Jam"
echo "5. Setiap 24 Jam"
echo "6. Setiap 3 Hari"
echo "7. Setiap 7 Hari"
echo "8. Setiap 1 Bulan"
echo "9. Nonaktifkan Autoreboot"
echo "10. Ubah Bot Telegram"
echo "11. Tes Notifikasi Telegram"
echo "12. Jalankan Manual Sekarang"
echo "-------------------------"
read -p "Pilih [1-12]: " pilih

case $pilih in
    1) set_cron "*/10 * * * *" ;;
    2) set_cron "0 * * * *" ;;
    3) set_cron "0 */6 * * *" ;;
    4) set_cron "0 */12 * * *" ;;
    5) set_cron "0 0 * * *" ;;
    6) set_cron "0 0 */3 * *" ;;
    7) set_cron "0 0 */7 * *" ;;
    8) set_cron "0 0 1 * *" ;;
    9) disable_cron ;;
    10) ubah_bot ;;
    11) tes_notif ;;
    12) manual_reboot ;;
    *) echo "Pilihan tidak valid." ;;
esac

