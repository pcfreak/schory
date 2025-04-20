#!/bin/bash

# === Konfigurasi ===
KUOTA_DIR="/etc/klmpk/limit/ssh/kuota"
LOG_FILE="/var/log/limit-kuota.log"

# Pastikan direktori kuota ada
if [[ ! -d "$KUOTA_DIR" ]]; then
    echo "$(date '+%F %T') - ERROR: Direktori kuota tidak ditemukan" >> "$LOG_FILE"
    exit 1
fi

# Logging waktu eksekusi
echo "$(date '+%F %T') - monitor-kuota.sh dijalankan" >> "$LOG_FILE"

# Fungsi untuk dapatkan total data RX+TX user dari /proc
get_usage_bytes() {
    local user="$1"
    local total=0
    for pid in $(pgrep -u "$user"); do
        if [[ -f "/proc/$pid/net/dev" ]]; then
            while read -r line; do
                [[ "$line" == *:* ]] || continue
                local rx tx
                rx=$(echo "$line" | awk -F: '{print $2}' | awk '{print $1}')
                tx=$(echo "$line" | awk -F: '{print $2}' | awk '{print $9}')
                total=$((total + rx + tx))
            done < "/proc/$pid/net/dev" 2>/dev/null
        fi
    done
    echo "$total"
}

# Loop pengecekan
for file in "$KUOTA_DIR"/*-limit; do
    user=$(basename "$file" | cut -d'-' -f1)
    [[ -z "$user" ]] && continue

    # Limit dalam MB, konversi ke byte
    limit_mb=$(cat "$file" 2>/dev/null)
    [[ ! "$limit_mb" =~ ^[0-9]+$ ]] && continue
    limit_bytes=$((limit_mb * 1024 * 1024))

    used_file="$KUOTA_DIR/${user}-used"
    [[ ! -f "$used_file" ]] && echo 0 > "$used_file"

    usage_now=$(get_usage_bytes "$user")
    usage_before=$(cat "$used_file" 2>/dev/null)
    total_usage=$((usage_before + usage_now))
    echo "$total_usage" > "$used_file"

    if [[ "$total_usage" -ge "$limit_bytes" ]]; then
        pkill -KILL -u "$user" && usermod -L "$user"
        echo "$(date '+%F %T') - User '$user' melebihi kuota (${total_usage} bytes / ${limit_bytes} bytes) - akun dikunci" >> "$LOG_FILE"
    fi
done
