#!/bin/bash

# Script Clear Log + Setup Cron Interval
# By: ChatGPT

# Fungsi membersihkan log
function clear_logs() {
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

  if command -v journalctl &>/dev/null; then
    journalctl --rotate
    journalctl --vacuum-time=1s
  fi

  rm -rf /var/crash/*
  find /var/log -type f -name "*.gz" -delete
  find /var/log -type f -name "*.1" -delete
  find /var/log -type f -name "*.old" -delete

  echo -e "\e[32m[OK]\e[0m Log server dibersihkan."
}

# Fungsi menambahkan cron
function setup_cron() {
  echo -e "\nPilih interval waktu untuk clear log otomatis:"
  echo "1) Setiap 10 menit"
  echo "2) Setiap 30 menit"
  echo "3) Setiap 1 jam"
  echo "4) Setiap 6 jam"
  echo "5) Setiap 12 jam"
  echo "6) Setiap 24 jam"
  read -rp "Pilih [1-6]: " pilihan

  case $pilihan in
    1) interval="*/10 * * * *" ;;
    2) interval="*/30 * * * *" ;;
    3) interval="0 * * * *" ;;
    4) interval="0 */6 * * *" ;;
    5) interval="0 */12 * * *" ;;
    6) interval="0 0 * * *" ;;
    *) echo "Pilihan tidak valid."; return 1 ;;
  esac

  CRON_CMD="/usr/local/bin/clearlog.sh >/dev/null 2>&1"
  CRON_JOB="$interval $CRON_CMD"

  # Hapus duplikat job sebelumnya
  (crontab -l 2>/dev/null | grep -v "$CRON_CMD"; echo "$CRON_JOB") | crontab -

  echo -e "\e[32m[OK]\e[0m Cron job berhasil ditambahkan: $interval"
}

# Jalankan fungsi utama
clear_logs
setup_cron
