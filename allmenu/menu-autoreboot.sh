#!/bin/bash

db_file="/etc/bot/autoreboot.db"
script_path="/usr/bin/autoreboot"

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
    echo -e "Status Jadwal Cron:"
    ls /etc/cron.d/autoreboot* 2>/dev/null | while read file; do
        waktu=$(awk '{print $1, $2, $3, $4, $5}' "$file")
        echo "• $(basename "$file") : $waktu"
    done
    [[ -z $(ls /etc/cron.d/autoreboot* 2>/dev/null) ]] && echo "• Tidak ada jadwal aktif"
}

while true; do
    clear
    echo -e "======== AUTO REBOOT MENU ========"
    echo -e "Waktu Server (UTC): $(date)"
    tampilkan_status
    echo -e "----------------------------------"
    echo -e "1. Jadwal Jam 00:10 WIB"
    echo -e "2. Jadwal Jam 05:15 WIB"
    echo -e "3. Jadwal Tiap 10 Menit"
    echo -e "4. Jadwal Tiap 1 Jam"
    echo -e "5. Jadwal Tiap 6 Jam"
    echo -e "6. Jadwal Tiap 12 Jam"
    echo -e "7. Jadwal Tiap 1 Hari"
    echo -e "8. Jadwal Tiap 1 Minggu"
    echo -e "9. Jadwal Tiap 1 Bulan"
    echo -e "10. Nonaktifkan Semua Jadwal"
    echo -e "11. Jalankan Manual Sekarang"
    echo -e "12. Ubah Bot Token & ID Telegram"
    echo -e "13. Test Notifikasi Telegram"
    echo -e "0. Keluar"
    echo -n "Pilih menu: "
    read pilih

    case $pilih in
    1)
        echo "10 0 * * * root $script_path" > /etc/cron.d/autoreboot-0010
        chmod 644 /etc/cron.d/autoreboot-0010
        echo "✓ Jadwal 00:10 WIB ditambahkan."
        ;;
    2)
        echo "15 5 * * * root $script_path" > /etc/cron.d/autoreboot-0515
        chmod 644 /etc/cron.d/autoreboot-0515
        echo "✓ Jadwal 05:15 WIB ditambahkan."
        ;;
    3)
        echo "*/10 * * * * root $script_path" > /etc/cron.d/autoreboot-10mnt
        chmod 644 /etc/cron.d/autoreboot-10mnt
        echo "✓ Jadwal tiap 10 menit ditambahkan."
        ;;
    4)
        echo "0 * * * * root $script_path" > /etc/cron.d/autoreboot-1jam
        chmod 644 /etc/cron.d/autoreboot-1jam
        echo "✓ Jadwal tiap 1 jam ditambahkan."
        ;;
    5)
        echo "0 */6 * * * root $script_path" > /etc/cron.d/autoreboot-6jam
        chmod 644 /etc/cron.d/autoreboot-6jam
        echo "✓ Jadwal tiap 6 jam ditambahkan."
        ;;
    6)
        echo "0 */12 * * * root $script_path" > /etc/cron.d/autoreboot-12jam
        chmod 644 /etc/cron.d/autoreboot-12jam
        echo "✓ Jadwal tiap 12 jam ditambahkan."
        ;;
    7)
        echo "0 0 * * * root $script_path" > /etc/cron.d/autoreboot-1hari
        chmod 644 /etc/cron.d/autoreboot-1hari
        echo "✓ Jadwal tiap 1 hari ditambahkan."
        ;;
    8)
        echo "0 0 * * 0 root $script_path" > /etc/cron.d/autoreboot-1minggu
        chmod 644 /etc/cron.d/autoreboot-1minggu
        echo "✓ Jadwal tiap 1 minggu ditambahkan."
        ;;
    9)
        echo "0 0 1 * * root $script_path" > /etc/cron.d/autoreboot-1bulan
        chmod 644 /etc/cron.d/autoreboot-1bulan
        echo "✓ Jadwal tiap 1 bulan ditambahkan."
        ;;
    10)
        rm -f /etc/cron.d/autoreboot*
        echo "✓ Semua jadwal auto reboot dinonaktifkan."
        ;;
    11)
        echo "Menjalankan manual via script autoreboot..."
        bash "$script_path"
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
    0)
        echo -e "Kembali ke menu utama..."
        sleep 1
        [[ -f /usr/bin/menu ]] && source /usr/bin/menu
        break
        ;;
    *)
        echo -e "Pilihan tidak valid! Silakan coba lagi."
        ;;
    esac

    echo
    echo "--------------------------------------------------------"
    echo "Tekan Enter untuk kembali ke menu..."
    echo "--------------------------------------------------------"
    read
done
