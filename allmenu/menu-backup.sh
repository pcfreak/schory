#!/bin/bash

# Warna
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'
blue='\033[0;34m'
ungu='\033[0;35m'
BlueCyan="\033[5;36m"

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
      echo -e "${yellow}PENGATURAN TOKEN RCLONE${plain}"
      echo
      echo "1). Buat Remote Rclone Baru (via rclone config)"
      echo "2). Edit Token Lama di Remote"
      echo
      read -p "Pilih metode (1/2): " metode
      if [ "$metode" = "1" ]; then
        echo -e "${green}Menjalankan rclone config untuk membuat remote baru...${plain}"
        sleep 1
        rclone config
      elif [ "$metode" = "2" ]; then
        config_file=~/.config/rclone/rclone.conf
        if [ ! -f "$config_file" ]; then
          echo -e "${red}File rclone.conf tidak ditemukan!${plain}"
          break
        fi

        echo
        echo -e "${blue}Daftar remote yang tersedia:${plain}"
        grep "^\[" "$config_file" | sed 's/\[//;s/\]//g' | nl -w2 -s'. '

        echo
        read -p "Masukkan nama remote yang ingin diedit (contoh: gdrive): " remote_name

        echo -e "\n${yellow}Token saat ini untuk [$remote_name]:${plain}"
        echo "-----------------------------------------"
        grep -A 3 "^\[$remote_name\]" "$config_file" | grep "token ="
        echo "-----------------------------------------"

        echo -e "\n${blue}Masukkan token baru (format lengkap, misal: token = {\"access_token\":\"...\"})${plain}"
        read -e -p "> " new_token_line

        backup_file="$config_file.bak.$(date +%s)"
        cp "$config_file" "$backup_file"
        echo -e "${yellow}Backup config lama: $backup_file${plain}"

        awk -v section="[$remote_name]" -v newtoken="$new_token_line" '
          $0 == section {found=1; print; next}
          /^\[.*\]/ {found=0}
          found && /^token = / {$0 = newtoken; found=0}
          {print}
        ' "$backup_file" > "$config_file"

        echo -e "${green}Token berhasil diperbarui untuk remote [$remote_name]!${plain}"
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
