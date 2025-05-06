#!/bin/bash

# Path penyimpanan konfigurasi Telegram
TELEGRAM_CONF="/etc/bot/clearlog.db"

# Fungsi kirim notifikasi Telegram
send_telegram() {
  [[ ! -f "$TELEGRAM_CONF" ]] && return
  TOKEN=$(grep 'TOKEN=' "$TELEGRAM_CONF" | cut -d= -f2-)
  CHAT_ID=$(grep 'CHAT_ID=' "$TELEGRAM_CONF" | cut -d= -f2-)
  [[ -z "$TOKEN" || -z "$CHAT_ID" ]] && return

  VPS_IP=$(curl -s ifconfig.me)
  CLIENT_IP=$(who | awk '{print $5}' | sed 's/[()]//g' | head -n1)
  HOSTNAME=$(hostname)

  MESSAGE="$1

Hostname: *$HOSTNAME*
VPS IP: *${VPS_IP:-N/A}*
Client IP: *${CLIENT_IP:-N/A}*"

  curl -s -X POST "https://api.telegram.org/bot${TOKEN}/sendMessage" \
    -d chat_id="$CHAT_ID" \
    -d text="$MESSAGE" \
    -d parse_mode="Markdown" > /dev/null
}

# Fungsi clear log & cache
clear_logs_and_cache() {
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

  for log_file in "${LOGS[@]}"; do
    [[ -f "$log_file" ]] && cat /dev/null > "$log_file"
  done

  journalctl --rotate &>/dev/null
  journalctl --vacuum-time=1s &>/dev/null

  rm -rf /var/crash/*
  find /var/log -type f -name "*.gz" -delete
  find /var/log -type f -name "*.1" -delete
  find /var/log -type f -name "*.old" -delete
  sync; echo 3 > /proc/sys/vm/drop_caches

  echo -e "\e[32m[OK]\e[0m Log dan cache berhasil dibersihkan."
}

# Fungsi ubah token dan ID Telegram
edit_telegram_config() {
  echo -e "\nUbah Token & Chat ID Telegram"
  read -rp "Masukkan Bot Token: " token
  read -rp "Masukkan Chat ID: " chatid

  mkdir -p /etc/bot
  {
    echo "TOKEN=$token"
    echo "CHAT_ID=$chatid"
  } > "$TELEGRAM_CONF"

  echo -e "\e[32m[OK]\e[0m Konfigurasi Telegram berhasil disimpan di $TELEGRAM_CONF"
}

# Fungsi atur auto cron
set_auto_cron() {
  echo -e "\nAuto Clear Log & Cache"
  echo "1) Aktifkan cron dan atur jadwal"
  echo "2) Lihat cron aktif"
  echo "3) Lihat status cron"
  echo "4) Nonaktifkan cron"
  echo "5) Ubah token & ID Telegram"
  read -rp "Pilih [1-5]: " pilih

  case $pilih in
    1)
      echo -e "\nPilih interval:"
      echo "1) Setiap 10 menit"
      echo "2) Setiap 30 menit"
      echo "3) Setiap 1 jam"
      echo "4) Setiap 6 jam"
      echo "5) Setiap 12 jam"
      echo "6) Setiap 24 jam"
      read -rp "Pilih [1-6]: " interval

      case $interval in
        1) cron_time="*/10 * * * *" ;;
        2) cron_time="*/30 * * * *" ;;
        3) cron_time="0 * * * *" ;;
        4) cron_time="0 */6 * * *" ;;
        5) cron_time="0 */12 * * *" ;;
        6) cron_time="0 0 * * *" ;;
        *) echo -e "\e[31m[ERROR]\e[0m Pilihan tidak valid."; return ;;
      esac

      CMD="/usr/bin/clearlog >/dev/null 2>&1"
      (crontab -l 2>/dev/null | grep -v "/usr/bin/clearlog"; echo "$cron_time $CMD") | crontab -
      echo -e "\e[32m[OK]\e[0m Cron diaktifkan."

      send_telegram "🛡️ *[AUTO CLEAR LOG]* telah diaktifkan.
Interval: $cron_time"
      ;;
    2)
      echo -e "\nCron aktif:"
      crontab -l | grep '/usr/bin/clearlog' || echo "Tidak ada cron aktif."
      ;;
    3)
      echo -e "\nStatus semua cron:"
      crontab -l || echo "Tidak ada cron."
      ;;
    4)
      (crontab -l 2>/dev/null | grep -v '/usr/bin/clearlog') | crontab -
      echo -e "\e[32m[OK]\e[0m Cron clearlog berhasil dimatikan."
      ;;
    5)
      edit_telegram_config
      ;;
    *)
      echo -e "\e[31m[ERROR]\e[0m Pilihan tidak valid."
      ;;
  esac
  read -n 1 -s -r -p "Tekan ENTER untuk kembali ke menu..."
  echo
}

# Menu utama
while true; do
  clear
  echo -e "┌─────────────────────────────┐"
  echo -e "│   MENU CLEAR LOG & CACHE    │"
  echo -e "└─────────────────────────────┘"
  echo "1) Clear log & cache manual"
  echo "2) Auto clear log & cache (cron)"
  echo "0) Keluar"
  read -rp "Pilih [0-2]: " menu

  case $menu in
    1)
      echo -e "\nMenjalankan clear log & cache manual..."
      clear_logs_and_cache
      send_telegram "🧹 *[CLEAR LOG MANUAL]* Log dan cache berhasil dibersihkan manual."
      read -n 1 -s -r -p "Tekan ENTER untuk kembali ke menu..."
      echo
      ;;
    2)
      set_auto_cron
      ;;
    0)
      exit 0
      ;;
    *)
      echo "Pilihan tidak valid."
      sleep 1
      ;;
  esac
done
