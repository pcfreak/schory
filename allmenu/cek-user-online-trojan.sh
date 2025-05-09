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

declare -A ip_per_user

# Ambil baris log terakhir (500 baris)
log_lines=$(tail -n 500 /var/log/xray/access.log)

# Proses log untuk menghitung IP per username
while read -r line; do
    ip=$(echo "$line" | awk '{for(i=1;i<=NF;i++) if($i=="from") print $(i+1)}' | cut -d':' -f1)
    user=$(echo "$line" | grep -oP 'email:\s*\K\S+')
    [[ -n "$ip" && -n "$user" ]] && ip_per_user["$user"]+="$ip"$'\n'
done <<< "$log_lines"

# Tampilkan tabel
for user in "${!ip_per_user[@]}"; do
    iplist=$(echo "${ip_per_user[$user]}" | sort -u)
    ipcount=$(echo "$iplist" | wc -l)

    limitfile="/etc/klmpk/limit/trojan/ip/$user"
    [[ -f "$limitfile" ]] && limit=$(cat "$limitfile") || limit=1

    [[ "$ipcount" -gt "$limit" ]] && status="${RED}Melebihi${NC}" || status="${GREEN}Normal${NC}"
    printf "$COLOR1│${NC} %-14s %-14s %-14s %-20s $COLOR1│${NC}\n" "$user" "$ipcount" "$limit" "$status"
done

echo -e "$COLOR1└────────────────────────────────────────────────────────────────────┘${NC}" 
echo -e "$COLOR1┌────────────────────── BY ───────────────────────┐${NC}"
echo -e "$COLOR1│${NC}                • KANGHORY •                 $COLOR1│$NC"
echo -e "$COLOR1└─────────────────────────────────────────────────┘${NC}" 
echo ""
read -n 1 -s -r -p "   Tekan sembarang tombol untuk kembali ke menu"
menu-trojan
