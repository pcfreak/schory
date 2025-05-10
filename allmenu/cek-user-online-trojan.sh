#!/bin/bash

LIMIT_DIR="/etc/klmpk/limit/trojan/ip"
LOG_FILE="/var/log/xray/access.log"

# Ambil semua user unik yang aktif
USERS=$(grep -oP '(?<=email: )[^\s]+' "$LOG_FILE" | sort | uniq)

if [ -z "$USERS" ]; then
  echo "Tidak ada user Trojan yang aktif ditemukan di log Xray."
  exit 1
fi

clear
echo -e "────────────────────────────────────────────────────────────"
echo -e "             • TROJAN ONLINE NOW (Last 5 Min) •             "
echo -e "────────────────────────────────────────────────────────────"
echo ""
echo -e "USERNAME         IP AKTIF (2 Oktet)   LIMIT IP     STATUS"
echo -e "────────────────────────────────────────────────────────────"

for USER in $USERS; do
  LIMIT_FILE="$LIMIT_DIR/$USER"
  if [ ! -f "$LIMIT_FILE" ]; then
    continue
  fi

  LIMIT_IP=$(cat "$LIMIT_FILE")

  ACTIVE_COUNT=$(grep "email: $USER" "$LOG_FILE" \
    | grep -oP 'from \K[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' \
    | cut -d'.' -f1,2 \
    | sort -u | wc -l)

  if [ "$ACTIVE_COUNT" -gt "$LIMIT_IP" ]; then
    STATUS="\e[31mMelebihi\e[0m"
  else
    STATUS="\e[32mDalam Batas\e[0m"
  fi

  printf "%-17s %-20s %-12s %b\n" "$USER" "$ACTIVE_COUNT" "$LIMIT_IP" "$STATUS"
done

echo -e "────────────────────────────────────────────────────────────"
echo ""
read -n 1 -s -r -p "   Tekan sembarang tombol untuk kembali ke menu"
menu-trojan
