#!/bin/bash

log_file="/var/log/xray/access.log"
user_json="/etc/xray/trojan.json"
limit_ip_dir="/etc/klmpk/limit/trojan/ip"

declare -A user_ips
declare -A user_ip_count

# Ambil semua user Trojan dari config
user_list=$(jq -r '.inbounds[] | select(.protocol=="trojan") | .settings.clients[].email' "$user_json")

# Ambil 50 baris log terakhir (bisa diubah sesuai kebutuhan)
tail -n 50 "$log_file" | while read -r line; do
    [[ "$line" =~ accepted\ tcp|udp.*email:\ ([^[:space:]]+) ]] || continue
    user="${BASH_REMATCH[1]}"

    [[ "$line" =~ from\ ([^:]+): ]] || continue
    ip="${BASH_REMATCH[1]}"

    [[ -n "$user" && -n "$ip" ]] && ((user_ips["$user,$ip"]++))
done

# Hitung hanya IP yang muncul lebih dari 1x
for key in "${!user_ips[@]}"; do
    IFS=',' read -r user ip <<< "$key"
    count=${user_ips["$key"]}
    if (( count >= 2 )); then
        ((user_ip_count["$user"]++))
    fi
done

# Tampilkan hasil
printf "Menampilkan hasil deteksi user Trojan yang online:\n"
printf "%-20s %-10s %-10s\n" "Username" "IP Aktif" "Limit IP"
printf "%s\n" "-----------------------------------------------"

for user in $user_list; do
    ip_count=${user_ip_count["$user"]:--}
    limit_ip_file="${limit_ip_dir}/${user}"
    if [[ -f "$limit_ip_file" ]]; then
        limit_ip=$(cat "$limit_ip_file")
    else
        limit_ip="Unlimited"
    fi
    if [[ "$ip_count" != "-" ]]; then
        printf "%-20s %-10s %-10s\n" "$user" "$ip_count" "$limit_ip"
    fi
done
