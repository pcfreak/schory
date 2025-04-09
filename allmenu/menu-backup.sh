#!/bin/bash

# Warna
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'
blue='\033[0;34m'
ungu='\033[0;35m'
BlueCyan="\033[5;36m"

# Menu utama
while true; do
  clear
  echo -e "${ungu}++++++++++++++++++++++++++++++++++++++++++++${plain}"
  echo -e "${BlueCyan}              MENU BACKUP                   ${plain}"
  echo -e "            ENAK KAN ADA AUTO BACKUPNYA"
  echo -e "${ungu}++++++++++++++++++++++++++++++++++++++++++++${plain}"
  echo
  echo "1). Backup"
  echo "2). Restore"
  echo "3). Start Service (strt)"
  echo "4). Limit Speed"
  echo "5). Auto Backup"
  echo "6). Edit Token Rclone (nano)"
  echo "0). Kembali ke Menu Utama"
  echo
  echo -e "${ungu}++++++++++++++++++++++++++++++++++++++++++++${plain}"
  echo
  read -p "Pilih Nomor └╼>>> " bro

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
      figlet "Start" | lolcat
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
      config_file="$HOME/.config/rclone/rclone.conf"
      if [ ! -f "$config_file" ]; then
        echo -e "${red}File rclone.conf tidak ditemukan di $config_file${plain}"
      else
        echo -e "${yellow}Membuka token rclone dengan nano...${plain}"
        sleep 1
        nano "$config_file"
        echo -e "${green}Selesai mengedit token.${plain}"
      fi
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
