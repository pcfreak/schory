#!/bin/bash

# === Konfigurasi ===
KUOTA_DIR="/etc/klmpk/limit/ssh/kuota"
LOG_FILE="/var/log/limit-kuota.log"

# Pastikan direktori kuota ada
[[ ! -d "$KUOTA_DIR" ]] && exit 1

# Fungsi untuk dapatkan total data RX+TX user dari ifconfig / dev
get_usage_bytes() {
    user="$1"
    total=0
    # Ambil semua PID user, lalu total trafiknya dari /proc
    for pid in $(pgrep -u "$user"); do
        if [[ -d "/proc/$pid/net/dev" || -f "/proc/$pid/net/dev" ]]; then
            while read -r line; do
                [[ "$line" == *:* ]] || continue
                rx=$(echo "$line" | awk -F: '{print $2}' | awk '{print $1}')
                tx=$(echo "$line" | awk -F: '{print $2}' | awk '{print $9}')
                total=$((total + rx + tx))
            done < /proc/$pid/net/dev 2>/dev/null
        fi
    done
    echo "$total"
}

# Loop pengecekan
while true; do
    for file in "$KUOTA_DIR"/*-limit; do
        user=$(basename "$file" | cut -d'-' -f1)
        [[ -z "$user" ]] && continue

        limit=$(cat "$file" 2>/dev/null)
        used_file="$KUOTA_DIR/${user}-used"

        [[ ! "$limit" =~ ^[0-9]+$ ]] && continue

        # Inisialisasi file used
        [[ ! -f "$used_file" ]] && echo 0 > "$used_file"

        # Dapatkan penggunaan saat ini
        usage_now=$(get_usage_bytes "$user")
        usage_before=$(cat "$used_file" 2>/dev/null)
        total_usage=$((usage_before + usage_now))

        echo "$total_usage" > "$used_file"

        # Cek apakah melebihi limit
        if [[ "$total_usage" -ge "$limit" ]]; then
            pkill -KILL -u "$user"
            usermod -L "$user"
            echo "$(date '+%Y-%m-%d %H:%M:%S') - User '$user' melebihi kuota ($total_usage / $limit bytes) - akun dikunci" >> "$LOG_FILE"
        fi
    done

    sleep 60
done
