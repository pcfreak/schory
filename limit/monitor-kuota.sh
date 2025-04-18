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

# Loop pengecekan per user
for file in "$KUOTA_DIR"/*-limit; do
    user=$(basename "$file" | cut -d'-' -f1)
    [[ -z "$user" ]] && continue

    # Skip jika user tidak ada di sistem
    id "$user" &>/dev/null || continue

    # Ambil limit kuota dari file dalam MB
    limit_mb=$(cat "$file" 2>/dev/null)
    [[ ! "$limit_mb" =~ ^[0-9]+$ ]] && continue

    # Tidak perlu konversi lagi, tetap pakai MB
    limit=$limit_mb  # Limit dalam MB

    used_file="$KUOTA_DIR/${user}-used"
    last_file="$KUOTA_DIR/${user}-last"

    # Jika file used tidak ada, buat dengan nilai 0
    [[ ! -f "$used_file" ]] && echo 0 > "$used_file"

    # Ambil penggunaan saat ini
    usage_now=$(get_usage_bytes "$user")
    [[ ! -f "$last_file" ]] && echo "$usage_now" > "$last_file"

    # Hitung selisih dengan nilai terakhir
    last_usage=$(cat "$last_file")
    delta=$((usage_now - last_usage))
    [[ "$delta" -lt 0 ]] && delta=0

    usage_before=$(cat "$used_file")
    total_usage=$((usage_before + delta))

    # Simpan nilai penggunaan saat ini dan total penggunaan
    echo "$usage_now" > "$last_file"
    echo "$total_usage" > "$used_file"

    # Hitung penggunaan dalam MB untuk ditampilkan
    usage_disp=$(awk "BEGIN {printf \"%.2f\", $total_usage / 1024 / 1024}")

    # Cek jika total penggunaan melebihi limit
    if (( total_usage / 1024 / 1024 >= limit )); then
        pkill -KILL -u "$user"
        usermod -L "$user"
        chmod 000 /home/"$user" &>/dev/null
        echo "$(date '+%F %T') - User '$user' melebihi kuota (${usage_disp} MB / ${limit} MB) - akun dikunci" >> "$LOG_FILE"
    fi
done
