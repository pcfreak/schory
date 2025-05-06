#!/bin/bash
# Color & Format
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

EROR="[${RED} EROR ${NC}]"
OKEY="[${GREEN} OKEY ${NC}]"

# Spinner function
spinner() {
    local pid=$!
    local spin='|/-\'
    local i=0
    while kill -0 $pid 2>/dev/null; do
        i=$(( (i+1) %4 ))
        printf "\r${YELLOW}Restarting... ${spin:$i:1}${NC}"
        sleep 0.1
    done
    printf "\r"
}

# Restart service with animation and result
restart_service() {
    local service=$1
    {
        /etc/init.d/$service restart &>/dev/null || systemctl restart $service &>/dev/null
    } &
    spinner $!
    if [ $? -eq 0 ]; then
        echo -e "${OKEY} ${GREEN}$service restarted successfully.${NC}"
    else
        echo -e "${EROR} ${RED}Failed to restart $service!${NC}"
    fi
}

# Main Display
clear
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "\e[44;1;39m                RESTART ALL SERVICE              \e[0m"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# List of services
services=("nginx" "dropbear" "ssh" "stunnel4" "vnstat" "squid" "xray" "openvpn" "fail2ban")

for svc in "${services[@]}"; do
    restart_service "$svc"
done

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}          Terimakasih sudah menggunakan         "
echo -e "                    Script Premium KANGHORY"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
read -n 1 -s -r -p "Tekan ENTER untuk kembali ke menu utama..."
menu
