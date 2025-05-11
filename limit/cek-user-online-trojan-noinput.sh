#!/bin/bash

LIMIT_DIR="/etc/klmpk/limit/trojan/ip"
LOG_FILE="/var/log/xray/access.log"

echo -e "  • TROJAN ONLINE NOW (Last 1 Min) •"
echo -e "──────────────────────────────────────────────────────────────"
printf "%-15s %-15s %-15s %-15s %-10s\n" "USERNAME" "IP AKTIF" "LIMIT IP" "TOLERANSI IP" "STATUS"
echo -e "──────────────────────────────────────────────────────────────"

now=$(date +%s)
cutoff=$((now - 60))

# Ambil log hanya dari 1 menit terakhir
log_recent=$(awk -v t="$cutoff" '{ gsub("\\[", "", $1); cmd="date -d \""$1"\" +%s"; cmd | getline ts; close(cmd); if (ts >= t) print }' "$LOG_FILE")

# Ambil semua email (user Trojan)
users=$(find "$LIMIT_DIR" -type f -printf "%f\n")

for user in $users; do
    limitip=$(cat "$LIMIT_DIR/$user")
    [[ -z "$limitip" ]] && limitip=1

    # Ambil IP unik (3 oktet) dari log user ini
    ips=$(echo "$log_recent" | grep "$user" | awk '{print $3}' | cut -d '.' -f1-3 | sort -u)
    ipcount=$(echo "$ips" | wc -l)

    # Hitung toleransi (jumlah IP)
    toleransi="$ipcount"
    status="Aman"
    [[ "$toleransi" -gt "$limitip" ]] && status="Melebihi"

    printf "%-15s %-15s %-15s %-15s %-10s\n" "$user" "$ipcount" "$limitip" "$toleransi" "$status"

    # Tampilkan IP-IP nya
    if [[ "$ipcount" -gt 0 ]]; then
        echo "  # IP Aktif (3 Oktet):"
        while read -r ip; do
            [[ -n "$ip" ]] && echo "   - $ip"
        done <<< "$ips"
    fi

    echo -e "──────────────────────────────────────────────────────────────"
done

total=$(echo "$log_recent" | awk '{print $3}' | cut -d '.' -f1-3 | sort -u | wc -l)
echo "Total IP aktif terdeteksi (3 oktet): $total"
echo -e "──────────────────────────────────────────────────────────────"
