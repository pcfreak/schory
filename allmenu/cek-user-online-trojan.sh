#!/bin/bash

# Path ke file log Xray dan direktori limit IP
log="/var/log/xray/access.log"
limit_dir="/etc/klmpk/limit/trojan/ip"
now=$(date +%s)

# Deklarasi array untuk IP per user, jumlah IP aktif, dan limit per user
declare -A user_ip_prefix
declare -A user_ip_count
declare -A user_limit

# Baca log dan proses baris yang relevan (dalam 1 menit terakhir)
while IFS= read -r line; do
    # Ekstrak username (email)
    [[ "$line" =~ email:\ ([^[:space:]]+) ]] || continue
    user="${BASH_REMATCH[1]}"

    # Ekstrak IP dan port
    [[ "$line" =~ from\ ([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+):([0-9]+) ]] || continue
    ip="${BASH_REMATCH[1]}"
    port="${BASH_REMATCH[2]}"

    # Hanya proses koneksi ke port 443 (Trojan)
    [[ "$port" != "443" ]] && continue

    # Ambil waktu dari log dan konversi ke epoch
    log_time=$(echo "$line" | awk '{print $1" "$2}')
    log_epoch=$(date -d "$log_time" +%s 2>/dev/null)
    [[ -z "$log_epoch" ]] && continue

    # Lewati log yang lebih dari 60 detik lalu
    ((now - log_epoch > 60)) && continue

    # Ambil 3 oktet pertama dari IP sebagai prefix (contoh: 192.168.1)
    ip_prefix=$(echo "$ip" | awk -F '.' '{print $1"."$2"."$3}')

    # Simpan unik prefix per user
    user_ip_prefix["$user,$ip_prefix"]=1
done < "$log"

# Hitung IP-prefix unik per user
for key in "${!user_ip_prefix[@]}"; do
    IFS=',' read -r user prefix <<< "$key"
    ((user_ip_count["$user"]++))
done

# Ambil limit IP dari file masing-masing user
for user in $(ls "$limit_dir" 2>/dev/null); do
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
