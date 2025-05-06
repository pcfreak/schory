#!/bin/bash

# Script Clear Log + Setup/Update Cron Interval
# By: kanghory

# Fungsi menambahkan atau memperbarui cron
function setup_or_update_cron() {
  echo -e "\nPilih opsi berikut:"
  echo "1) Clear log manual"
  echo "2) Matikan Cron"
  echo "3) Lihat Status Cron"
  echo "4) Aktifkan Cron (Ubah Jadwal)"
  read -rp "Pilih [1-4]: " pilihan

  case $pilihan in
    1) 
      echo -e "\nMenjalankan clear log manual..."
      clear_logs
      return 0
      ;;
    2)
      echo -e "\nMematikan cron job..."
      (crontab -l 2>/dev/null | grep -v '/usr/local/bin/clearlog.sh') | crontab -
      echo -e "\e[32m[OK]\e[0m Cron job berhasil dimatikan."
      return 0
      ;;
    3)
      echo -e "\nLihat status cron job..."
      crontab -l
      return 0
      ;;
    4) 
      echo -e "\nAktifkan cron job."
      echo -e "\nPilih interval waktu untuk mengaktifkan cron:"
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
        *) echo -e "\e[31m[ERROR]\e[0m Pilihan tidak valid."; return 1 ;;
      esac

      CRON_CMD="/usr/local/bin/clearlog.sh >/dev/null 2>&1"
      CRON_JOB="$interval $CRON_CMD"
      (crontab -l 2>/dev/null | grep -v "$CRON_CMD"; echo "$CRON_JOB") | crontab -

      echo -e "\e[32m[OK]\e[0m Cron job berhasil diaktifkan dengan interval: $interval"
      return 0
      ;;
    *) echo "Pilihan tidak valid."; return 1 ;;
  esac
}

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

# Menu utama
echo -e "\nMenu Clear Log"
setup_or_update_cron
