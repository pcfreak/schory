#!/bin/bash

log_file="/var/log/xray/access.log"
config_file="/etc/xray/config.json"
limit_dir="/etc/klmpk/limit/trojan/ip"

cutoff_epoch=$(date -d "60 seconds ago" +%s)
echo "[DEBUG] Cutoff epoch: $cutoff_epoch ($(date -d "@$cutoff_epoch"))"

user_list=$(grep -oP '"password":\s*"\K[^"]+' "$config_file")

declare -A user_ips user_online

echo "[DEBUG] Parsing access.log..."

grep "email:" "$log_file" | while read -r line; do
    echo "[DEBUG] Line: $line"
    ts_raw=$(echo "$line" | grep -oP '^\d{4}/\d{2}/\d{2} \d{2}:\d{2}:\d{2}')
    [[ -z "$ts_raw" ]] && echo "[SKIP] No timestamp found" && continue

    ts_epoch=$(date -d "$ts_raw" +%s 2>/dev/null)
    [[ $? -ne 0 ]] && echo "[SKIP] Invalid date: $ts_raw" && continue
    echo "[DEBUG] Log time: $ts_raw ($ts_epoch)"

    if [[ $ts_epoch -lt $cutoff_epoch ]]; then
        echo "[SKIP] Older than cutoff"
        continue
    fi

    user=$(echo "$line" | grep -oP 'email:\s*\K\S+')
    ip=$(echo "$line" | grep -oP 'from (\d{1,3}\.){3}\d{1,3}' | awk '{print $2}')
    subnet=$(echo "$ip" | cut -d '.' -f1-3)

    [[ -z "$user" || -z "$subnet" ]] && echo "[SKIP] Missing user or IP" && continue

    echo "[DEBUG] User: $user | IP: $ip | Subnet: $subnet"

    user_ips["$user,$subnet"]=1
    user_online["$user"]=1
done

echo
echo "Menampilkan hasil deteksi user Trojan yang online:"
printf "%-20s %-10s %-10s\n" "Username" "IP Aktif" "Limit IP"
printf "%s\n" "-----------------------------------------------"

for user in $user_list; do
    [[ -z "${user_online[$user]}" ]] && echo "[SKIP OUTPUT] $user tidak aktif" && continue

    count=$(printf "%s\n" "${!user_ips[@]}" | grep "^$user," | wc -l)

    limit_file="$limit_dir/$user"
    if [[ -f $limit_file ]]; then
        limit=$(cat "$limit_file")
    else
        limit="-"
    fi

    printf "%-20s %-10s %-10s\n" "$user" "$count" "$limit"
done
