#!/bin/bash

KUOTA_DIR="/etc/klmpk/limit/ssh/kuota"
LOG_FILE="/var/log/limit-kuota.log"

[[ ! -d "$KUOTA_DIR" ]] && echo "$(date '+%F %T') - ERROR: Direktori kuota tidak ditemukan" >> "$LOG_FILE" && exit 1

echo "$(date '+%F %T') - monitor-kuota.sh dijalankan" >> "$LOG_FILE"

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

for file in "$KUOTA_DIR"/*-limit; do
    user=$(basename "$file" | cut -d'-' -f1)
    [[ -z "$user" ]] && continue

    limit_mb=$(cat "$file" 2>/dev/null)
    [[ ! "$limit_mb" =~ ^[0-9]+$ ]] && continue
    limit_bytes=$((limit_mb * 1024 * 1024))

    base_file="$KUOTA_DIR/${user}-base"
    [[ ! -f "$base_file" ]] && get_usage_bytes "$user" > "$base_file"

    usage_now=$(get_usage_bytes "$user")
    usage_base=$(cat "$base_file" 2>/dev/null)
    diff_usage=$((usage_now - usage_base))

    if [[ "$diff_usage" -ge "$limit_bytes" ]]; then
        pkill -KILL -u "$user" && usermod -L "$user"
        echo "$(date '+%F %T') - User '$user' melebihi kuota ($((diff_usage / 1024 / 1024)) MB / $limit_mb MB) - akun dikunci" >> "$LOG_FILE"
    fi
done
