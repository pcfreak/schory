#!/bin/bash

# === Fungsi Kirim Notif Telegram ===
function send_telegram() {
  local token chat_id message
  token=$(cat /etc/bot/clearlog/token 2>/dev/null)
  chat_id=$(cat /etc/bot/clearlog/chat_id 2>/dev/null)
  message="✅ Clear Log & Cache berhasil dijalankan pada $(date '+%d-%m-%Y %H:%M:%S')"

  if [[ -n "$token" && -n "$chat_id" ]]; then
    curl -s -X POST "https://api.telegram.org/bot$token/sendMessage" \
      -d chat_id="$chat_id" \
      -d text="$message" >/dev/null 2>&1
  fi
}

# === Fungsi Clear Log dan Cache ===
function clear_log_cache() {
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

  for log in "${LOGS[@]}"; do
    [[ -f "$log" ]] && : > "$log"
  done

  if command -v journalctl &>/dev/null; then
    journalctl --rotate
    journalctl --vacuum-time=1s
  fi

  rm -rf /var/crash/*
  find /var/log -type f -name "*.gz" -delete
  find /var/log -type f -name "*.1" -delete
  find /var/log -type f -name "*.old" -delete
  sync; echo 3 > /proc/sys/vm/drop_caches

  echo -e "\e[32m[OK]\e[0m Log dan cache berhasil dibersihkan."
  [[ "$1" == "cron" ]] && send_telegram
}

# === Fungsi Set Token dan Chat ID ===
function set_token_chatid() {
  mkdir -p /etc/bot/clearlog
  echo -e "\n--- Ubah Token dan Chat ID Telegram ---"
  read -rp "Masukkan BOT Token Baru: " token
  read -rp "Masukkan Chat ID Baru: " chat_id

  if [[ -n "$token" && -n "$chat_id" ]]; then
    echo "$token" > /etc/bot/clearlog/token
    echo "$chat_id" > /etc/bot/clearlog/chat_id
    chmod 600 /etc/bot/clearlog/{token,chat_id}
    echo -e "\e[32m[OK]\e[0m Token dan Chat ID disimpan."
  else
    echo -e "\e[31m[ERROR]\e[0m Input tidak boleh kosong."
  fi
}

# === Fungsi Atur Cron Schedule ===
function set_cron_schedule() {
  echo -e "\nPilih interval auto clear log & cache:"
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
    *) echo -e "\e[31m[ERROR]\e[0m Pilihan tidak valid."; return ;;
  esac

  CRON_CMD="/usr/bin/clearlog cron >/dev/null 2>&1"
  (crontab -l 2>/dev/null | grep -v "$CRON_CMD"; echo "$interval $CRON_CMD") | crontab -
  echo -e "\e[32m[OK]\e[0m Cron diaktifkan dengan interval: $interval"
}

# === Fungsi Auto Menu ===
function set_auto_cron() {
  while true; do
    echo -e "\n--- Auto Clear Log & Cache ---"
    echo "1) Aktifkan / Ubah Jadwal"
    echo "2) Lihat Cron Aktif"
    echo "3) Lihat Status Cron"
    echo "4) Nonaktifkan Cron"
    echo "5) Ubah Token & ID Telegram"
    echo "0) Kembali"
    read -rp "Pilih [0-5]: " menu_cron

    case $menu_cron in
      1) set_cron_schedule ;;
      2) crontab -l | grep "/usr/bin/clearlog" || echo "Belum ada cron aktif." ;;
      3) crontab -l ;;
      4) (crontab -l 2>/dev/null | grep -v '/usr/bin/clearlog') | crontab -
         echo -e "\e[32m[OK]\e[0m Cron dinonaktifkan." ;;
      5) set_token_chatid ;;
      0) break ;;
      *) echo "Pilihan tidak valid." ;;
    esac
  done
}

# === Menu Utama ===
if [[ "$1" == "cron" ]]; then
  clear_log_cache "cron"
  exit 0
fi

echo -e "\n=== Menu Clear Log & Cache ==="
echo "1) Clear log & cache manual"
echo "2) Auto clear log & cache (cron)"
read -rp "Pilih [1-2]: " menu

case $menu in
  1) clear_log_cache ;;
  2) set_auto_cron ;;
  *) echo "Pilihan tidak valid." ;;
esac
