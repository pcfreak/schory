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
elif ! [[ "$iplimit" =~ ^[0-9]+$ && "$masaaktif" =~ ^[0-9]+$ ]]; then
    echo -e "${RED}[ERROR]${NC} Limit IP dan Expired harus berupa angka!"
    exit 1
fi

# Cek jika user sudah ada
if id "$Login" &>/dev/null; then
    echo -e "${RED}[ERROR]${NC} Username '$Login' sudah ada!"
    exit 1
fi

# Limit IP
mkdir -p /etc/klmpk/limit/ssh/ip/
echo -e "$iplimit" > /etc/klmpk/limit/ssh/ip/$Login

# Load data sistem
domain=$(cat /etc/xray/domain)
sldomain=$(cat /root/nsdomain)
cdndomain=$(cat /root/awscdndomain 2>/dev/null || echo "auto pointing Cloudflare")
slkey=$(cat /etc/slowdns/server.pub)
IP=$(wget -qO- ipinfo.io/ip)

# Deteksi port otomatis
openssh_port=$(ss -tnlp | grep -w sshd | awk '{print $4}' | cut -d: -f2 | sort -n | paste -sd "," -)
dropbear_port=$(ps -ef | grep dropbear | grep -v grep | awk '{for(i=1;i<=NF;i++) if ($i=="-p") print $(i+1)}' | sort -n | paste -sd "," -)
stunnel_port=$(grep -i 'accept' /etc/stunnel/stunnel.conf 2>/dev/null | cut -d= -f2 | sed 's/ //g' | paste -sd "," -)
ws_tls=$(grep -w "Websocket TLS" ~/log-install.txt | cut -d: -f2 | sed 's/ //g')
ws_http=$(grep -w "Websocket None TLS" ~/log-install.txt | cut -d: -f2 | sed 's/ //g')
udp_ports=$(pgrep -a badvpn-udpgw | grep -oP '127.0.0.1:\K[0-9]+' | sort -n | paste -sd "," -)
sldns_ports=$(ps -ef | grep sldns | grep -v grep | grep -oP '\-udp\s+\K[^ ]+' | cut -d: -f2 | sort -u | paste -sd "," -)

# Default jika kosong
openssh_port=${openssh_port:-22}
dropbear_port=${dropbear_port:-Tidak terdeteksi}
stunnel_port=${stunnel_port:-Tidak terdeteksi}
udp_ports=${udp_ports:-Tidak terdeteksi}
sldns_ports=${sldns_ports:-Tidak terdeteksi}
ws_tls=${ws_tls:-443}
ws_http=${ws_http:-80,8080}

# Proses pembuatan user
useradd -e $(date -d "$masaaktif days" +"%Y-%m-%d") -s /bin/false -M $Login
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
echo -e "OpenSSH        : $openssh_port"
echo -e "Dropbear       : $dropbear_port"
echo -e "SSH UDP        : $udp_ports"
echo -e "STunnel4       : $stunnel_port"
echo -e "SlowDNS        : $sldns_ports"
echo -e "WS TLS         : $ws_tls"
echo -e "WS HTTP        : $ws_http"
echo -e "WS Direct      : $ws_http"
echo -e "OpenVPN TCP    : http://$IP:81/tcp.ovpn"
echo -e "OpenVPN UDP    : http://$IP:81/udp.ovpn"
echo -e "OpenVPN SSL    : http://$IP:81/ssl.ovpn"
echo -e "BadVPN UDPGW   : $udp_ports"
echo -e "Squid Proxy    : [ON]"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "       Script by kanghoryVPN"
echo -e "${LIGHT}================================================${NC}"

# Simpan ke log akun
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
