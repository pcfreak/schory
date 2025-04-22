#!/bin/bash
BOT_DIR="/etc/bot"
mkdir -p $BOT_DIR

declare -A fungsiBot=(
  [limitip]="Bot Notifikasi Limit IP"
  [backup]="Bot Notifikasi Auto Backup"
  [sshadd]="Bot Notif Add Akun SSH"
)

function list_bot() {
  echo -e "\nDaftar Bot yang Terdaftar:"
  for file in "${!fungsiBot[@]}"; do
    if [[ -f "$BOT_DIR/$file.db" ]]; then
      token=$(awk '{print $2}' "$BOT_DIR/$file.db")
      id=$(awk '{print $3}' "$BOT_DIR/$file.db")
      echo -e "[${file}] ${fungsiBot[$file]}"
      echo -e "  Token : $token"
      echo -e "  ID    : $id"
    else
      echo -e "[${file}] ${fungsiBot[$file]} - \033[0;31mBelum Disetting\033[0m"
    fi
  done
}

function set_bot() {
  echo "Pilih Fungsi Bot:"
  select fungsi in "${!fungsiBot[@]}"; do
    if [[ -n "$fungsi" ]]; then
      read -rp "Masukkan Token Bot untuk ${fungsiBot[$fungsi]}: " token
      read -rp "Masukkan ID Telegram: " chatid
      echo "#bot# $token $chatid" > "$BOT_DIR/$fungsi.db"
      echo "Berhasil disimpan."
      break
    fi
  done
}

function delete_bot() {
  echo "Pilih Bot yang Ingin Dihapus:"
  select fungsi in "${!fungsiBot[@]}"; do
    if [[ -f "$BOT_DIR/$fungsi.db" ]]; then
      rm -f "$BOT_DIR/$fungsi.db"
      echo "Bot ${fungsiBot[$fungsi]} berhasil dihapus."
      break
    else
      echo "Bot belum disetting."
      break
    fi
  done
}

while true; do
  clear
  echo -e "\033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
  echo -e "       \e[1;97;101m MANAJEMEN BOT NOTIFIKASI \e[0m"
  echo -e "\033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
  echo "1. Lihat Daftar Bot"
  echo "2. Tambah / Ganti Bot"
  echo "3. Hapus Bot"
  echo "0. Keluar"
  echo -e "\033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
  read -rp "Pilih menu: " pilih
  case $pilih in
    1) list_bot ;;
    2) set_bot ;;
    3) delete_bot ;;
    0) break ;;
    *) echo "Pilihan tidak valid!" ;;
  esac
  read -n 1 -s -r -p "Tekan Enter untuk kembali ke menu..."
done
