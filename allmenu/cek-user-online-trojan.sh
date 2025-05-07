#!/bin/bash

LOG_FILE="/var/log/xray/access.log"
LIMIT_DIR="/etc/klmpk/limit/trojan/ip"

# Ambil semua username dari log TCP
USER_LIST=$(grep "email:" "$LOG_FILE" | grep "from " | grep "accepted tcp:" | awk '{for(i=1;i<=NF;i++){if($i=="email:"){print $(i+1)}}}' | sort -u)

# Header
printf "%-20s %-10s %-10s\n" "Username" "IP Aktif" "Limit IP"
echo "-----------------------------------------------"

for user in $USER_LIST; do
    # Ambil semua IP unik dari log TCP user
    IP_LIST=$(grep "email: $user" "$LOG_FILE" | grep "accepted tcp:" | grep "from " | awk '{for(i=1;i<=NF;i++){if($i=="from"){print $(i+1)}}}' | cut -d: -f1 | sort -u)
    IP_COUNT=$(echo "$IP_LIST" | grep -c .)

    # Ambil limit dari file (jika ada)
    LIMIT_FILE="${LIMIT_DIR}/${user}"
    [[ -f "$LIMIT_FILE" ]] && LIMIT=$(cat "$LIMIT_FILE") || LIMIT="-"

    # Output
    printf "%-20s %-10s %-10s\n" "$user" "$IP_COUNT" "$LIMIT"
done
