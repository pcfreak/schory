#!/bin/bash

red() { echo -e "\\033[31;1m${*}\\033[0m"; } # Warna merah
green() { echo -e "\\033[32;1m${*}\\033[0m"; }

# Mendapatkan IP VPS
MYIP=$(wget -qO- ipinfo.io/ip)
echo "Checking VPS..."

# Cek izin dan expired
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
mkdir -p /etc/klmpk/log-vless

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

# Validasi masa aktif
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

# Output untuk OpenClash
cat >/var/www/html/vless-$user.txt <<-END
# Format Vless WS TLS
- name: Vless-$user-WS TLS
  server: ${domain}
  port: 443
  type: vless
  uuid: ${uuid}
  cipher: auto
  tls: true
  skip-cert-verify: true
  servername: ${domain}
  network: ws
  ws-opts:
    path: /vless
    headers:
      Host: ${domain}

# Format Vless WS Non TLS
- name: Vless-$user-WS (CDN) Non TLS
  server: ${domain}
  port: 80
  type: vless
  uuid: ${uuid}
  cipher: auto
  tls: false
  skip-cert-verify: false
  servername: ${domain}
  network: ws
  ws-opts:
    path: /vless
    headers:
      Host: ${domain}
  udp: true

# Format Vless gRPC (SNI)
- name: Vless-$user-gRPC (SNI)
  server: ${domain}
  port: 443
  type: vless
  uuid: ${uuid}
  cipher: auto
  tls: true
  skip-cert-verify: true
  servername: ${domain}
  network: grpc
  grpc-opts:
  grpc-mode: gun
  grpc-service-name: vless-grpc
  udp: true

-------------------------------------------------------
              Link Akun Vless 
-------------------------------------------------------
Link TLS      : ${vlesslink1}
Link none TLS : ${vlesslink2}
Link GRPC     : ${vlesslink3}
-------------------------------------------------------
END

# Restart layanan
systemctl restart xray
systemctl restart nginx

# Tampilkan info akun dengan format log dan warna
clear
echo -e "\033[1;93m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\E[0;41;36m          VLESS ACCOUNT LOG          \E[0m"
echo -e "\033[1;93m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"

cat <<-EOF
────────────────────────────
    Xray/Vless Account Log
────────────────────────────
User       : ${user}
Domain     : ${domain}
UUID       : ${uuid}
Expired    : ${exp}
TLS        : ${vlesslink1}
NonTLS     : ${vlesslink2}
gRPC       : ${vlesslink3}
OpenClash  : https://${domain}:81/vless-${user}.txt
────────────────────────────
EOF

# Menyimpan log ke direktori /etc/klmpk/log-vless (bukan di /root/akun/vless)
cat <<-EOF > /etc/klmpk/log-vless/${user}.txt
User       : ${user}
Domain     : ${domain}
UUID       : ${uuid}
Expired    : ${exp}
TLS        : ${vlesslink1}
NonTLS     : ${vlesslink2}
gRPC       : ${vlesslink3}
OpenClash  : https://${domain}:81/vless-${user}.txt
EOF

read -n 1 -s -r -p "Press any key to return to menu"
menu
