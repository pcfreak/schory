#!/bin/bash

# ==========================================
# Color
RED='\033[0;31m'
NC='\033[0m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
LIGHT='\033[0;37m'
# ==========================================
export RED GREEN YELLOW BLUE PURPLE CYAN LIGHT NC

# Izin
MYIP=$(wget -qO- ipinfo.io/ip)
echo "Memeriksa VPS Anda..."
sleep 0.5

CEKEXPIRED () {
    today=$(date -d +1day +%Y-%m-%d)
    Exp1=$(curl -sS https://raw.githubusercontent.com/kanghory/schory/main/izin | grep $MYIP | awk '{print $3}')
    if [[ $today < $Exp1 ]]; then
        echo "Status script aktif..."
    else
        echo "SCRIPT ANDA EXPIRED"
        exit 0
    fi
}

IZIN=$(curl -sS https://raw.githubusercontent.com/kanghory/schory/main/izin | awk '{print $4}' | grep $MYIP)
if [[ $MYIP == $IZIN ]]; then
    echo "IZIN DITERIMA!!"
    CEKEXPIRED
else
    echo "Akses ditolak!!"
    exit 0
fi

# Input user
Login=trial`</dev/urandom tr -dc X-Z0-9 | head -c4`
Pass="1"
read -p "Limit IP (contoh 2): " max
echo -e "Pilih masa aktif akun trial:"
echo -e "1. 10 Menit"
echo -e "2. 30 Menit"
echo -e "3. 1 Jam"
echo -e "4. 6 Jam"
echo -e "5. 1 Hari"
read -p "Pilih [1-5]: " pilih_exp

case $pilih_exp in
  1) masaaktif="10 minute" ;;
  2) masaaktif="30 minute" ;;
  3) masaaktif="1 hour" ;;
  4) masaaktif="6 hour" ;;
  5) masaaktif="1 day" ;;
  *) echo "Pilihan tidak valid"; exit 1 ;;
esac

# Domain & Info
domain=$(cat /etc/xray/domain)
sldomain=$(cat /root/nsdomain)
cdndomain=$(cat /root/awscdndomain)
slkey=$(cat /etc/slowdns/server.pub)
IP=$(wget -qO- ipinfo.io/ip)

# Port Info
ws="$(grep -w "Websocket TLS" ~/log-install.txt | cut -d: -f2|sed 's/ //g')"
ws2="$(grep -w "Websocket None TLS" ~/log-install.txt | cut -d: -f2|sed 's/ //g')"
ssl="$(grep -w "Stunnel5" ~/log-install.txt | cut -d: -f2)"
sqd="$(grep -w "Squid" ~/log-install.txt | cut -d: -f2)"
ovpn="$(netstat -nlpt | grep -i openvpn | grep -i 0.0.0.0 | awk '{print $4}' | cut -d: -f2)"
ovpn2="$(netstat -nlpu | grep -i openvpn | grep -i 0.0.0.0 | awk '{print $4}' | cut -d: -f2)"

# Restart layanan
systemctl restart client-sldns server-sldns ssh-ohp rc-local dropbear-ohp openvpn-ohp

# Buat akun SSH
useradd -e `date -d "$masaaktif" +"%Y-%m-%d %H:%M:%S"` -s /bin/false -M $Login
echo -e "$Pass\n$Pass\n"|passwd $Login &> /dev/null
expi=$(date -d "$masaaktif" +"%Y-%m-%d %H:%M:%S")
hariini=$(date +"%Y-%m-%d %H:%M:%S")

# Simpan limit IP
mkdir -p /etc/klmpk/limit/ssh/ip
echo "$max" > /etc/klmpk/limit/ssh/ip/$Login

# Output akun
clear
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "\E[44;1;39m              ⇱ TRIAL AKUN SSH ⇲               \E[0m"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${LIGHT}Username: $Login"
echo -e "Password: $Pass"
echo -e "Created: $hariini"
echo -e "Expired: $expi"
echo -e "Limit IP: $max IP"
echo -e "${LIGHT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "IP/Host: $IP"
echo -e "Domain SSH: $domain"
echo -e "PubKey: $slkey"
echo -e "Nameserver: $sldomain"
echo -e "OpenSSH: 22"
echo -e "Dropbear: 44, 69, 143"
echo -e "STunnel4: 442,222,2096"
echo -e "SlowDNS: 53,5300,8080,443,80"
echo -e "WS SSL: 443 | HTTP: 80,8080,8880 | Direct: 8080"
echo -e "OVPN TCP: http://$IP:81/tcp.ovpn"
echo -e "OVPN UDP: http://$IP:81/udp.ovpn"
echo -e "OVPN SSL: http://$IP:81/ssl.ovpn"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "Payload Websocket SSL:"
echo -e "GET wss://bug.com/ HTTP/1.1[crlf]Host: [host][crlf]Upgrade: websocket[crlf][crlf]"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "Payload Websocket HTTP:"
echo -e "GET / HTTP/1.1[crlf]Host: [host][crlf]Upgrade: websocket[crlf][crlf]"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "Terimakasih sudah menggunakan script BY KANGHORY TUNNELING"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
read -n 1 -s -r -p "Tekan ENTER untuk kembali ke menu..."
/usr/bin/menu
