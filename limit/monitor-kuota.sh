#!/bin/bash

LIMIT_DIR="/etc/klmpk/limit/ssh/kuota"
LOG_FILE="/var/log/limit-kuota.log"
INTERFACE="eth0"  # Ganti dengan interface jaringan yang digunakan

# Cek semua user yang memiliki limit
for file in $LIMIT_DIR/*-limit; do
    user=$(basename "$file" | cut -d'-' -f1)
    limit=$(cat "$file")  # Limit dalam MB
    used_file="$LIMIT_DIR/${user}-used"

    # Jika belum ada file used, inisialisasi 0
    [[ ! -f $used_file ]] && echo 0 > "$used_file"

    # Menggunakan nethogs untuk monitoring per user
    total=$(nethogs -t -v1 $INTERFACE | grep "$user" | awk '{sum += $2} END {print sum}')

    # Jika total tidak ada, maka user belum ada traffic
    if [[ -z "$total" ]]; then
        total=0
    fi

    # Hitung penggunaan dalam MB (bukan GB)
    new_usage=$(echo "$total / 1024 / 1024" | bc)  # Convert bytes to MB

    # Tambahkan usage baru ke existing usage
    current=$(cat "$used_file")
    updated=$(echo "$current + $new_usage" | bc)

    echo "$updated" > "$used_file"

    # Bandingkan dengan limit (dalam MB)
    if (( $(echo "$updated >= $limit" | bc -l) )); then
        usermod -L $user 2>/dev/null
        pkill -u $user 2>/dev/null
        echo "$(date '+%F %T') - User $user melebihi kuota: ${updated}MB/${limit}MB - account locked" >> "$LOG_FILE"
    fi
done
