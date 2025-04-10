#!/bin/bash

# Warna (tidak dipakai dalam output Telegram)
CYAN='\033[1;96m'
LIGHT='\033[1;97m'
NC='\033[0m'
RED='\033[1;91m'

# Ambil data dari argumen
Login="$1"
Pass="$2"
iplimit="$3"
masaaktif="$4"

# Validasi input
if [[ -z "$Login" || -z "$Pass" || -z "$iplimit" || -z "$masaaktif" ]]; then
    echo "[ERROR] Semua input harus diisi!"
    exit 1
fi

# Cek jika user sudah ada
if id "$Login" &>/dev/null; then
    echo "[ERROR] Username '$Login' sudah ada!"
    exit 1
fi

# Limit IP
if [[ $iplimit -gt 0 ]]; then
    mkdir -p /etc/klmpk/limit/ssh/ip/
    echo "$iplimit" > /etc/klmpk/limit/ssh/ip/$Login
fi

# Load data sistem
domain=$(cat /etc/xray/domain)
sldomain=$(cat /root/nsdomain 2>/dev/null || echo "-")
cdndomain=$(cat /root/awscdndomain 2>/dev/null || echo "-")
slkey=$(cat /etc/slowdns/server.pub 2>/dev/null || echo "-")
IP=$(wget -qO- ipinfo.io/ip)
ws=$(grep -w "Websocket TLS" ~/log-install.txt | cut -d: -f2 | sed 's/ //g')
ws2=$(grep -w "Websocket None TLS" ~/log-install.txt | cut -d: -f2 | sed 's/ //g')

# Buat akun user
useradd -e $(date -d "$masaaktif days" +"%Y-%m-%d") -s /bin/false -M $Login
echo -e "$Pass\n$Pass" | passwd $Login &> /dev/null

# Tanggal
hariini=$(date +%Y-%m-%d)
expi=$(date -d "$masaaktif days" +"%Y-%m-%d")

# Output informasi akun (untuk bot Telegram)
echo -e "==== SSH Account ===="
echo -e "Username : $Login"
echo -e "Password : $Pass"
echo -e "Created  : $hariini"
echo -e "Expired  : $expi"
echo -e "Limit IP : $iplimit"
echo -e ""
echo -e "==== Host ===="
echo -e "IP       : $IP"
echo -e "Domain   : $domain"
echo -e "Cloudflare: $cdndomain"
echo -e "PubKey   : $slkey"
echo -e "NS       : $sldomain"
echo -e ""
echo -e "==== OpenVPN ===="
echo -e "TCP : http://$IP:81/tcp.ovpn"
echo -e "UDP : http://$IP:81/udp.ovpn"
echo -e "SSL : http://$IP:81/ssl.ovpn"
echo -e ""
echo -e "Script by kanghoryVPN"

# Simpan log
mkdir -p /etc/klmpk/log-ssh
cat <<EOF > /etc/klmpk/log-ssh/$Login.txt
==== SSH Account ====
Username : $Login
Password : $Pass
Created  : $hariini
Expired  : $expi
Limit IP : $iplimit

==== Host ====
IP       : $IP
Domain   : $domain
Cloudflare: $cdndomain
PubKey   : $slkey
NS       : $sldomain

==== OpenVPN ====
TCP : http://$IP:81/tcp.ovpn
UDP : http://$IP:81/udp.ovpn
SSL : http://$IP:81/ssl.ovpn
EOF
