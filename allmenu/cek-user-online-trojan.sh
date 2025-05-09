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
log_lines=$(awk -v t="$(date -d '5 min ago' +%s)" '
{
  split($1, d, "/")
  split(d[3], dt, ":")
  cmd = "date -d \"" d[1] "/" d[2] "/" dt[1] " " dt[2] ":" dt[3] ":" dt[4] "\" +%s"
  cmd | getline ts
  close(cmd)
  if (ts >= t) print
}' /var/log/xray/access.log)

for user in "${users[@]}"; do
    [[ -z "$user" ]] && continue
    ips=()

    # Ambil semua IP untuk user ini dari log_lines
    while IFS= read -r line; do
        if [[ "$line" == *"email: $user"* ]]; then
            ip=$(echo "$line" | grep -oP 'from \K[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+')
            [[ -n "$ip" ]] && ips+=("$ip")
        fi
    done <<< "$log_lines"

    # Normalisasi IP (pakai 3 oktet pertama)
    ip_prefixes=()
    for ip in "${ips[@]}"; do
        prefix=$(echo "$ip" | cut -d '.' -f1-3)
        [[ ! " ${ip_prefixes[*]} " =~ " $prefix " ]] && ip_prefixes+=("$prefix")
    done

    ipaktif=${#ip_prefixes[@]}
    [[ "$ipaktif" == 0 ]] && continue

    # Ambil limit IP user
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

    printf "$COLOR1│${NC} %-14s %-14s %-14s %-20s $COLOR1│${NC}\n" "$user" "$ipaktif" "$limit" "$status"
done

echo -e "$COLOR1└────────────────────────────────────────────────────────────────────┘${NC}"
echo -e "$COLOR1┌────────────────────── BY ───────────────────────┐${NC}"
echo -e "$COLOR1│${NC}                • KANGHORY •                 $COLOR1│$NC"
echo -e "$COLOR1└─────────────────────────────────────────────────┘${NC}"
echo ""
read -n 1 -s -r -p "   Tekan sembarang tombol untuk kembali ke menu"
menu-trojan
