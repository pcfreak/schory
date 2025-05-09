#!/bin/bash

log="/var/log/xray/access.log"
limit_ip=1
durasi_menit=5
batas_epoch=$(date -d "$durasi_menit minutes ago" +"%s")

clear
echo -e "┌────────────────────────────────────────────────────────────┐"
echo -e "│              • TROJAN ONLINE NOW (Last $durasi_menit Min) •              │"
echo -e "└────────────────────────────────────────────────────────────┘"
printf "%-18s %-14s %-14s %s\n" "USERNAME" "IP AKTIF" "LIMIT IP" "STATUS"
echo -e "┌────────────────────────────────────────────────────────────┐"

users=$(grep 'accepted' "$log" | grep 'email:' | awk -F 'email: ' '{print $2}' | sort | uniq)

for user in $users; do
    ip_list=$(grep "accepted" "$log" | grep "email: $user" | while read -r line; do
        waktu_log=$(echo "$line" | awk '{print $1" "$2}' | sed 's/\//-/g') # convert tanggal ke YYYY-MM-DD
        ip_full=$(echo "$line" | grep -oP 'from \K[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+')
        ip_group=$(echo "$ip_full" | cut -d. -f1,2)

        epoch_log=$(date -d "${waktu_log%.*}" +"%s" 2>/dev/null)

        if [[ "$epoch_log" -ge "$batas_epoch" ]]; then
            echo "$ip_group"
        fi
    done | sort -u)

    total_ip=$(echo "$ip_list" | wc -l)
    [[ -z "$ip_list" ]] && total_ip=0

    status="\e[32mAktif\e[0m"
    [ "$total_ip" -gt "$limit_ip" ] && status="\e[31mMelebihi\e[0m"

    printf "%-18s %-14s %-14s %b\n" "$user" "$total_ip" "$limit_ip" "$status"
done

echo -e "└────────────────────────────────────────────────────────────┘"
read -p "Tekan enter untuk kembali ke menu..."
