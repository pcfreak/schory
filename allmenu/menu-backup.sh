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
  echo "6). Ganti Token Rclone"
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
      echo -e "${yellow}GANTI TOKEN RCLONE${plain}"
      echo
      echo "1). Config Manual (via rclone config)"
      echo "2). Replace otomatis dengan file rclone.conf"
      echo
      read -p "Pilih metode (1/2): " metode
      if [ "$metode" = "1" ]; then
        echo -e "${green}Menjalankan rclone config...${plain}"
        sleep 1
        rclone config
      elif [ "$metode" = "2" ]; then
        read -p "Masukkan path ke file rclone.conf baru: " tokenfile
        if [ -f "$tokenfile" ]; then
          mkdir -p ~/.config/rclone
          backup_file=~/.config/rclone/rclone.conf.bak.$(date +%s)
          if [ -f ~/.config/rclone/rclone.conf ]; then
            cp ~/.config/rclone/rclone.conf "$backup_file"
            echo -e "${yellow}Config lama dibackup di:$plain $backup_file"
          fi
          cp "$tokenfile" ~/.config/rclone/rclone.conf
          echo -e "${green}Token berhasil diganti!${plain}"
        else
          echo -e "${red}File tidak ditemukan.${plain}"
        fi
      else
        echo -e "${red}Pilihan tidak valid.${plain}"
      fi
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
