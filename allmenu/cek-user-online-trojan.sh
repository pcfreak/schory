#!/bin/bash

LIMIT_DIR="/etc/klmpk/limit/trojan/ip"
LOG_FILE="/var/log/xray/access.log"

# Ambil log 1 menit terakhir
LOG_NOW=$(date "+%Y-%m-%d %H:%M")
LOG_RECENT=$(grep "$LOG_NOW" "$LOG_FILE")

# Ambil semua user unik dari log 1 menit terakhir
USERS=$(echo "$LOG_RECENT" | grep -oP '(?<=email: )[^\s]+' | sort -u)

if [ -z "$USERS" ]; then
  echo "Tidak ada user Trojan yang aktif dalam 1 menit terakhir."
  exit 1
fi

clear
echo -e "────────────────────────────────────────────────────────────"
echo -e "             • TROJAN ONLINE NOW (Last 1 Min) •             "
echo -e "────────────────────────────────────────────────────────────"
echo -e ""
echo -e "USERNAME         IP AKTIF (2 Oktet)   LIMIT IP     STATUS"
echo -e "────────────────────────────────────────────────────────────"

TOTAL_IP_ALL=()

for USER in $USERS; do
  LIMIT_FILE="$LIMIT_DIR/$USER"
  if [ ! -f "$LIMIT_FILE" ]; then
    continue
  fi

  LIMIT_IP=$(cat "$LIMIT_FILE")

  # Ambil IP user dari log 1 menit terakhir, potong 2 oktet
  USER_IPS=$(echo "$LOG_RECENT" | grep "email: $USER" | grep -oP 'from \K[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | cut -d'.' -f1,2 | sort -u)
  ACTIVE_COUNT=$(echo "$USER_IPS" | wc -l)

  # Gabungkan IP ke total keseluruhan
  TOTAL_IP_ALL+=($USER_IPS)

  if [ "$ACTIVE_COUNT" -gt "$LIMIT_IP" ]; then
    STATUS="\e[31mMelebihi\e[0m"
  else
    STATUS="\e[32mDalam Batas\e[0m"
  fi

  printf "%-17s %-20s %-12s %b\n" "$USER" "$ACTIVE_COUNT" "$LIMIT_IP" "$STATUS"

  # Tampilkan IP user
  echo -e "  -> IP Aktif (2 Oktet):"
  echo "$USER_IPS" | sed 's/^/     - /'
  echo ""
done

# Hitung total IP aktif semua user (unik)
TOTAL_UNIK=$(printf "%s\n" "${TOTAL_IP_ALL[@]}" | sort -u | wc -l)

echo -e "────────────────────────────────────────────────────────────"
echo -e "Total IP Aktif Unik (2 Oktet) Semua User: \e[34m$TOTAL_UNIK\e[0m"
echo -e "────────────────────────────────────────────────────────────"
echo ""
read -n 1 -s -r -p "   Tekan sembarang tombol untuk kembali ke menu"
menu-trojan
