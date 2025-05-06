#!/bin/bash

# === Konfigurasi ===
TELEGRAM_CONF="/etc/bot/clearlog.db"

# === Fungsi Kirim Notifikasi Telegram ===
send_telegram() {
  [[ ! -f $TELEGRAM_CONF ]] && return
  source "$TELEGRAM_CONF"
  [[ -z $TOKEN || -z $ID ]] && return

  curl -s -X POST "https://api.telegram.org/bot${TOKEN}/sendMessage" \
    -d chat_id="${ID}" \
    -d parse_mode="Markdown" \
    -d text="$1" >/dev/null 2>&1
}

# === Fungsi Clear Log & Cache ===
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
  send_telegram "*[CLEAR LOG]* Log dan cache berhasil dibersihkan otomatis."
}

# === Fungsi Set Auto Cron ===
set_auto_cron() {
  while true; do
    echo -e "\nAuto Clear Log & Cache Menu"
    echo "1) Aktifkan dan Atur Jadwal"
    echo "2) Lihat Jadwal Aktif"
    echo "3) Lihat Status Cron"
    echo "4) Ubah Token & ID Telegram"
    echo "5) Hapus Cron"
    echo "0) Kembali"
    read -rp "Pilih [0-5]: " opt

    case $opt in
      1)
        echo -e "\nPilih interval cron:"
        echo "1) Setiap 10 menit"
        echo "2) Setiap 30 menit"
        echo "3) Setiap 1 jam"
        echo "4) Setiap 6 jam"
        echo "5) Setiap 12 jam"
        echo "6) Setiap 24 jam"
        read -rp "Pilih [1-6]: " intvl
        case $intvl in
          1) schedule="*/10 * * * *" ;;
          2) schedule="*/30 * * * *" ;;
          3) schedule="0 * * * *" ;;
          4) schedule="0 */6 * * *" ;;
          5) schedule="0 */12 * * *" ;;
          6) schedule="0 0 * * *" ;;
          *) echo "Pilihan tidak valid."; continue ;;
        esac
        CMD="/usr/bin/clearlog auto >/dev/null 2>&1"
        (crontab -l 2>/dev/null | grep -v '/usr/bin/clearlog' ; echo "$schedule $CMD") | crontab -
        echo -e "\e[32m[OK]\e[0m Cron ditambahkan: $schedule"
        ;;
      2)
        crontab -l | grep '/usr/bin/clearlog' || echo "Tidak ada cron aktif."
        ;;
      3)
        crontab -l || echo "Tidak ada cron."
        ;;
      4)
        echo -n "Masukkan BOT TOKEN: "; read token
        echo -n "Masukkan CHAT ID: "; read id
        mkdir -p /etc/bot
        echo "TOKEN=$token" > "$TELEGRAM_CONF"
        echo "ID=$id" >> "$TELEGRAM_CONF"
        echo -e "\e[32m[OK]\e[0m Token & ID Telegram disimpan."
        ;;
      5)
        (crontab -l | grep -v '/usr/bin/clearlog') | crontab -
        echo -e "\e[32m[OK]\e[0m Cron auto clearlog dihapus."
        ;;
      0) break ;;
      *) echo "Pilihan tidak valid." ;;
    esac
  done
}

# === Eksekusi ===
if [[ $1 == "auto" ]]; then
  clear_log_cache
  exit
fi

# === Menu Utama ===
while true; do
  echo -e "\nMenu Clear Log & Cache"
  echo "1) Clear log & cache manual"
  echo "2) Auto clear log & cache (cron)"
  echo "0) Keluar"
  read -rp "Pilih [0-2]: " menu
  case $menu in
    1) clear_log_cache ;;
    2) set_auto_cron ;;
    0) exit ;;
    *) echo "Pilihan tidak valid." ;;
  esac
done
