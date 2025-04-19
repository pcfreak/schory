#!/bin/bash

LIMIT_DIR="/etc/klmpk/limit/ssh/quota"
USAGE_DIR="/etc/klmpk/limit/ssh/usage"

mkdir -p "$LIMIT_DIR" "$USAGE_DIR"

while true; do
    users=$(ls $LIMIT_DIR)
    for user in $users; do
        if id "$user" &>/dev/null; then
            # Ambil limit kuota (dalam MB)
            limit=$(cat "$LIMIT_DIR/$user")
            usage_file="$USAGE_DIR/$user"

            # Ambil total bytes digunakan oleh user (TX+RX)
            used=$(grep "$user" /proc/net/dev | awk '{tx+=$10; rx+=$2} END {print tx+rx}')
            
            # Jika file penggunaan belum ada, inisialisasi
            if [ ! -f "$usage_file" ]; then
                echo "$used" > "$usage_file"
                continue
            fi

            start=$(cat "$usage_file")
            total_used=$(( (used - start) / 1024 / 1024 )) # MB

            if (( total_used >= limit )); then
                pkill -KILL -u "$user"
                echo "User $user melebihi kuota (${limit}MB), koneksi dihentikan."
            fi
        fi
    done
    sleep 60
done
