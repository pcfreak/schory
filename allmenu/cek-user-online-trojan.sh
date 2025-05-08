#!/bin/bash
clear

RED='\e[31m'
GREEN='\e[32m'
NC='\e[0m'
COLOR1='\e[0;36m'
COLBG1='\e[44;97m'

# Tampilkan header
echo "" | pv -qL 20
echo -e "$COLOR1┌─────────────────────────────────────────────────┐${NC}"
echo -e "$COLOR1│${NC} ${COLBG1}            • TROJAN ONLINE NOW •              ${NC} $COLOR1│$NC"
echo -e "$COLOR1└─────────────────────────────────────────────────┘${NC}"
echo -e "$COLOR1┌────────────────────────────────────────────────────────────────────┐${NC}"
echo -e "$COLOR1│${NC} ${COLBG1} USERNAME        IP AKTIF       LIMIT IP        STATUS                 ${NC} $COLOR1│$NC"
echo -e "$COLOR1├────────────────────────────────────────────────────────────────────┤${NC}"

# Ambil user trojan dari config
mapfile -t users < <(grep '^#!' /etc/xray/config.json | awk '{print $2}' | sort -u)

# Ambil IP dari log akses terakhir
mapfile -t iplog < <(tail -n 500 /var/log/xray/access.log | awk '{print $3}' | sed 's/tcp://g' | cut -d ':' -f1 | sort -u)

for user in "${users[@]}"; do
    [[ -z "$user" ]] && continue
    > /tmp/iptrojan.txt

    for ip in "${iplog[@]}"; do
        grep -w "$user" /var/log/xray/access.log | tail -n 500 | grep -w "$ip" > /dev/null && echo "$ip" >> /tmp/iptrojan.txt
    done

    ipaktif=$(sort -u /tmp/iptrojan.txt | wc -l)
    [[ "$ipaktif" = "0" ]] && continue

    # Baca limit IP dari file
    limitfile="/etc/klmpk/limit/trojan/ip/$user"
    if [[ -f "$limitfile" ]]; then
        limit=$(cat "$limitfile")
    else
        limit=1
    fi

    # Tentukan status warna
    if [[ "$ipaktif" -gt "$limit" ]]; then
        status="${RED}Melebihi${NC}"
    else
        status="${GREEN}Normal${NC}"
    fi

    # Cetak tabel
    printf "$COLOR1│${NC} %-14s %-14s %-14s %-20s $COLOR1│${NC}\n" "$user" "$ipaktif" "$limit" "$status"
    rm -f /tmp/iptrojan.txt
done

echo -e "$COLOR1└────────────────────────────────────────────────────────────────────┘${NC}" 
echo -e "$COLOR1┌────────────────────── BY ───────────────────────┐${NC}"
echo -e "$COLOR1│${NC}                • KANGHORY •                 $COLOR1│$NC"
echo -e "$COLOR1└─────────────────────────────────────────────────┘${NC}" 
echo ""
read -n 1 -s -r -p "   Tekan sembarang tombol untuk kembali ke menu"
menu-trojan
