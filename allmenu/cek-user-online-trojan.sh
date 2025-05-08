#!/bin/bash
clear
> /tmp/other.txt

echo -e "$COLOR1┌─────────────────────────────────────────────────┐${NC}"
echo -e "$COLOR1│${NC} ${COLBG1}            • TROJAN ONLINE NOW •              ${NC} $COLOR1│$NC"
echo -e "$COLOR1└─────────────────────────────────────────────────┘${NC}"
echo -e "$COLOR1┌─────────────────────────────────────────────────┐${NC}"

# Ambil daftar akun trojan dari config
mapfile -t data < <(grep '^#!' /etc/xray/config.json | awk '{print $2}' | sort -u)

# Ambil daftar IP unik dari log
mapfile -t data_ip < <(tail -n 500 /var/log/xray/access.log | awk '{print $3}' | sed 's/tcp://g' | cut -d ':' -f1 | sort -u)

for akun in "${data[@]}"; do
    [[ -z "$akun" ]] && akun="tidakada"
    > /tmp/iptrojan.txt

    for ip in "${data_ip[@]}"; do
        if grep -w "$akun" /var/log/xray/access.log | tail -n 500 | grep -w "$ip" > /dev/null; then
            echo "$ip" >> /tmp/iptrojan.txt
        else
            echo "$ip" >> /tmp/other.txt
        fi
    done

    if [[ -s /tmp/iptrojan.txt ]]; then
        echo -e "$COLOR1│${NC}   user : $akun"
        nl /tmp/iptrojan.txt | while read line; do
            echo -e "$COLOR1│${NC}   $line"
        done
    fi

    rm -f /tmp/iptrojan.txt
done

rm -f /tmp/other.txt

echo -e "$COLOR1└─────────────────────────────────────────────────┘${NC}" 
echo -e "$COLOR1┌────────────────────── BY ───────────────────────┐${NC}"
echo -e "$COLOR1│${NC}                • KANGHORY •                 $COLOR1│$NC"
echo -e "$COLOR1└─────────────────────────────────────────────────┘${NC}" 
echo ""
read -n 1 -s -r -p "   Press any key to back on menu"
menu-trojan
