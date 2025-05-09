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

# Ambil daftar user Trojan
mapfile -t users < <(grep '^#!' /etc/xray/config.json | awk '{print $2}' | sort -u)

for user in "${users[@]}"; do
    [[ -z "$user" ]] && continue

    # Cari semua IP yang terkoneksi dengan user tersebut
    mapfile -t iplist < <(grep -a "$user" /var/log/xray/access.log | tail -n 500 | awk '{print $1}' | sort -u)

    ipaktif=${#iplist[@]}
    [[ "$ipaktif" = "0" ]] && continue

    # Ambil limit IP user
    limitfile="/etc/klmpk/limit/trojan/ip/$user"
    [[ -f "$limitfile" ]] && limit=$(cat "$limitfile") || limit=1

    # Status warna
    if [[ "$ipaktif" -gt "$limit" ]]; then
        status="${RED}Melebihi${NC}"
    else
        status="${GREEN}Normal${NC}"
    fi

    # Cetak tabel
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
