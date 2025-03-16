echo -e "\033[1;93m---------------------------------------------------\033[0m"
echo -e " SSH Ovpn Account           "
echo -e "\033[1;93m---------------------------------------------------\033[0m"
read -p " Username : " Login
read -p " Password : " Pass
read -p " Limit IP : " iplimit
read -p " Expired (Days) : " masaaktif

# Limit IP
if [[ $iplimit -gt 0 ]]; then
    mkdir -p /etc/klmpk/limit/ssh/ip/
    echo -e "$iplimit" > /etc/klmpk/limit/ssh/ip/$Login
else
    echo > /dev/null
fi

# Getting
domain=$(cat /etc/xray/domain)
sldomain=$(cat /root/nsdomain)
cdndomain=$(cat /root/awscdndomain)
slkey=$(cat /etc/slowdns/server.pub)
clear

IP=$(wget -qO- ipinfo.io/ip)
ws="$(cat ~/log-install.txt | grep -w "Websocket TLS" | cut -d: -f2 | sed 's/ //g')"
ws2="$(cat ~/log-install.txt | grep -w "Websocket None TLS" | cut -d: -f2 | sed 's/ //g')"

useradd -e `date -d "$masaaktif days" +"%Y-%m-%d"` -s /bin/false -M $Login
expi="$(chage -l $Login | grep "Account expires" | awk -F": " '{print $2}')"
echo -e "$Pass\n$Pass\n" | passwd $Login &> /dev/null
hariini=`date -d "0 days" +"%Y-%m-%d"`
expi=`date -d "$masaaktif days" +"%Y-%m-%d"`

clear
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m${NC}"
echo -e "\E[44;1;39m                 ⇱ INFORMASI AKUN SSH ⇲            \E[0m"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m${NC}"
echo -e "${LIGHT}Username: $Login"
echo -e "Password: $Pass"
echo -e "Created: $hariini"
echo -e "Expired: $expi"
echo -e "Limit IP: $iplimit"
echo -e "${LIGHT}=================HOST-SSH===================="
echo -e "IP/Host: $IP"
echo -e "Domain SSH: $domain"
echo -e "Domain Cloudflare: $domain"
echo -e "PubKey : $slkey"
echo -e "Nameserver: $sldomain"
echo -e "${LIGHT}===============Service-Port=================="
echo -e "OpenSSH: 22"
echo -e "Dropbear: 44, 69, 143"
echo -e "SSH UDP: 1-2288"
echo -e "STunnel4: 442,222,2096"
echo -e "SlowDNS port: 53,5300,8080"
echo -e "SSH Websocket SSL/TLS: 443"
echo -e "SSH Websocket HTTP: 80,8080"
echo -e "SSH Websocket Direct: 8080"
echo -e "OPEN VPN: 1194"
echo -e "BadVPN UDPGW: 7100,7200,7300"
echo -e "Proxy Squid: [ON]"
echo -e "OVPN TCP: http://$IP:81/tcp.ovpn"
echo -e "OVPN UDP: http://$IP:81/udp.ovpn"
echo -e "OVPN SSL: http://$IP:81/ssl.ovpn"
echo -e "=================================================="
echo -e "${CYAN}       Script By kanghoryVPN" 
echo -e "${LIGHT}=================================================="
