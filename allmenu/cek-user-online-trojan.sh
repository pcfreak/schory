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

# Ambil log 5 menit terakhir
mapfile -t log5mnt < <(awk -v t="$(date +%s)" '$1 ~ /^[0-9]{4}/ {
    gsub("/", " ", $1); gsub(":", " ", $2);
    cmd = "date -d \"" $1 " " $2 "\" +%s"
    cmd | getline ts; close(cmd)
    if (t - ts <= 300) print $0
}' /var/log/xray/access.log)

for user in "${users[@]}"; do
    [[ -z "$user" ]] && continue
    declare -A ip_prefix=()
    ips=()

    for line in "${log5mnt[@]}"; do
        email=$(echo "$line" | grep -oE 'email: [^ ]+' | cut -d' ' -f2)
        [[ "$email" != "$user" ]] && continue

        ipfull=$(echo "$line" | grep -oE 'from [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:' | cut -d' ' -f2 | cut -d':' -f1)
        ipprefix=$(echo "$ipfull" | cut -d'.' -f1-3)

        # Kelompokkan IP per /24
        ip_prefix["$ipprefix"]=1
        [[ ! " ${ips[*]} " =~ $ipfull ]] && ips+=("$ipfull")
    done

    ipaktif=${#ip_prefix[@]}
    [[ "$ipaktif" = "0" ]] && continue

    # Baca limit IP dari file
    limitfile="/etc/klmpk/limit/trojan/ip/$user"
    [[ -f "$limitfile" ]] && limit=$(cat "$limitfile") || limit=1

    [[ "$ipaktif" -gt "$limit" ]] && status="${RED}Melebihi${NC}" || status="${GREEN}Normal${NC}"

    printf "$COLOR1│${NC} %-14s %-14s %-14s %-20s $COLOR1│${NC}\n" "$user" "$ipaktif" "$limit" "$status"
    echo -e "$COLOR1│${NC} IP Detil: ${ips[*]}${NC}"
    echo -e "$COLOR1├────────────────────────────────────────────────────────────────────┤${NC}"
done

echo -e "$COLOR1└────────────────────────────────────────────────────────────────────┘${NC}" 
echo -e "$COLOR1┌────────────────────── BY ───────────────────────┐${NC}"
echo -e "$COLOR1│${NC}                • KANGHORY •                 $COLOR1│$NC"
echo -e "$COLOR1└─────────────────────────────────────────────────┘${NC}" 
echo ""
read -n 1 -s -r -p "   Tekan sembarang tombol untuk kembali ke menu"
menu-trojan
