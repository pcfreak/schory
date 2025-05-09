#!/bin/bash
clear

RED='\e[31m'
GREEN='\e[32m'
NC='\e[0m'
COLOR1='\e[0;36m'
COLBG1='\e[44;97m'

echo "" | pv -qL 20
echo -e "$COLOR1┌─────────────────────────────────────────────────┐${NC}"
echo -e "$COLOR1│${NC} ${COLBG1}            • TROJAN ONLINE NOW •              ${NC} $COLOR1│$NC"
echo -e "$COLOR1└─────────────────────────────────────────────────┘${NC}"
echo -e "$COLOR1┌────────────────────────────────────────────────────────────────────┐${NC}"
echo -e "$COLOR1│${NC} ${COLBG1} USERNAME        IP AKTIF       LIMIT IP        STATUS                 ${NC} $COLOR1│$NC"
echo -e "$COLOR1├────────────────────────────────────────────────────────────────────┤${NC}"

# Ambil user trojan dari config
mapfile -t users < <(grep '^#!' /etc/xray/config.json | awk '{print $2}' | sort -u)

# Ambil log 5 menit terakhir dan proses
mapfile -t log5mnt < <(awk -v t="$(date +%s)" '$1 ~ /^[0-9]{4}/ {
    split($2, time_parts, "."); waktu = $1 " " time_parts[1];
    gsub("/", "-", waktu);
    cmd = "date -d \"" waktu "\" +%s"
    cmd | getline ts; close(cmd)
    if (t - ts <= 300) print $0
}' /var/log/xray/access.log)

for user in "${users[@]}"; do
    [[ -z "$user" ]] && continue
    iplist=()

    for line in "${log5mnt[@]}"; do
        email=$(echo "$line" | grep -oE "email: *${user}$")
        [[ -n "$email" ]] || continue

        ip=$(echo "$line" | grep -oE 'from [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:' | cut -d ' ' -f2 | cut -d ':' -f1)
        ip3=$(echo "$ip" | cut -d '.' -f1-3)

        # Jika IP3 belum ada dalam list, tambahkan
        if [[ ! " ${iplist[*]} " =~ " $ip3 " ]]; then
            iplist+=("$ip3")
        fi
    done

    ipaktif=${#iplist[@]}
    [[ "$ipaktif" = "0" ]] && continue

    # Baca limit IP user
    limitfile="/etc/klmpk/limit/trojan/ip/$user"
    [[ -f "$limitfile" ]] && limit=$(cat "$limitfile") || limit=1

    # Status warna
    if [[ "$ipaktif" -gt "$limit" ]]; then
        status="${RED}Melebihi${NC}"
    else
        status="${GREEN}Normal${NC}"
    fi

    # Tampilkan tabel
    printf "$COLOR1│${NC} %-14s %-14s %-14s %-20s $COLOR1│${NC}\n" "$user" "$ipaktif" "$limit" "$status"
done

echo -e "$COLOR1└────────────────────────────────────────────────────────────────────┘${NC}" 
echo -e "$COLOR1┌────────────────────── BY ───────────────────────┐${NC}"
echo -e "$COLOR1│${NC}                • KANGHORY •                 $COLOR1│$NC"
echo -e "$COLOR1└─────────────────────────────────────────────────┘${NC}" 
echo ""
read -n 1 -s -r -p "   Tekan sembarang tombol untuk kembali ke menu"
menu-trojan
