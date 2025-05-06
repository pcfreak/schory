#!/bin/bash

# Lokasi konfigurasi token & ID Telegram
TELEGRAM_CONF="/etc/bot/clearlog.db"

# Fungsi: Kirim notifikasi Telegram
send_telegram() {
  if [[ -s $TELEGRAM_CONF ]]; then
    source "$TELEGRAM_CONF"
    [[ -z "$TOKEN" || -z "$ID" ]] && return

    local message="$1"
    curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" \
      -d chat_id="$ID" \
      -d parse_mode="Markdown" \
      -d text="$message" >/dev/null 2>&1
  fi
}

# Fungsi: Clear log dan cache
clear_log_cache() {
  local total_cleared=0
  local logs=(
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

  for log in "${logs[@]}"; do
    if [[ -f "$log" ]]; then
      : > "$log"
      ((total_cleared++))
    fi
  done

  journalctl --rotate &>/dev/null
  journalctl --vacuum-time=1s &>/dev/null
  rm -rf /var/crash/*
  find /var/log -type f -name "*.gz" -delete
  find /var/log -type f -name "*.1" -delete
  find /var/log -type f -name "*.old" -delete

  # Bersihkan cache
  sync; echo 3 > /proc/sys/vm/drop_caches

  local now=$(date '+%d-%m-%Y %H:%M:%S')
  local cron_status=$(crontab -l 2>/dev/null | grep '/usr/bin/clearlog' || echo "Tidak aktif")

  send_telegram "✅ *Clear Log & Cache*\n\n🕒 *Waktu:* $now\n🧹 *Log dibersihkan:* $total_cleared file\n⚙️ *Cache dibersihkan*\n⏰ *Cron:* \`$cron_status\`"
  echo -e "\e[32m[OK]\e[0m Log & Cache berhasil dibersihkan ($total_cleared file)."
}

# Fungsi: Atur Token & ID Telegram
set_telegram() {
  read -rp "Masukkan Bot Token: " TOKEN
  read -rp "Masukkan Chat ID: " ID
  mkdir -p $(dirname "$TELEGRAM_CONF")
  echo "TOKEN=\"$TOKEN\"" > "$TELEGRAM_CONF"
  echo "ID=\"$ID\"" >> "$TELEGRAM_CONF"
  echo -e "\e[32m[OK]\e[0m Token & ID Telegram disimpan ke $TELEGRAM_CONF."
}

# Fungsi: Setup/atur cron
set_auto_cron() {
  while true; do
    echo -e "\nAuto Clear Log & Cache (Cron)"
    echo "1) Aktifkan & Atur Jadwal"
    echo "2) Lihat Jadwal Aktif"
    echo "3) Lihat Status Cron"
    echo "4) Ubah Token & ID Telegram"
    echo "0) Kembali"
    read -rp "Pilih [0-4]: " opt
    case $opt in
      1)
        echo -e "\nPilih interval waktu:"
        echo "1) Setiap 10 menit"
        echo "2) Setiap 30 menit"
        echo "3) Setiap 1 jam"
        echo "4) Setiap 6 jam"
        echo "5) Setiap 12 jam"
        echo "6) Setiap 24 jam"
        read -rp "Pilih [1-6]: " interval_opt
        case $interval_opt in
          1) interval="*/10 * * * *" ;;
          2) interval="*/30 * * * *" ;;
          3) interval="0 * * * *" ;;
          4) interval="0 */6 * * *" ;;
          5) interval="0 */12 * * *" ;;
          6) interval="0 0 * * *" ;;
          *) echo "Pilihan tidak valid."; continue ;;
        esac
        cron_job="$interval /usr/bin/clearlog >/dev/null 2>&1"
        (crontab -l 2>/dev/null | grep -v '/usr/bin/clearlog'; echo "$cron_job") | crontab -
        echo -e "\e[32m[OK]\e[0m Cron diaktifkan: $interval"
        ;;
      2)
        echo -e "\nJadwal aktif:"
        crontab -l | grep '/usr/bin/clearlog' || echo "Belum ada."
        ;;
      3)
        echo -e "\nStatus cron:"
        crontab -l || echo "Cron kosong."
        ;;
      4)
        set_telegram
        ;;
      0) break ;;
      *) echo "Pilihan tidak valid." ;;
    esac
  done
}

# Menu Utama
while true; do
  clear
  echo -e "===== MENU CLEAR LOG & CACHE ====="
  echo "1) Jalankan Manual"
  echo "2) Auto Clear Log & Cache (Cron)"
  echo "0) Keluar"
  read -rp "Pilih [0-2]: " main_opt
  case $main_opt in
    1) clear_log_cache ;;
    2) set_auto_cron ;;
    0) exit ;;
    *) echo "Pilihan tidak valid."; sleep 1 ;;
  esac
done
