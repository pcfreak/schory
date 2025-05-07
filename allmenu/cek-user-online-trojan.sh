#!/bin/bash

log_file="/var/log/xray/access.log"
config_file="/etc/xray/config.json"
limit_dir="/etc/klmpk/limit/trojan/ip"

printf "%-20s %-10s %-10s\n" "Username" "IP Aktif" "Limit IP"
printf "%-40s\n" "-----------------------------------------------"

# Ambil semua user trojan dari config
users=$(grep -oP '"password":\s*"\K[^"]+' "$config_file")

for user in $users; do
    # Ambil semua IP tcp user dari log (tanpa port)
    ips=$(grep "accepted tcp" "$log_file" | grep "email: $user" | grep -oP 'from (\d+\.\d+\.\d+)' | awk '{print $2}')
    
    # Hitung IP unik berdasarkan 3 oktet pertama
    ip_subnets=$(echo "$ips" | cut -d'.' -f1-3 | sort -u)
    ip_count=$(echo "$ip_subnets" | wc -l)

    # Ambil limit IP jika ada
    if [[ -f "$limit_dir/$user" ]]; then
        limit=$(cat "$limit_dir/$user")
    else
        limit="-"
    fi

    printf "%-20s %-10s %-10s\n" "$user" "$ip_count" "$limit"
done
