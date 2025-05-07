#!/bin/bash

log_file="/var/log/xray/access.log"
config_file="/etc/xray/config.json"
limit_dir="/etc/klmpk/limit/trojan/ip" # Ubah sesuai path penyimpanan limit IP

# Waktu cutoff 60 detik lalu dalam epoch
cutoff_epoch=$(date -d "60 seconds ago" +%s)

# Ambil daftar user dari config Xray
user_list=$(grep -oP '"password":\s*"\K[^"]+' "$config_file")

declare -A user_ips user_online

# Baca log dan proses baris dengan email
grep "email:" "$log_file" | while read -r line; do
    # Ambil timestamp dari log, format: YYYY/MM/DD HH:MM:SS
    ts_raw=$(echo "$line" | grep -oP '^\d{4}/\d{2}/\d{2} \d{2}:\d{2}:\d{2}')
    [[ -z "$ts_raw" ]] && continue

    ts_epoch=$(date -d "$ts_raw" +%s 2>/dev/null)
    [[ $? -ne 0 ]] && continue
    [[ $ts_epoch -lt $cutoff_epoch ]] && continue

    # Ambil user (email) dan IP
    user=$(echo "$line" | grep -oP 'email:\s*\K\S+')
    ip=$(echo "$line" | grep -oP 'from (\d{1,3}\.){3}\d{1,3}' | awk '{print $2}')
    subnet=$(echo "$ip" | cut -d '.' -f1-3)

    [[ -z "$user" || -z "$subnet" ]] && continue

    user_ips["$user,$subnet"]=1
    user_online["$user"]=1
done

# Output
echo "Menampilkan hasil deteksi user Trojan yang online:"
printf "%-20s %-10s %-10s\n" "Username" "IP Aktif" "Limit IP"
printf "%s\n" "-----------------------------------------------"

for user in $user_list; do
    [[ -z "${user_online[$user]}" ]] && continue

    # Hitung jumlah subnet aktif
    count=$(printf "%s\n" "${!user_ips[@]}" | grep "^$user," | wc -l)

    # Ambil limit IP
    limit_file="$limit_dir/$user"
    if [[ -f $limit_file ]]; then
        limit=$(cat "$limit_file")
    else
        limit="-"
    fi

    printf "%-20s %-10s %-10s\n" "$user" "$count" "$limit"
done
