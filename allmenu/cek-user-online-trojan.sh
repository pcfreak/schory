#!/bin/bash

# File konfigurasi Xray
config_file="/etc/xray/config.json"
log_file="/var/log/xray/access.log"

# Batas waktu log (60 detik terakhir)
time_limit=60
current_epoch=$(date +%s)

# Ambil daftar user (email)
user_list=$(grep -oP '"email":\s*"\K[^"]+' "$config_file")

# Inisialisasi hasil akhir
declare -A user_ips

# Parsing log access
while read -r line; do
    log_time_raw=$(echo "$line" | awk '{print $1" "$2}')
    log_epoch=$(date -d "$log_time_raw" +%s 2>/dev/null)
    
    # Lewati jika parsing waktu gagal atau log terlalu lama
    [[ -z $log_epoch ]] && continue
    [[ $((current_epoch - log_epoch)) -gt $time_limit ]] && continue

    # Ambil IP dan username
    user=$(echo "$line" | grep -oP 'email:\s*\K\S+')
    ip=$(echo "$line" | grep -oP 'from\s+\K[\d.]+')

    [[ -z $user || -z $ip ]] && continue

    # Gunakan subnet /24
    subnet=$(echo "$ip" | cut -d '.' -f 1-3)

    # Jika user ada di daftar dan subnet belum dicatat, simpan
    if echo "$user_list" | grep -qw "$user"; then
        key="$user|$subnet"
        [[ -z ${user_ips[$key]} ]] && user_ips["$key"]="$ip"
    fi
done < "$log_file"

# Tampilkan hasil
printf "Menampilkan hasil deteksi user Trojan yang online:\n"
printf "%-20s %-10s %-10s\n" "Username" "IP Aktif" "Limit IP"
printf "%s\n" "-----------------------------------------------"

for user in $user_list; do
    count=0
    for key in "${!user_ips[@]}"; do
        [[ $key == "$user|"* ]] && ((count++))
    done
    if [[ $count -gt 0 ]]; then
        limit_file="/etc/klmpk/limit/trojan/ip/$user"
        [[ -f $limit_file ]] && limit=$(cat "$limit_file") || limit="-"
        printf "%-20s %-10s %-10s\n" "$user" "$count" "$limit"
    fi
done
