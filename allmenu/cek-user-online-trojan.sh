#!/bin/bash

config_file="/etc/xray/config.json"
log_file="/var/log/xray/access.log"
time_limit=60
current_epoch=$(date +%s)

# Warna
RED='\e[31m'
NC='\e[0m'

user_list=$(grep -oP '"email":\s*"\K[^"]+' "$config_file")
declare -A user_ips_subnet

while read -r line; do
    log_time_raw=$(echo "$line" | awk '{print $1" "$2}')
    log_epoch=$(date -d "$log_time_raw" +%s 2>/dev/null)
    [[ -z $log_epoch ]] && continue
    [[ $((current_epoch - log_epoch)) -gt $time_limit ]] && continue

    user=$(echo "$line" | grep -oP 'email:\s*\K\S+')
    ip=$(echo "$line" | grep -oP 'from\s+\K[\d.]+')
    [[ -z $user || -z $ip ]] && continue

    subnet=$(echo "$ip" | cut -d '.' -f 1-3)

    if echo "$user_list" | grep -qw "$user"; then
        user_ips_subnet["$user,$subnet"]=1
    fi
done < "$log_file"

# Output
printf "Menampilkan hasil deteksi user Trojan yang online:\n"
printf "%-20s %-10s %-10s\n" "Username" "IP Aktif" "Limit IP"
printf "%s\n" "-----------------------------------------------"

for user in $(echo "$user_list" | sort -u); do
    count=0
    for key in "${!user_ips_subnet[@]}"; do
        [[ $key == "$user,"* ]] && ((count++))
    done
    if [[ $count -gt 0 ]]; then
        limit_file="/etc/klmpk/limit/trojan/ip/$user"
        [[ -f $limit_file ]] && limit=$(cat "$limit_file") || limit="-"

        if [[ "$limit" =~ ^[0-9]+$ && $count -gt $limit ]]; then
            printf "${RED}%-20s %-10s %-10s${NC}\n" "$user" "$count" "$limit"
        else
            printf "%-20s %-10s %-10s\n" "$user" "$count" "$limit"
        fi
    fi
done
