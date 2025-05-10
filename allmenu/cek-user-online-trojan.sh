#!/bin/bash

LIMIT_DIR="/etc/klmpk/limit/trojan/ip"
LOG_FILE="/var/log/xray/access.log"

# Ambil log 1 menit terakhir
RECENT_LOG=$(awk -v date="$(date --date='1 minute ago' '+%Y/%m/%d %H:%M')" '$0 > date' "$LOG_FILE")

# Ambil daftar user aktif dari log
USERS=$(echo "$RECENT_LOG" | grep -oP 'email: \K[^\s]+' | sort -u)

if [ -z "$USERS" ]; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Tidak ada user Trojan yang aktif dalam 1 menit terakhir."
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  exit 0
fi

TOTAL_IP=0

echo "──────────────────────────────────────────────────────────────"
echo "              • TROJAN ONLINE NOW (Last 1 Min) •              "
echo "──────────────────────────────────────────────────────────────"
printf "%-15s %-15s %-15s %-10s\n" "USERNAME" "IP AKTIF" "LIMIT IP" "STATUS"
echo "──────────────────────────────────────────────────────────────"

for USER in $USERS; do
  LIMIT_FILE="$LIMIT_DIR/$USER"

  if [ ! -f "$LIMIT_FILE" ]; then
    LIMIT_IP=0
  else
    LIMIT_IP=$(cat "$LIMIT_FILE")
  fi

  # Ambil IP 3 oktet dari user
  USER_IPS=$(echo "$RECENT_LOG" | grep "email: $USER" | grep -oP 'from \K[0-9]+\.[0-9]+\.[0-9]+' | sort -u)
  IP_COUNT=$(echo "$USER_IPS" | wc -l)
  TOTAL_IP=$((TOTAL_IP + IP_COUNT))

  STATUS=$(if [ "$IP_COUNT" -gt "$LIMIT_IP" ]; then echo -e "\e[31mMelebihi\e[0m"; else echo "Dalam Batas"; fi)

  printf "%-15s %-15s %-15s %-10b\n" "$USER" "$IP_COUNT" "$LIMIT_IP" "$STATUS"
  
  # Tampilkan IP yang terdeteksi (3 oktet)
  echo "  # IP Aktif (3 Oktet):"
  echo "$USER_IPS" | sed 's/^/   - /'
  echo ""
done

echo "──────────────────────────────────────────────────────────────"
echo "Total IP aktif terdeteksi (3 oktet): $TOTAL_IP"
echo "──────────────────────────────────────────────────────────────"
read -n 1 -s -r -p "   Tekan sembarang tombol untuk kembali ke menu"
menu-trojan
