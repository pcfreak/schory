#!/bin/bash

# Warna
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'
ungu='\033[0;35m'
BlueCyan='\033[5;36m'

# Fungsi cek token
cek_token_rclone() {
    local config_file="$HOME/.config/rclone/rclone.conf"
    local remote=$(rclone listremotes 2>/dev/null | head -n1 | sed 's/://')

    echo -e "${yellow}Token Rclone Saat Ini:${plain}"
    if [[ -f "$config_file" && -n "$remote" ]]; then
        echo -e "Remote aktif: ${green}$remote${plain}"
        grep -A 1 "\[$remote\]" "$config_file" | grep token | sed 's/^/   /'
    else
        echo -e "${red}Remote atau file konfigurasi tidak ditemukan.${plain}"
    fi
}

# Fungsi ganti token langsung
gantitoken_manual() {
    cek_token_rclone
    echo ""
    read -p "Masukkan token baru: " new_token
    local config_file="$HOME/.config/rclone/rclone.conf"
    local remote=$(rclone listremotes 2>/dev/null | head -n1 | sed 's/://')

    if [[ -f "$config_file" && -n "$remote" ]]; then
        local backup_file="$config_file.bak.$(date +%s)"
        cp "$config_file" "$backup_file"
        echo -e "${yellow}Config lama dibackup di:${plain} $backup_file"
        sed -i "s|\(token = \).*|\1$new_token|" "$config_file"
        echo -e "${green}Token berhasil diganti!${plain}"
    else
        echo -e "${red}Gagal mengganti token. Pastikan remote tersedia.${plain}"
    fi
}

# Menu utama
while true; do
  clear
  echo -e "${ungu}++++++++++++++++++++++++++++++++++++++++++++${plain}"
  echo -e "${BlueCyan}              Menu Backup VPS              ${plain}"
  echo -e "           ENAK KAN ADA AUTO BACKUPNYA"
  echo -e "${ungu}++++++++++++++++++++++++++++++++++++++++++++${plain}"
  echo
  echo "1). Backup"
  echo "2). Restore"
  echo "3). strt"
  echo "4). Limit Speed"
  echo "5). Auto Backup"
  echo "6). Ganti Token Rclone"
  echo "0). Keluar"
  echo
  echo -ne "${BlueCyan}Pilih Nomor └╼>>> ${plain}"; read bro

  case "$bro" in
    1)
      figlet "Backup" | lolcat
      backup
      ;;

    2)
      figlet "Restore" | lolcat
      restore
      ;;

    3)
      figlet "strt" | lolcat
      strt
      ;;

    4)
      figlet "Limit" | lolcat
      limitspeed
      ;;

    5)
      figlet "AutoBackup" | lolcat
      autobackup
      ;;

    6)
      figlet "Rclone" | lolcat
      echo -e "${yellow}GANTI TOKEN RCLONE${plain}"
      echo "1). Jalankan rclone config manual"
      echo "2). Edit token langsung (input manual)"
      echo "3). Lihat token saat ini"
      echo
      read -p "Pilih metode (1/2/3): " metode
      case $metode in
        1)
          echo -e "${green}Menjalankan rclone config...${plain}"
          sleep 1
          rclone config
          ;;
        2)
          gantitoken_manual
          ;;
        3)
          cek_token_rclone
          ;;
        *)
          echo -e "${red}Pilihan tidak valid.${plain}"
          ;;
      esac
      read -n 1 -s -r -p "Tekan Enter untuk kembali ke menu..."
      ;;

    0)
      echo -e "${green}Terima kasih! Keluar dari menu...${plain}"
      sleep 1
      break
      ;;

    *)
      echo -e "${red}Pilihan tidak valid!${plain}"
      sleep 1
      ;;
  esac
done
