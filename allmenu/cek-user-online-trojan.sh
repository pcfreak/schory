#!/bin/bash

# Direktori limit IP Trojan per user
LIMIT_DIR="/etc/klmpk/limit/trojan/ip"

# File log Xray
LOG_FILE="/var/log/xray/access.log"

# Ambil log 1 menit terakhir berdasarkan format waktu Xray (YYYY/MM/DD HH:MM)
LOG_NOW=$(date "+%Y/%m/%d %H:%M")
LOG_RECENT=$(grep "$LOG_NOW" "$LOG_FILE")

# Cek jika tidak ada log aktif dalam 1 menit
if [ -z "$LOG_RECENT" ]; then
  echo -e "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo -e "Tidak ada user Trojan yang aktif dalam 1 menit terakhir."
  echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  exit 0
fi

# Ambil semua user yang aktif dari email log
USERS=$(echo "$LOG_RECENT" | grep -oP 'email: \K[^\s]+' | sort -u)

# Tampilkan header
echo -e "\n────────────────────────────────────────────────────────────"
echo -e "               • TROJAN ONLINE NOW (1 Menit) •              "
echo -e "────────────────────────────────────────────────────────────"
printf "%-15s %-18s %-12s %-12s\n" "USERNAME" "IP AKTIF (2 Oktet)" "LIMIT IP" "STATUS"
echo -e "────────────────────────────────────────────────────────────"

TOTAL_IP_GLOBAL=()

for USER in $USERS; do
  LIMIT_FILE="$LIMIT_DIR/$USER"
  if [ ! -f "$LIMIT_FILE" ]; then
    LIMIT_IP=0
  else
    LIMIT_IP=$(cat "$LIMIT_FILE")
  fi

  # Ambil IP dari log user, potong 2 oktet pertama
  USER_IPS=$(echo "$LOG_RECENT" | grep "email: $USER" | grep -oP 'from \K[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | cut -d'.' -f1,2 | sort -u)

  # Hitung jumlah IP unik
  ACTIVE_COUNT=$(echo "$USER_IPS" | wc -l)

  # Gabungkan semua IP ke total global
  TOTAL_IP_GLOBAL+=($USER_IPS)

  # Tentukan status
  if [ "$ACTIVE_COUNT" -gt "$LIMIT_IP" ]; then
    STATUS="\e[31mMelebihi\e[0m"
  else
    STATUS="Dalam Batas"
  fi

  # Tampilkan baris user
  printf "%-15s %-18s %-12s %-12b\n" "$USER" "$ACTIVE_COUNT" "$LIMIT_IP" "$STATUS"

  # Tampilkan daftar IP user
  echo -e "  # Daftar IP (2 Oktet): $(echo "$USER_IPS" | tr '\n' ' ')"
done

# Tampilkan total IP aktif global
TOTAL_UNIK_GLOBAL=$(echo "${TOTAL_IP_GLOBAL[@]}" | tr ' ' '\n' | sort -u | wc -l)

echo -e "\nTotal Seluruh IP Aktif (2 Oktet Unik): $TOTAL_UNIK_GLOBAL"
echo -e "────────────────────────────────────────────────────────────"
echo ""
read -n 1 -s -r -p "   Tekan sembarang tombol untuk kembali ke menu"
menu-trojan
