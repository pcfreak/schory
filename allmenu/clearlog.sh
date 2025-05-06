#!/bin/bash

# === Konfigurasi ===
TELEGRAM_CONF="/etc/bot/clearlog.db"

# === Fungsi kirim pesan ke Telegram ===
send_telegram() {
  [[ ! -f $TELEGRAM_CONF ]] && return
  source "$TELEGRAM_CONF"
  [[ -z $TOKEN || -z $ID ]] && return

  TEXT="$1"
  curl -s -X POST "https://api.telegram.org/bot${TOKEN}/sendMessage" \
    -d chat_id="${ID}" \
    -d parse_mode="Markdown" \
    -d text="$TEXT" > /dev/null 2>&1
}

# === Fungsi clear log dan cache ===
clear_log_cache() {
  LOGS=(
    /var/log/syslog /var/log/auth.log /var/log/daemon.log
    /var/log/kern.log /var/log/dpkg.log /var/log/alternatives.log
    /var/log/ufw.log /var/log/bootstrap.log /var/log/messages
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

  echo -e "\e[32m[OK]\e[0m Log dan cache dibersihkan."

  VPS_IP=$(curl -s ifconfig.me)
  EXEC_USER=$(whoami)
  CLIENT_IP=$(who | awk '{print $5}' | tr -d '()' | head -n 1)
  HOSTNAME=$(hostname)
  TIMESTAMP=$(date '+%d-%m-%Y %H:%M:%S')

  MSG="*[CLEAR LOG]*

Waktu: *$TIMESTAMP*
Hostname: *$HOSTNAME*
VPS IP: *$VPS_IP*
Dijalankan oleh: *$EXEC_USER*
Client IP: *${CLIENT_IP:-N/A}*

Log dan cache berhasil dibersihkan."

  send_telegram "$MSG"
}

# === Fungsi atur cron auto clean ===
set_auto_cron() {
  echo -e "\nAuto Clear Log & Cache (CRON)"
  echo "1) Aktifkan dan atur jadwal"
  echo "2) Lihat cron aktif"
  echo "3) Ubah token & ID Telegram"
  echo "4) Matikan cron"
  echo -n "Pilih [1-4]: "; read pilih
  case $pilih in
    1)
      echo -e "\nPilih interval waktu:"
      echo "1) Setiap 10 menit"
      echo "2) Setiap 30 menit"
      echo "3) Setiap 1 jam"
      echo "4) Setiap 6 jam"
      echo "5) Setiap 12 jam"
      echo "6) Setiap 24 jam"
      read -rp "Pilih [1-6]: " cron_interval
      case $cron_interval in
        1) interval="*/10 * * * *" ;;
        2) interval="*/30 * * * *" ;;
        3) interval="0 * * * *" ;;
        4) interval="0 */6 * * *" ;;
        5) interval="0 */12 * * *" ;;
        6) interval="0 0 * * *" ;;
        *) echo "Pilihan tidak valid."; return ;;
      esac
      CRON_CMD="/usr/bin/clearlog >/dev/null 2>&1"
      (crontab -l 2>/dev/null | grep -v "/usr/bin/clearlog"; echo "$interval $CRON_CMD") | crontab -
      echo -e "\e[32m[OK]\e[0m Auto clearlog & cache aktif setiap interval: $interval"
      ;;
    2)
      echo -e "\nCron aktif:"
      crontab -l | grep "/usr/bin/clearlog" || echo "Tidak ditemukan."
      ;;
    3)
      echo -n "Masukkan TOKEN Bot Telegram: "; read token
      echo -n "Masukkan ID Chat Telegram: "; read id
      mkdir -p /etc/bot
      echo "TOKEN=\"$token\"" > $TELEGRAM_CONF
      echo "ID=\"$id\"" >> $TELEGRAM_CONF
      echo -e "\e[32m[OK]\e[0m Token dan ID disimpan di $TELEGRAM_CONF"
      ;;
    4)
      (crontab -l 2>/dev/null | grep -v "/usr/bin/clearlog") | crontab -
      echo -e "\e[32m[OK]\e[0m Cron auto clearlog dimatikan."
      ;;
    *) echo "Pilihan tidak valid."; return ;;
  esac
}

# === Menu Utama ===
echo -e "\nMenu Clear Log & Cache"
echo "1) Manual clear log & cache"
echo "2) Auto clear log & cache (cron)"
echo -n "Pilih [1-2]: "; read pilih
case $pilih in
  1) clear_log_cache ;;
  2) set_auto_cron ;;
  *) echo "Pilihan tidak valid." ;;
esac
