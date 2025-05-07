#!/bin/bash

# Konfigurasi
LOG_FILE="/var/log/xray/access.log"
LIMIT_DIR="/etc/klmpk/limit/trojan/ip"

# Ambil semua username dari config
USER_LIST=$(grep -oP '"password":\s*"\K[^"]+' /etc/xray/config.json)

# Header
echo -e "=========================================================="
echo -e "             MONITOR TROJAN ONLINE (Akurat)"
echo -e "=========================================================="
printf "%-20s %-10s %-10s\n" "Username" "IP Aktif" "Limit IP"
echo -e "----------------------------------------------------------"

for user in $USER_LIST; do
    # Ambil IP unik dari log dengan mencocokkan username setelah "email:"
    IP_LIST=$(grep "email: $user" "$LOG_FILE" | awk '{for(i=1;i<=NF;i++) if($i=="from") print $(i+1)}' | cut -d':' -f1 | sort -u)
    IP_COUNT=$(echo "$IP_LIST" | grep -v '^$' | wc -l)

    # Ambil limit
    LIMIT_FILE="${LIMIT_DIR}/${user}"
    if [[ -f "$LIMIT_FILE" ]]; then
        LIMIT=$(cat "$LIMIT_FILE")
    else
        LIMIT="-"
    fi

    if [[ "$IP_COUNT" -gt 0 ]]; then
        printf "%-20s %-10s %-10s\n" "$user" "$IP_COUNT" "$LIMIT"
    fi
done

echo -e "=========================================================="
