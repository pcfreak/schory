#!/bin/bash

log="/var/log/xray/access.log"
limit_dir="/etc/klmpk/limit/trojan/ip"
now=$(date +%s)

declare -A user_ips
declare -A user_ip_count
declare -A user_limit

while IFS= read -r line; do
    [[ "$line" =~ email:\ ([^[:space:]]+) ]] || continue
    user="${BASH_REMATCH[1]}"

    [[ "$line" =~ from\ ([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+):([0-9]+) ]] || continue
    ip="${BASH_REMATCH[1]}"
    port="${BASH_REMATCH[2]}"

    # Hanya hitung port 443
    [[ "$port" != "443" ]] && continue

    # Waktu log
    log_time=$(echo "$line" | awk '{print $1" "$2}')
    log_epoch=$(date -d "$log_time" +%s 2>/dev/null)
    [[ -z "$log_epoch" ]] && continue

    ((now - log_epoch > 60)) && continue

    # Ambil tiga oktet pertama dari IP (misalnya 192.168.1)
    ip_prefix=$(echo "$ip" | awk -F. '{print $1"."$2"."$3}')

    user_ips["$user,$ip_prefix"]=1
done < "$log"

# Hitung IP aktif
for key in "${!user_ips[@]}"; do
    IFS=',' read -r user ip_prefix <<< "$key"
    ((user_ip_count["$user"]++))
done

# Ambil limit
for user in $(ls "$limit_dir"); do
    limit=$(cat "$limit_dir/$user" 2>/dev/null)
    user_limit["$user"]=$limit
done

# Output
echo -e "\nMenampilkan hasil deteksi user Trojan yang online:"
printf "%-20s %-10s %-10s\n" "Username" "IP Aktif" "Limit IP"
echo "-----------------------------------------------"

for user in "${!user_ip_count[@]}"; do
    count=${user_ip_count["$user"]}
    limit=${user_limit["$user"]:-0}

    if (( count > 0 )); then
        if (( count > limit && limit > 0 )); then
            printf "\e[31m%-20s %-10s %-10s\e[0m\n" "$user" "$count" "$limit"
        else
            printf "%-20s %-10s %-10s\n" "$user" "$count" "$limit"
        fi
    fi
done
