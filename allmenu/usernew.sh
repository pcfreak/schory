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

# Simpan Limit IP
mkdir -p /etc/klmpk/limit/ssh/ip/
echo "$iplimit" > /etc/klmpk/limit/ssh/ip/$Login

# Load data sistem
domain=$(cat /etc/xray/domain)
sldomain=$(cat /root/nsdomain)
cdndomain=$(cat /root/awscdndomain 2>/dev/null || echo "auto pointing Cloudflare")
slkey=$(cat /etc/slowdns/server.pub)
IP=$(wget -qO- ipinfo.io/ip)

# Deteksi port otomatis (hindari port kosong)
function detect_ports() {
    local pattern="$1"
    local ports=$(netstat -tulpn 2>/dev/null | grep -i "$pattern" | awk '{print $4}' | grep -oE '[0-9]+$' | sort -n | uniq | paste -sd, -)
    [[ -z "$ports" ]] && echo "Tidak terdeteksi" || echo "$ports"
}

openssh=$(detect_ports ssh)
dropbear=$(detect_ports dropbear)
stunnel=$(detect_ports stunnel)
ws_tls=$(detect_ports 443)
ws_http=$(detect_ports 80)
slowdns=$(ps -ef | grep -w sldns | grep -v grep | awk '{for(i=1;i<=NF;i++){if($i=="-udp"){print $(i+1)}}}' | cut -d: -f2 | paste -sd, -)
[[ -z "$slowdns" ]] && slowdns="Tidak terdeteksi"
udpgw_ports=$(ps -ef | grep badvpn | grep -v grep | awk '{for(i=1;i<=NF;i++){if($i=="--listen-addr"){print $(i+1)}}}' | cut -d: -f2 | paste -sd, -)
[[ -z "$udpgw_ports" ]] && udpgw_ports="Tidak terdeteksi"
ws_direct=8080

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
echo -e "OpenSSH        : $openssh"
echo -e "Dropbear       : $dropbear"
echo -e "SSH UDP        : $udpgw_ports"
echo -e "STunnel4       : $stunnel"
echo -e "SlowDNS        : $slowdns"
echo -e "WS TLS         : $ws_tls"
echo -e "WS HTTP        : $ws_http"
echo -e "WS Direct      : $ws_direct"
echo -e "OpenVPN TCP    : http://$IP:81/tcp.ovpn"
echo -e "OpenVPN UDP    : http://$IP:81/udp.ovpn"
echo -e "OpenVPN SSL    : http://$IP:81/ssl.ovpn"
echo -e "BadVPN UDPGW   : $udpgw_ports"
echo -e "Squid Proxy    : [ON]"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "       Script by kanghoryVPN"
echo -e "${LIGHT}================================================${NC}"

# Simpan log akun
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
