#!/bin/bash

log_file="/var/log/xray/access.log"
config_file="/etc/xray/config.json"
limit_dir="/etc/klmpk/limit/trojan/ip" # Ganti sesuai lokasi penyimpanan limit IP

# Ambil daftar user dari config Xray
user_list=$(grep -oP '"password":\s*"\K[^"]+' "$config_file")

# Ambil timestamp 1 menit terakhir dari log
cutoff=$(date -d "1 minute ago" +"%Y/%m/%d %H:%M")

# Associative array
declare -A ip_map user_active_ip

# Proses log yang 1 menit terakhir
while IFS= read -r line; do
    timestamp=$(echo "$line" | cut -d ' ' -f1,2)
    [[ "$timestamp" < "$cutoff" ]] && continue

    # Ambil user dan IP dari log
    user=$(echo "$line" | grep -oP 'email:\s*\K\S+')
    [[ -z "$user" ]] && continue

    ip=$(echo "$line" | grep -oP 'from (\d{1,3}\.){3}\d{1,3}' | cut -d ' ' -f2)
    subnet=$(echo "$ip" | cut -d '.' -f1-3) # subnet /24
    [[ -z "$subnet" ]] && continue

    # Hanya simpan IP yang aktif dalam waktu 1 menit terakhir
    ip_map["$user:$subnet"]=1
    user_active_ip["$user"]=1
done < <(grep "email:" "$log_file")

# Tampilkan output
echo "Menampilkan hasil deteksi user Trojan yang online:"
printf "%-20s %-10s %-10s\n" "Username" "IP Aktif" "Limit IP"
printf "%s\n" "-----------------------------------------------"

for user in $user_list; do
    [[ -z "${user_active_ip[$user]}" ]] && continue # Skip user tidak aktif

    # Hitung IP unik berdasarkan subnet
    ip_count=$(printf "%s\n" "${!ip_map[@]}" | grep "^$user:" | wc -l)

    # Cek limit dari file (jika ada)
    limit_file="$limit_dir/$user"
    if [[ -f $limit_file ]]; then
        limit=$(cat "$limit_file")
    else
        limit="-"
    fi

    # Tampilkan hasil deteksi IP aktif dan limit IP
    printf "%-20s %-10s %-10s\n" "$user" "$ip_count" "$limit"
done
