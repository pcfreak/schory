#!/bin/bash

# Path ke file log Xray dan direktori limit IP
log="/var/log/xray/access.log"
limit_dir="/etc/klmpk/limit/trojan/ip"
now=$(date +%s)

# Mendeklarasikan array untuk menyimpan data IP, hitungan IP, dan limit
declare -A user_ips
declare -A user_ip_count
declare -A user_limit

# Baca log dari file dan ambil data IP yang aktif dalam 1 menit terakhir
while IFS= read -r line; do
    # Ekstrak username (email) dari log
    [[ "$line" =~ email:\ ([^[:space:]]+) ]] || continue
    user="${BASH_REMATCH[1]}"

    # Ekstrak IP dari log
    [[ "$line" =~ from\ ([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+): ]] || continue
    ip="${BASH_REMATCH[1]}"

    # Ambil waktu log
    log_time=$(echo "$line" | awk '{print $1" "$2}')
    log_epoch=$(date -d "$log_time" +%s 2>/dev/null)
    [[ -z "$log_epoch" ]] && continue

    # Jika log lebih dari 1 menit lalu, lanjutkan ke baris berikutnya
    ((now - log_epoch > 60)) && continue

    # Simpan IP per user (menyimpan user dan IP secara unik)
    user_ips["$user,$ip"]=1
done < "$log"

# Hitung jumlah IP aktif per user
for key in "${!user_ips[@]}"; do
    IFS=',' read -r user ip <<< "$key"
    ((user_ip_count["$user"]++))
done

# Ambil limit IP per user dari direktori
for user in $(ls "$limit_dir"); do
    limit=$(cat "$limit_dir/$user" 2>/dev/null)
    user_limit["$user"]=$limit
done

# Tampilkan hasil deteksi IP aktif
echo -e "\nMenampilkan hasil deteksi user Trojan yang online:"
printf "%-20s %-10s %-10s\n" "Username" "IP Aktif" "Limit IP"
echo "-----------------------------------------------"

# Loop melalui semua user yang terdeteksi
for user in "${!user_ip_count[@]}"; do
    count=${user_ip_count["$user"]}
    limit=${user_limit["$user"]:-0}

    # Menampilkan hasil
    if (( count > 0 )); then
        if (( count > limit && limit > 0 )); then
            # Tampilkan warna merah jika IP lebih banyak dari limit
            printf "\e[31m%-20s %-10s %-10s\e[0m\n" "$user" "$count" "$limit"
        else
            # Tampilkan normal jika IP dalam batas limit
            printf "%-20s %-10s %-10s\n" "$user" "$count" "$limit"
        fi
    fi
done
