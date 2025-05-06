#!/bin/bash

# File konfigurasi Telegram
TELEGRAM_CONF="/etc/bot/clearlog.db"

# Fungsi kirim notifikasi Telegram
send_telegram() {
  [[ ! -f $TELEGRAM_CONF ]] && return
  source "$TELEGRAM_CONF"
  [[ -z "$TOKEN" || -z "$CHAT_ID" ]] && return

  VPS_IP=$(curl -s ifconfig.me)
  CLIENT_IP=$(who | awk '{print $5}' | tr -d '()' | head -n1)
  HOSTNAME=$(hostname)

  MESSAGE="$1

*Hostname:* \`$HOSTNAME\`
*IP VPS:* \`$VPS_IP\`
*IP Client:* \`${CLIENT_IP:-N/A}\`
"

  curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" \
    -d chat_id="$CHAT_ID" \
    -d parse_mode="Markdown" \
    -d text="$MESSAGE" > /dev/null
}

# Fungsi membersihkan log dan cache dengan animasi
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
    /var/log/cloud-init-output.log
    /var/log/apt/term.log
    /var/log/apt/history.log
    /var/log/nginx/access.log
    /var/log/nginx/error.log
    /var/log/squid/access.log
    /var/log/squid/cache.log
    /var/log/landscape/sysinfo.log
    /var/log/unattended-upgrades/unattended-upgrades-shutdown.log
    /var/log/ubuntu-advantage-apt-hook.log
    /var/log/stunnel4/stunnel.log
    /var/log/ubuntu-advantage.log
    /var/log/kern.log
    /var/log/cloud-init.log
    /var/log/xray/access.log
    /var/log/xray/access2.log
    /var/log/xray/error2.log
    /var/log/xray/error.log
  )

  for log_file in "${LOGS[@]}"; do
    if [[ -f "$log_file" ]]; then
      echo -n "Membersihkan $log_file..."
      pv -q -L 10 < /dev/null > "$log_file"
      cat /dev/null > "$log_file"
      echo " Selesai!"
    fi
  done

  # Membersihkan log sistem dengan animasi
  echo -n "Memutar ulang journalctl..."
  journalctl --rotate &>/dev/null
  journalctl --vacuum-time=1s &>/dev/null
  echo " Selesai!"

  # Menghapus cache
  rm -rf /var/crash/*
  find /var/log -type f -name "*.gz" -delete
  find /var/log -type f -name "*.1" -delete
  find /var/log -type f -name "*.old" -delete
  sync
  echo "Cache dibersihkan!"

  send_telegram "🧹 *[CLEAR LOG]* Log dan cache berhasil dibersihkan."
}

# Fungsi atur jadwal Cron
set_auto_cron() {
  while true; do
    echo -e "\nAuto Clear Log & Cache (Cron)"
    echo "1) Aktifkan & atur jadwal"
    echo "2) Lihat jadwal aktif"
    echo "3) Lihat status cron"
    echo "4) Ubah token & ID Telegram"
    echo "5) Tes kirim pesan Telegram"
    echo "0) Kembali"
    read -rp "Pilih [0-5]: " opt

    case $opt in
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
          1) TIME="*/10 * * * *" ;;
          2) TIME="*/30 * * * *" ;;
          3) TIME="0 * * * *" ;;
          4) TIME="0 */6 * * *" ;;
          5) TIME="0 */12 * * *" ;;
          6) TIME="0 0 * * *" ;;
          *) echo "Pilihan tidak valid."; continue ;;
        esac

        (crontab -l 2>/dev/null | grep -v '/usr/bin/clearlog' ; echo "$TIME /usr/bin/clearlog auto") | crontab -
        echo -e "\e[32m[OK]\e[0m Cron job diaktifkan dengan jadwal: $TIME"
        ;;
      2)
        echo -e "\nJadwal aktif:"
        crontab -l | grep '/usr/bin/clearlog' || echo "Tidak ada"
        ;;
      3)
        echo -e "\nSemua cron job:"
        crontab -l || echo "Tidak ada"
        ;;
      4)
        mkdir -p /etc/bot
        echo -n "Masukkan Token Bot: "
        read TOKEN
        echo -n "Masukkan Chat ID: "
        read CHAT_ID
        echo "TOKEN=$TOKEN" > "$TELEGRAM_CONF"
        echo "CHAT_ID=$CHAT_ID" >> "$TELEGRAM_CONF"
        echo -e "\e[32m[OK]\e[0m Konfigurasi Telegram disimpan."
        ;;
      5)
        send_telegram "✅ *Tes kirim pesan berhasil!*"
        echo -e "\e[32m[OK]\e[0m Pesan terkirim ke Telegram."
        ;;
      0) break ;;
      *) echo "Pilihan tidak valid." ;;
    esac
    read -n 1 -s -r -p "Tekan enter untuk kembali..."
  done
}

# Menu utama
main_menu() {
  while true; do
    clear
    echo "=== MENU CLEAR LOG & CACHE ==="
    echo "1) Clear log & cache manual"
    echo "2) Auto clear log & cache (Cron)"
    echo "0) Keluar"
    read -rp "Pilih [0-2]: " menu

    case $menu in
      1)
        clear_logs_and_cache
        echo -e "\e[32m[OK]\e[0m Clear log & cache manual selesai."
        read -n 1 -s -r -p "Tekan enter untuk kembali..."
        ;;
      2)
        set_auto_cron
        ;;
      0)
      echo -e "${green}Kembali ke menu utama...${plain}"
      sleep 1
      source /usr/bin/menu
      break
      ;;

    *)
      echo -e "${red}Pilihan tidak valid! Silakan coba lagi.${plain}"
      ;;
  esac

  echo
  echo "--------------------------------------------------------"
  echo "Tekan Enter untuk kembali ke menu..."
  echo "--------------------------------------------------------"
  read
done
}

# Mode otomatis jika dipanggil oleh cron
[[ $1 == "auto" ]] && clear_logs_and_cache && exit 0

# Jalankan menu utama
main_menu
