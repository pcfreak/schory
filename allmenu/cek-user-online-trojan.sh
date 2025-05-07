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
    echo -e "Memeriksa user: $user"
    
    # Ambil semua IP yang login dengan koneksi TCP berdasarkan username
    IP_LIST=$(grep "email: $user" "$LOG_FILE" | grep -oP 'from tcp:[^ ]+' | cut -d':' -f2 | sort -u)

    echo -e "IP List untuk user $user: $IP_LIST"
    
    IP_COUNT=$(echo "$IP_LIST" | grep -v '^$' | wc -l)

    echo -e "Jumlah IP yang ditemukan: $IP_COUNT"

    # Baca limit IP user dari file
    LIMIT_FILE="${LIMIT_DIR}/${user}"
    if [[ -f "$LIMIT_FILE" ]]; then
        LIMIT=$(cat "$LIMIT_FILE")
    else
        LIMIT="-"
    fi

    echo -e "Limit IP untuk user $user: $LIMIT"

    # Tampilkan jika ada aktivitas
    if [[ "$IP_COUNT" -gt 0 ]]; then
        printf "%-20s %-10s %-10s\n" "$user" "$IP_COUNT" "$LIMIT"
    fi
done

echo -e "=========================================================="
