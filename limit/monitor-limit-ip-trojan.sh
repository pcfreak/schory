#!/bin/bash

LOG_FILE="/var/log/xray/access.log"
LIMIT_DIR="/etc/klmpk/limit/trojan/ip"

# Loop terus menerus
while true; do
    for limit_file in ${LIMIT_DIR}/*; do
        [[ -f "$limit_file" ]] || continue
        user=$(basename "$limit_file")
        limit=$(cat "$limit_file")

        # Ambil semua IP aktif dari log (gunakan grep dan sort unik)
        ips=$(grep -w "$user" "$LOG_FILE" | awk '{print $3}' | cut -d: -f1 | sort -u)
        ip_count=$(echo "$ips" | wc -l)

        if [[ "$ip_count" -gt "$limit" ]]; then
            echo "$(date) - User $user melebihi limit IP ($ip_count/$limit), menonaktifkan akun"

            # Hapus dari config.json bagian trojanws dan trojangrpc
            sed -i "/^#.*$user $/,/^},{/d" /etc/xray/config.json

            # Hapus limit
            rm -f "$limit_file"

            # Restart Xray agar perubahan berlaku
            systemctl restart xray
        fi
    done
    sleep 60
done
