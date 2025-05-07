#!/bin/bash

log_file="/var/log/xray/access.log"
config_file="/etc/xray/config.json"
limit_dir="/etc/klmpk/limit/trojan/ip"

printf "%-20s %-10s %-10s\n" "Username" "IP Aktif" "Limit IP"
printf "%-40s\n" "-----------------------------------------------"

# Waktu 5 menit terakhir
time_limit=$(date -d "5 minutes ago" +%s)

users=$(grep -oP '"email":\s*"\K[^"]+' "$config_file" | sort -u)

for user in $users; do
    declare -A ip_map=()
    found_active=0

    while IFS= read -r line; do
        [[ "$line" =~ email:\ $user ]] || continue
        [[ "$line" =~ accepted\ tcp ]] || continue

        log_time=$(echo "$line" | awk '{print $1 " " $2}')
        log_unix=$(date -d "$log_time" +%s 2>/dev/null)
        [[ "$log_unix" =~ ^[0-9]+$ ]] || continue

        (( log_unix < time_limit )) && continue

        ip=$(echo "$line" | grep -oP 'from \K[0-9]+\.[0-9]+\.[0-9]+')
        ip_map["$ip"]=1
        found_active=1
    done < "$log_file"

    if [[ $found_active -eq 1 ]]; then
        ip_count=${#ip_map[@]}
        limit="-"
        [[ -f "$limit_dir/$user" ]] && limit=$(cat "$limit_dir/$user")
        printf "%-20s %-10s %-10s\n" "$user" "$ip_count" "$limit"
    fi

    unset ip_map
done
