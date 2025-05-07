#!/bin/bash

log="/var/log/xray/access.log"
limit_dir="/etc/klmpk/limit/trojan/ip"
now=$(date +%s)

declare -A user_ips
declare -A user_ip_count
declare -A user_limit

# Baca log 1 menit terakhir
while IFS= read -r line; do
    [[ "$line" =~ email:\ ([^[:space:]]+) ]] || continue
    user="${BASH_REMATCH[1]}"

    [[ "$line" =~ from\ ([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+): ]] || continue
    ip="${BASH_REMATCH[1]}"

    # Ambil waktu log
    log_time=$(echo "$line" | awk '{print $1" "$2}')
    log_epoch=$(date -d "$log_time" +%s 2>/dev/null)
    [[ -z "$log_epoch" ]] && continue

    # Jika lebih dari 1 menit, skip
    ((now - log_epoch > 60)) && continue

    # Simpan IP per user (IP unik penuh)
    user_ips["$user,$ip"]=1
done < "$log"

# Hitung IP aktif per user
for key in "${!user_ips[@]}"; do
    IFS=',' read -r user ip <<< "$key"
    ((user_ip_count["$user"]++))
done

# Ambil limit dari file
for user in $(ls "$limit_dir"); do
    limit=$(cat "$limit_dir/$user" 2>/dev/null)
    user_limit["$user"]=$limit
done

# Tampilkan hasil
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
