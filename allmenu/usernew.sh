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
openssh_port=$(ss -tnlp | grep -w sshd | awk '{print $4}' | grep -oE '[0-9]+' | sort -n | uniq | paste -sd "," -)
dropbear_port=$(ss -tnlp | grep -w dropbear | awk '{print $4}' | grep -oE '[0-9]+' | sort -n | uniq | paste -sd "," -)
stunnel_port=$(ss -tnlp | grep -w stunnel | awk '{print $4}' | grep -oE '[0-9]+' | sort -n | uniq | paste -sd "," -)
slowdns_port=$(ps -ef | grep sldns | grep -v grep | grep -oE '[0-9]{2,5}' | sort -n | uniq | paste -sd "," -)
ws_tls_port=$(cat ~/log-install.txt 2>/dev/null | grep -i "Websocket TLS" | awk -F: '{print $2}' | grep -oE '[0-9]+' | paste -sd "," -)
ws_http_port=$(cat ~/log-install.txt 2>/dev/null | grep -i "Websocket None TLS" | awk -F: '{print $2}' | grep -oE '[0-9]+' | paste -sd "," -)
badvpn_ports=$(ps -ef | grep udpgw | grep -v grep | awk '{for(i=1;i<=NF;i++) if($i ~ /--listen-addr/) print $i}' | cut -d: -f2 | sort -n | uniq | paste -sd "," -)

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
echo -e "OpenSSH        : ${openssh_port:-Tidak terdeteksi}"
echo -e "Dropbear       : ${dropbear_port:-Tidak terdeteksi}"
echo -e "SSH UDP        : ${badvpn_ports:-Tidak terdeteksi}"
echo -e "STunnel4       : ${stunnel_port:-Tidak terdeteksi}"
echo -e "SlowDNS        : ${slowdns_port:-Tidak terdeteksi}"
echo -e "WS TLS         : ${ws_tls_port:-Tidak terdeteksi}"
echo -e "WS HTTP        : ${ws_http_port:-Tidak terdeteksi}"
echo -e "WS Direct      : 8080"
echo -e "OpenVPN TCP    : http://$IP:81/tcp.ovpn"
echo -e "OpenVPN UDP    : http://$IP:81/udp.ovpn"
echo -e "OpenVPN SSL    : http://$IP:81/ssl.ovpn"
echo -e "BadVPN UDPGW   : ${badvpn_ports:-Tidak terdeteksi}"
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

==== Ports ====
OpenSSH        : ${openssh_ports:-Tidak terdeteksi}
Dropbear       : ${dropbear_ports:-Tidak terdeteksi}
SSH UDP        : ${udp_ports:-Tidak terdeteksi}
STunnel4       : ${stunnel_ports:-Tidak terdeteksi}
SlowDNS        : ${slowdns_ports:-Tidak terdeteksi}
WS TLS         : ${ws_tls:-443}
WS HTTP        : ${ws_http:-80}

==== OpenVPN ====
TCP : http://$IP:81/tcp.ovpn
UDP : http://$IP:81/udp.ovpn
SSL : http://$IP:81/ssl.ovpn
EOF
