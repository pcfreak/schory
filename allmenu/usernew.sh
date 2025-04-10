#!/bin/bash

# Warna
CYAN='\033[1;96m'
LIGHT='\033[1;97m'
NC='\033[0m'
YELLOW='\033[1;93m'
RED='\033[1;91m'

# Header
clear
echo -e "${YELLOW}---------------------------------------------------${NC}"
echo -e "                SSH Ovpn Account"
echo -e "${YELLOW}---------------------------------------------------${NC}"

# Input data
read -p " Username        : " Login
read -p " Password        : " Pass
read -p " Limit IP        : " iplimit
read -p " Expired (Days)  : " masaaktif

# Validasi input
if [[ -z "$Login" || -z "$Pass" || -z "$iplimit" || -z "$masaaktif" ]]; then
    echo -e "${RED}[ERROR]${NC} Semua input harus diisi!"
    exit 1
fi

# Cek jika user sudah ada
if id "$Login" &>/dev/null; then
    echo -e "${RED}[ERROR]${NC} Username '$Login' sudah ada!"
    exit 1
fi

# Limit IP
if [[ $iplimit -gt 0 ]]; then
    mkdir -p /etc/klmpk/limit/ssh/ip/
    echo -e "$iplimit" > /etc/klmpk/limit/ssh/ip/$Login
fi

# Load data sistem
domain=$(cat /etc/xray/domain)
sldomain=$(cat /root/nsdomain)
cdndomain=$(cat /root/awscdndomain 2>/dev/null || echo "-")
slkey=$(cat /etc/slowdns/server.pub)
IP=$(wget -qO- ipinfo.io/ip)
ws="$(grep -w "Websocket TLS" ~/log-install.txt | cut -d: -f2 | sed 's/ //g')"
ws2="$(grep -w "Websocket None TLS" ~/log-install.txt | cut -d: -f2 | sed 's/ //g')"

# Proses pembuatan user
useradd -e `date -d "$masaaktif days" +"%Y-%m-%d"` -s /bin/false -M $Login
echo -e "$Pass\n$Pass\n" | passwd $Login &> /dev/null
hariini=$(date +%Y-%m-%d)
expi=$(date -d "$masaaktif days" +"%Y-%m-%d")

# Output informasi akun
clear
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "\E[44;1;39m            ⇱ INFORMASI AKUN SSH ⇲             \E[0m"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${LIGHT}Username       : $Login"
echo -e "Password       : $Pass"
echo -e "Created        : $hariini"
echo -e "Expired        : $expi"
echo -e "Limit IP       : $iplimit"
echo -e "${LIGHT}=================HOST-SSH======================"
echo -e "IP/Host        : $IP"
echo -e "Domain SSH     : $domain"
echo -e "Cloudflare     : $cdndomain"
echo -e "PubKey         : $slkey"
echo -e "Nameserver     : $sldomain"
echo -e "${LIGHT}===============SERVICE PORT===================="
echo -e "OpenSSH        : 22"
echo -e "Dropbear       : 44, 69, 143"
echo -e "SSH UDP        : 1-2288"
echo -e "STunnel4       : 442, 222, 2096"
echo -e "SlowDNS        : 53, 5300, 8080"
echo -e "WS TLS         : 443"
echo -e "WS HTTP        : 80, 8080"
echo -e "WS Direct      : 8080"
echo -e "OpenVPN TCP    : http://$IP:81/tcp.ovpn"
echo -e "OpenVPN UDP    : http://$IP:81/udp.ovpn"
echo -e "OpenVPN SSL    : http://$IP:81/ssl.ovpn"
echo -e "BadVPN UDPGW   : 7100, 7200, 7300"
echo -e "Squid Proxy    : [ON]"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "       Script by kanghoryVPN"
echo -e "${LIGHT}================================================${NC}"

# Simpan ke file log akun
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
PubKey   : $slkey
NS       : $sldomain

==== OpenVPN ====
TCP : http://$IP:81/tcp.ovpn
UDP : http://$IP:81/udp.ovpn
SSL : http://$IP:81/ssl.ovpn
EOF
