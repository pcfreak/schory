#!/bin/bash

# Konfigurasi
LOG_FILE="/var/log/xray/access.log"
LIMIT_DIR="/etc/klmpk/limit/trojan/ip"
PORT_TROJAN="443"  # default trojan

# Ambil daftar user trojan dari config.json (asumsi field password)
USER_LIST=$(grep -oP '"password":\s*"\K[^"]+' /etc/xray/config.json)

# Header
echo -e "=========================================================="
echo -e "             MONITOR TROJAN ONLINE (Port $PORT_TROJAN)"
echo -e "=========================================================="
printf "%-20s %-10s %-10s\n" "Username" "IP Aktif" "Limit IP"
echo -e "----------------------------------------------------------"

for user in $USER_LIST; do
    # Ambil baris log untuk user dengan port 443
    LOG_MATCH=$(grep -w "$user" "$LOG_FILE" | grep ":$PORT_TROJAN")

    # Ambil IP unik dari log
    IP_LIST=$(echo "$LOG_MATCH" | awk '{print $3}' | cut -d':' -f1 | sort -u)
    IP_COUNT=$(echo "$IP_LIST" | grep -v '^$' | wc -l)

    # Ambil limit IP
    LIMIT_FILE="${LIMIT_DIR}/${user}"
    if [[ -f "$LIMIT_FILE" ]]; then
        LIMIT=$(cat "$LIMIT_FILE")
    else
        LIMIT="-"
    fi

    # Tampilkan jika user aktif
    if [[ "$IP_COUNT" -gt 0 ]]; then
        printf "%-20s %-10s %-10s\n" "$user" "$IP_COUNT" "$LIMIT"
    fi
done

echo -e "=========================================================="
