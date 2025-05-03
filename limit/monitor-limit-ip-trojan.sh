#!/bin/bash

LOG_FILE="/var/log/xray/access.log"
LIMIT_DIR="/etc/klmpk/limit/trojan/ip"
TMP_DIR="/tmp/limit-ip-trojan"

mkdir -p $TMP_DIR

# Proses tiap user yang punya limit
for limit_file in ${LIMIT_DIR}/*; do
    user=$(basename "$limit_file")
    limit=$(cat "$limit_file")
    
    # Ambil semua IP yang sedang terhubung dari log Xray
    ips=$(grep -w "$user" "$LOG_FILE" | awk '{print $3}' | cut -d: -f1 | sort -u)
    
    ip_count=$(echo "$ips" | wc -l)
    
    if [[ "$ip_count" -gt "$limit" ]]; then
        echo "User $user melebihi limit IP ($ip_count/$limit), disconnect atau disable akun"
        
        # Contoh disable user (hapus dari config)
        sed -i "/^#trojan $user$/,/^},{/d" /etc/xray/config.json
        
        # Restart Xray agar config baru berlaku
        systemctl restart xray
    fi
done
