#!/bin/bash

red() { echo -e "\\033[31;1m${*}\\033[0m"; }
green() { echo -e "\\033[32;1m${*}\\033[0m"; }

MYIP=$(wget -qO- ipinfo.io/ip)
echo "Checking VPS..."

CEKIZIN() {
    IZIN=$(curl -sS https://raw.githubusercontent.com/kanghory/schory/main/izin | awk '{print $4}' | grep -w "$MYIP")
    if [[ "$MYIP" == "$IZIN" ]]; then
        echo -e "\e[32mPermission Accepted...\e[0m"
        today=$(date +%Y-%m-%d)
        Exp1=$(curl -sS https://raw.githubusercontent.com/kanghory/schory/main/izin | grep "$MYIP" | awk '{print $3}')
        if [[ "$today" < "$Exp1" ]]; then
            echo -e "\e[32mSTATUS SCRIPT AKTIF...\e[0m"
        else
            red "SCRIPT ANDA EXPIRED!"
            exit 1
        fi
    else
        red "Permission Denied!"
        exit 1
    fi
}

CEKIZIN
clear

domain=$(cat /etc/xray/domain)
mkdir -p /etc/klmpk/log-vless/  # Direktori untuk log

until [[ $user =~ ^[a-zA-Z0-9_]+$ && ${CLIENT_EXISTS} == '0' ]]; do
    clear
    echo -e "\033[1;93m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    echo -e "\E[0;41;36m             VLESS ACCOUNT           \E[0m"
    echo -e "\033[1;93m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    read -rp "User: " -e user
    CLIENT_EXISTS=$(grep -w "$user" /etc/xray/config.json | wc -l)
    if [[ ${CLIENT_EXISTS} == '1' ]]; then
        red "A client with the specified name already exists, please choose another."
        read -n 1 -s -r -p "Press any key to try again"
    fi
done

while [[ ! "$masaaktif" =~ ^[0-9]+$ ]]; do
    read -p "Expired (days): " masaaktif
done

uuid=$(cat /proc/sys/kernel/random/uuid)
exp=$(date -d "$masaaktif days" +"%Y-%m-%d")

# Tambah user ke config.json
sed -i "/#vless$/a\#& ${user} ${exp}\
},{\"id\": \"${uuid}\",\"email\": \"${user}\"" /etc/xray/config.json
sed -i "/#vlessgrpc$/a\#& ${user} ${exp}\
},{\"id\": \"${uuid}\",\"email\": \"${user}\"" /etc/xray/config.json

# Link VLESS
vlesslink1="vless://${uuid}@${domain}:443?path=/vless&security=tls&encryption=none&type=ws#${user}"
vlesslink2="vless://${uuid}@${domain}:80?path=/vless&encryption=none&type=ws#${user}"
vlesslink3="vless://${uuid}@${domain}:443?mode=gun&security=tls&encryption=none&type=grpc&serviceName=vless-grpc&sni=${domain}#${user}"

# Restart layanan
systemctl restart xray
systemctl restart nginx

# Simpan log dan tampilkan
tee /etc/klmpk/log-vless/${user}.txt > /dev/null <<-EOF
────────────────────────────
    Xray/Vless Account
────────────────────────────
Remarks     : ${user}
Domain      : ${domain}
Port TLS    : 443
Port NTLS   : 80
Port gRPC   : 443
User ID     : ${uuid}
Encryption  : none
Path TLS    : /vless
ServiceName : vless-grpc
────────────────────────────
Link TLS    : ${vlesslink1}
Link NTLS   : ${vlesslink2}
Link GRPC   : ${vlesslink3}
────────────────────────────
Expired On  : ${exp}
────────────────────────────
EOF

cat /etc/klmpk/log-vless/${user}.txt

read -n 1 -s -r -p "Press any key to return to menu"
menu
