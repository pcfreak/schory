#!/bin/bash
clear

# Warna
RED='\e[31m'
GREEN='\e[32m'
NC='\e[0m'
COLOR1='\e[0;36m'
COLBG1='\e[44;97m'

# Header
echo "" | pv -qL 20
echo -e "$COLOR1┌─────────────────────────────────────────────────┐${NC}"
echo -e "$COLOR1│${NC} ${COLBG1}            • TROJAN ONLINE NOW •              ${NC} $COLOR1│$NC"
echo -e "$COLOR1└─────────────────────────────────────────────────┘${NC}"
echo -e "$COLOR1┌────────────────────────────────────────────────────────────────────┐${NC}"
echo -e "$COLOR1│${NC} ${COLBG1} USERNAME        IP AKTIF       LIMIT IP        STATUS                 ${NC} $COLOR1│$NC"
echo -e "$COLOR1├────────────────────────────────────────────────────────────────────┤${NC}"

# Ambil daftar user Trojan dari config
mapfile -t users < <(grep '^#!' /etc/xray/config.json | awk '{print $2}' | sort -u)

# Proses masing-masing user
for user in "${users[@]}"; do
    [[ -z "$user" ]] && continue

    # Ambil IP unik dari log xray untuk user ini
    ipaktif=$(grep -w "$user" /var/log/xray/access.log | tail -n 500 | awk '{for(i=1;i<=NF;i++) if($i ~ /^tcp:\/\//) print $i}' | sed 's/tcp:\/\///' | cut -d ':' -f1 | sort -u | wc -l)

    [[ "$ipaktif" = "0" ]] && continue

    # Baca limit IP dari file
    limitfile="/etc/klmpk/limit/trojan/ip/$user"
    if [[ -f "$limitfile" ]]; then
        limit=$(cat "$limitfile")
    else
        limit=1
    fi

    # Status warna
    if [[ "$ipaktif" -gt "$limit" ]]; then
        status="${RED}Melebihi${NC}"
    else
        status="${GREEN}Normal${NC}"
    fi

    # Tampilkan tabel
    printf "$COLOR1│${NC} %-14s %-14s %-14s %-20s $COLOR1│${NC}\n" "$user" "$ipaktif" "$limit" "$status"
done

# Footer
echo -e "$COLOR1└────────────────────────────────────────────────────────────────────┘${NC}" 
echo -e "$COLOR1┌────────────────────── BY ───────────────────────┐${NC}"
echo -e "$COLOR1│${NC}                • KANGHORY •                 $COLOR1│$NC"
echo -e "$COLOR1└─────────────────────────────────────────────────┘${NC}" 
echo ""
read -n 1 -s -r -p "   Tekan sembarang tombol untuk kembali ke menu"
menu-trojan
