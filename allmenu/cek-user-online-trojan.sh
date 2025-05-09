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

# Ambil user trojan
mapfile -t users < <(grep '^#!' /etc/xray/config.json | awk '{print $2}' | sort -u)

# Ambil log 5 menit terakhir dari log akses
log_lines=$(awk -v t=$(date -d '5 minutes ago' +%s) '
{
    ts_str = $1 " " $2  # Contoh: 2025/05/09 15:10:35.572694
    gsub(/\..*/, "", ts_str)  # Hilangkan microsecond
    cmd = "date -d \"" ts_str "\" +%s"
    cmd | getline ts
    close(cmd)
    if (ts >= t) print
}' /var/log/xray/access.log)

for user in "${users[@]}"; do
    [[ -z "$user" ]] && continue
    ips=()

    # Ambil IP-IP user dari log yang valid
    while read -r line; do
        [[ "$line" == *"email: $user"* ]] || continue
        ip=$(echo "$line" | grep -oP 'from \K[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+')
        [[ -n "$ip" ]] && ips+=("$ip")
    done <<< "$log_lines"

    # Hitung IP unik berdasarkan 3 oktet pertama (prefix)
    ip_prefixes=()
    for ip in "${ips[@]}"; do
        prefix=$(echo "$ip" | cut -d '.' -f1-3)
        [[ ! " ${ip_prefixes[*]} " =~ " $prefix " ]] && ip_prefixes+=("$prefix")
    done

    ipaktif=${#ip_prefixes[@]}
    [[ "$ipaktif" == 0 ]] && continue

    # Baca limit
    limitfile="/etc/klmpk/limit/trojan/ip/$user"
    [[ -f "$limitfile" ]] && limit=$(cat "$limitfile") || limit=1

    if (( ipaktif > limit )); then
        status="${RED}Melebihi${NC}"
    else
        status="${GREEN}Normal${NC}"
    fi

    printf "$COLOR1│${NC} %-14s %-14s %-14s %-20s $COLOR1│${NC}\n" "$user" "$ipaktif" "$limit" "$status"
done

echo -e "$COLOR1└────────────────────────────────────────────────────────────────────┘${NC}"
echo -e "$COLOR1┌────────────────────── BY ───────────────────────┐${NC}"
echo -e "$COLOR1│${NC}                • KANGHORY •                 $COLOR1│$NC"
echo -e "$COLOR1└─────────────────────────────────────────────────┘${NC}"
echo ""
read -n 1 -s -r -p "   Tekan sembarang tombol untuk kembali ke menu"
menu-trojan
