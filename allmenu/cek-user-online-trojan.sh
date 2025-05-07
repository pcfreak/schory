#!/bin/bash

# File log akses Xray
LOG_FILE="/var/log/xray/access.log"

# Direktori limit IP per user
LIMIT_DIR="/etc/klmpk/limit/trojan/ip"

# Ambil semua username dari config.json
USER_LIST=$(grep '"email"' /etc/xray/config.json | cut -d':' -f2 | tr -d '", ' | sort -u)

# Header tampilan
echo -e "=========================================================="
echo -e "             MONITOR TROJAN ONLINE (Akurat)"
echo -e "=========================================================="
printf "%-20s %-10s %-10s\n" "Username" "IP Aktif" "Limit IP"
echo -e "----------------------------------------------------------"

for user in $USER_LIST; do
    # Ambil semua IP yang login berdasarkan username
    IP_LIST=$(grep "email: $user" "$LOG_FILE" | grep -oP 'from \K[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+')
    IP_COUNT=$(echo "$IP_LIST" | sort -u | grep -v '^$' | wc -l)

    # Baca limit IP user dari file
    LIMIT_FILE="${LIMIT_DIR}/${user}"
    if [[ -f "$LIMIT_FILE" ]]; then
        LIMIT=$(cat "$LIMIT_FILE")
    else
        LIMIT="-"
    fi

    # Tampilkan jika ada aktivitas
    if [[ "$IP_COUNT" -gt 0 ]]; then
        printf "%-20s %-10s %-10s\n" "$user" "$IP_COUNT" "$LIMIT"
    fi
done

echo -e "=========================================================="
