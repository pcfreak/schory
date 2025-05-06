#!/bin/bash

db_file="/etc/bot/autoreboot.db"
autoreboot_script="/usr/bin/autoreboot"

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

tampilkan_status() {
    if [[ -f /etc/cron.d/autoreboot ]]; then
        JADWAL=$(awk '{print $1, $2, $3, $4, $5}' /etc/cron.d/autoreboot)
        echo "Status : AKTIF"
        echo "Jadwal : $JADWAL"
    elif [[ -f /etc/cron.d/autoreboot-00 || -f /etc/cron.d/autoreboot-05 ]]; then
        echo "Status : AKTIF (Jam Khusus)"
        [[ -f /etc/cron.d/autoreboot-00 ]] && awk '{print "Jadwal :", $1, $2, $3, $4, $5}' /etc/cron.d/autoreboot-00
        [[ -f /etc/cron.d/autoreboot-05 ]] && awk '{print "Jadwal :", $1, $2, $3, $4, $5}' /etc/cron.d/autoreboot-05
    else
        echo "Status : NONAKTIF"
    fi
}

clear
echo -e "======== AUTO REBOOT MENU ========"
tampilkan_status
echo -e "----------------------------------"
echo -e "1. Jadwalkan Jam Khusus Auto Reboot (00:01 & 05:15 WIB)"
echo -e "2. Jadwal 10 Menit sekali"
echo -e "3. Jadwal 1 Jam sekali"
echo -e "4. Jadwal 6 Jam sekali"
echo -e "5. Jadwal 12 Jam sekali"
echo -e "6. Jadwal 1 Hari sekali"
echo -e "7. Jadwal 3 Hari sekali"
echo -e "8. Jadwal 7 Hari sekali"
echo -e "9. Jadwal 1 Bulan sekali"
echo -e "10. Matikan Auto Reboot"
echo -e "11. Jalankan Manual Sekarang"
echo -e "12. Ubah Bot Token & ID Telegram"
echo -e "13. Test Notifikasi Telegram"
echo -e "0. Keluar"
echo -n "Pilih menu: "
read pilih

case $pilih in
1)
    echo "1 17 * * * root $autoreboot_script" > /etc/cron.d/autoreboot-00
    echo "15 22 * * * root $autoreboot_script" > /etc/cron.d/autoreboot-05
    chmod 644 /etc/cron.d/autoreboot-*
    echo "✓ Cron khusus jam 00:01 dan 05:15 WIB ditambahkan."
    ;;
2)
    echo "*/10 * * * * root $autoreboot_script" > /etc/cron.d/autoreboot
    ;;
3)
    echo "0 * * * * root $autoreboot_script" > /etc/cron.d/autoreboot
    ;;
4)
    echo "0 */6 * * * root $autoreboot_script" > /etc/cron.d/autoreboot
    ;;
5)
    echo "0 */12 * * * root $autoreboot_script" > /etc/cron.d/autoreboot
    ;;
6)
    echo "0 0 * * * root $autoreboot_script" > /etc/cron.d/autoreboot
    ;;
7)
    echo "0 0 */3 * * root $autoreboot_script" > /etc/cron.d/autoreboot
    ;;
8)
    echo "0 0 */7 * * root $autoreboot_script" > /etc/cron.d/autoreboot
    ;;
9)
    echo "0 0 1 * * root $autoreboot_script" > /etc/cron.d/autoreboot
    ;;
10)
    rm -f /etc/cron.d/autoreboot /etc/cron.d/autoreboot-*
    echo "✓ Auto reboot dinonaktifkan."
    ;;
11)
    echo "Manual: Clear log, restart service, dan reboot..."
    journalctl --rotate
    journalctl --vacuum-time=1s
    rm -rf /var/log/*
    systemctl daemon-reexec
    systemctl restart ssh dropbear stunnel5 xray nginx 2>/dev/null
    send_telegram "⚙️ *REBOOT MANUAL DIPICU ADMIN*

Admin memicu proses berikut:
• Clear log & cache
• Restart layanan
• Reboot sistem

⏱️ Waktu: $(date +"%d-%m-%Y %H:%M:%S")

#ManualReboot #ServerControl"
    reboot
    ;;
12)
    echo -n "Masukkan BOT TOKEN baru: "
    read token
    echo -n "Masukkan CHAT ID baru: "
    read id
    echo "token=$token" > $db_file
    echo "id=$id" >> $db_file
    echo "✓ Token dan ID berhasil disimpan."
    ;;
13)
    send_telegram "✅ *Test Notifikasi Auto Reboot*\nBot berhasil terkoneksi!"
    echo "✓ Notifikasi dikirim (jika token dan ID valid)."
    ;;
0) exit ;;
*) echo "Pilihan tidak valid." ;;
esac
