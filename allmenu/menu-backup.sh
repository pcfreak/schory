#!/bin/bash

# Warna
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'
blue='\033[0;34m'
ungu='\033[0;35m'
Green="\033[32m"
Red="\033[31m"
WhiteB="\033[5;37m"
BlueCyan="\033[5;36m"
Green_background="\033[42;37m"
Red_background="\033[41;37m"
Suffix="\033[0m"

edit_rclone_token() {
  config_file=~/.config/rclone/rclone.conf
  if [ ! -f "$config_file" ]; then
    echo -e "${red}File rclone.conf tidak ditemukan!${plain}"
    return
  fi

  echo -e "${yellow}Membuka rclone.conf dengan nano...${plain}"
  sleep 1
  nano "$config_file"
}

while true; do
  clear
  echo -e "${ungu}++++++++++++++++++++++++++++++++++++++++++++"
  echo
  echo -e "${BlueCyan}              Menu Backup                   "
  echo
  echo -e "            ENAK KAN ADA AUTO BACKUPNYA"
  echo -e "${ungu}++++++++++++++++++++++++++++++++++++++++++++"
  echo
  echo -e "${BlueCyan}Pilih Nomor: ${plain}"
  echo
  echo "1). Backup"
  echo "2). Restore"
  echo "3). strt"
  echo "4). Limit Speed"
  echo "5). Auto Backup"
  echo "6). Rclone Change Token (Edit Manual)"
  echo "0). Keluar"
  echo
  echo -e "${ungu}++++++++++++++++++++++++++++++++++++++++++++${plain}"
  echo
  echo -ne "${BlueCyan}Pilih Nomor └╼>>> ${plain}"
  read bro

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
      edit_rclone_token
      ;;
    0)
      echo -e "${green}Terima kasih! Keluar dari menu...${plain}"
      sleep 1
      break
      ;;
    *)
      echo -e "${red}Pilihan tidak valid!${plain}"
      ;;
  esac

  echo
  echo "--------------------------------------------------------"
  echo "Tekan Enter untuk kembali ke menu..."
  echo "--------------------------------------------------------"
  read
done
