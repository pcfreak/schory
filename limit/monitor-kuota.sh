#!/bin/bash

KUOTA_DIR="/etc/klmpk/limit/ssh/kuota"
LOG_FILE="/var/log/limit-kuota.log"

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

echo "$(date '+%F %T') - monitor-kuota.sh dijalankan" >> "$LOG_FILE"

for file in "$KUOTA_DIR"/*-limit; do
    user=$(basename "$file" | cut -d'-' -f1)
    [[ -z "$user" ]] && continue

    limit_mb=$(cat "$file")
    limit_bytes=$(( limit_mb * 1024 * 1024 ))

    base_file="$KUOTA_DIR/${user}-base"
    [[ ! -f "$base_file" ]] && echo 0 > "$base_file"

    usage_now=$(get_usage_bytes "$user")
    base=$(cat "$base_file")
    usage_total=$(( usage_now - base ))

    if [[ "$usage_total" -lt 0 ]]; then
        usage_total=0
        echo 0 > "$base_file"
    fi

    if [[ "$usage_total" -ge "$limit_bytes" ]]; then
        pkill -KILL -u "$user"
        usermod -L "$user"
        echo "$(date '+%F %T') - User '$user' melewati limit ($usage_total / $limit_bytes bytes) - akun dikunci" >> "$LOG_FILE"
    fi
done
