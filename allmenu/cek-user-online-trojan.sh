#!/bin/bash

log_file="/var/log/xray/access.log"
config_file="/etc/xray/config.json"
limit_dir="/etc/klmpk/limit/trojan/ip"

printf "%-20s %-10s %-10s\n" "Username" "IP Aktif" "Limit IP"
printf "%-40s\n" "-----------------------------------------------"

users=$(grep -oP '"email":\s*"\K[^"]+' "$config_file" | sort -u)

for user in $users; do
    # Ambil semua IP dari log (tcp saja) berdasarkan email
    ips=$(grep "accepted tcp" "$log_file" | grep "email: $user" | grep -oP 'from (\d+\.\d+\.\d+)' | awk '{print $2}')
    
    # Toleransi: anggap IP dari subnet yang sama = 1 device
    ip_subnet=$(echo "$ips" | cut -d'.' -f1-3 | sort | uniq)
    ip_count=$(echo "$ip_subnet" | wc -l)

    if [[ -f "$limit_dir/$user" ]]; then
        limit=$(cat "$limit_dir/$user")
    else
        limit="-"
    fi

    printf "%-20s %-10s %-10s\n" "$user" "$ip_count" "$limit"
done
