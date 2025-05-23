#!/bin/bash
clear

red='\e[31m'
GREEN='\e[32m'
NC='\e[0m'

if [ "$(id -u)" -ne 0 ]; then
  echo -e "${red}Error: Please run this script as root!${NC}"
  exit 1
fi

echo -e "[${GREEN}INFO${NC}] Stopping services nginx & xray..."
systemctl stop nginx > /dev/null 2>&1
systemctl stop xray > /dev/null 2>&1

domain=$(cat /var/lib/scrz-prem/ipvps.conf | cut -d'=' -f2)
if [[ -z "$domain" ]]; then
  echo -e "${red}Error: Domain not found in /var/lib/scrz-prem/ipvps.conf${NC}"
  exit 1
fi

used=$(lsof -ti tcp:80 | head -n1)
if [[ ! -z "$used" ]]; then
  echo -e "[${red}WARNING${NC}] Port 80 digunakan oleh PID $used, akan dihentikan..."
  kill -9 $used
  sleep 1
fi

if [ ! -f ~/.acme.sh/acme.sh ]; then
  echo -e "[${GREEN}INFO${NC}] Installing acme.sh..."
  curl https://acme-install.netlify.app/acme.sh -o acme.sh
  bash acme.sh
  source ~/.bashrc
fi

echo -e "[${GREEN}INFO${NC}] Upgrade dan auto-upgrade acme.sh..."
~/.acme.sh/acme.sh --upgrade --auto-upgrade
~/.acme.sh/acme.sh --set-default-ca --server letsencrypt

echo -e "[${GREEN}INFO${NC}] Checking existing certificate..."
cert_path="/etc/xray/xray.crt"
key_path="/etc/xray/xray.key"

if [ -f "$cert_path" ] && [ -f "$key_path" ]; then
  echo -e "[${GREEN}INFO${NC}] Certificate found, renewing with --force ..."
  ~/.acme.sh/acme.sh --issue -d $domain --standalone -k ec-256 --force
else
  echo -e "[${GREEN}INFO${NC}] No certificate found, issuing new certificate..."
  ~/.acme.sh/acme.sh --issue -d $domain --standalone -k ec-256
fi

if [ $? -ne 0 ]; then
  echo -e "${red}Failed to issue/renew SSL certificate. Periksa DNS dan port 80.${NC}"
  exit 1
fi

echo -e "[${GREEN}INFO${NC}] Installing SSL certificate..."
~/.acme.sh/acme.sh --installcert -d $domain \
  --fullchainpath $cert_path \
  --keypath $key_path \
  --ecc

echo "$domain" > /etc/xray/domain

echo -e "[${GREEN}INFO${NC}] Restarting services nginx & xray..."
systemctl start nginx
systemctl start xray

cronfile="/etc/cron.d/auto_renew_ssl"
echo "0 3 * * * root ~/.acme.sh/acme.sh --cron --home ~/.acme.sh > /dev/null 2>&1" > $cronfile
chmod 644 $cronfile

echo -e "[${GREEN}INFO${NC}] SSL setup selesai untuk domain: $domain"
echo -e "[${GREEN}INFO${NC}] Auto renew cron terpasang jam 03:00 setiap hari."
