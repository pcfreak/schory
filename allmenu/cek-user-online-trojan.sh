#!/bin/bash

log="/var/log/xray/access.log"
batas_menit=5
limit_ip=1

# Ambil waktu sekarang - 5 menit
waktu_batas=$(date -d "$batas_menit min ago" '+%Y/%m/%d %H:%M:%S')

# Ambil semua email (user) unik dari log
users=$(grep "accepted" "$log" | awk '{for(i=1;i<=NF;i++) if ($i ~ /^email:/) print $i}' | cut -d: -f2 | sort | uniq)

clear
echo -e "┌────────────────────────────────────────────────────────────┐"
echo -e "│              • TROJAN ONLINE NOW (Last $batas_menit Min) •              │"
echo -e "└────────────────────────────────────────────────────────────┘"
printf "%-18s %-14s %-14s %s\n" "USERNAME" "IP AKTIF" "LIMIT IP" "STATUS"
echo -e "┌────────────────────────────────────────────────────────────┐"

for user in $users; do
    ip_list=$(awk -v user="$user" -v waktu="$waktu_batas" '
    $0 ~ user {
        split($1, d, "/")
        split($2, t, ":")
        waktu_log = d[1] "/" d[2] "/" d[3] " " t[1] ":" t[2] ":" t[3]
        if (waktu_log >= waktu) {
            match($0, /from ([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)/, ip)
            if (ip[1] != "") {
                split(ip[1], o, ".")
                print o[1] "." o[2]
            }
        }
    }
    ' "$log" | sort | uniq)

    jumlah_ip=$(echo "$ip_list" | wc -l)

    status="\e[32mAktif\e[0m"
    [ "$jumlah_ip" -gt "$limit_ip" ] && status="\e[31mMelebihi\e[0m"

    printf "%-18s %-14s %-14s %b\n" "$user" "$jumlah_ip" "$limit_ip" "$status"
done

echo -e "└────────────────────────────────────────────────────────────┘"
echo -e "   Tekan Enter untuk kembali ke menu"
read
