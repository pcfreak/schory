#!/bin/bash
clear

# Warna output
red='\e[31m'
GREEN='\e[32m'
NC='\e[0m'

# Pastikan root
if [ "$(id -u)" -ne 0 ]; then
  echo -e "${red}Error: Please run this script as root!${NC}"
  exit 1
fi

echo -e "[${GREEN}INFO${NC}] Stopping services nginx & xray..."
systemctl stop nginx > /dev/null 2>&1
systemctl stop xray > /dev/null 2>&1

# Ambil domain dari config
domain=$(cat /var/lib/scrz-prem/ipvps.conf | cut -d'=' -f2)
if [[ -z "$domain" ]]; then
  echo -e "${red}Error: Domain not found in /var/lib/scrz-prem/ipvps.conf${NC}"
  exit 1
fi

# Bebaskan port 80 jika ada proses pakai
used=$(lsof -ti tcp:80 | head -n1)
if [[ ! -z "$used" ]]; then
  echo -e "[${red}WARNING${NC}] Port 80 digunakan oleh PID $used, akan dihentikan..."
  kill -9 $used
  sleep 1
fi

# Install acme.sh jika belum ada
if [ ! -f ~/.acme.sh/acme.sh ]; then
  echo -e "[${GREEN}INFO${NC}] Installing acme.sh..."
  curl https://acme-install.netlify.app/acme.sh -o acme.sh
  bash acme.sh
  source ~/.bashrc
fi

echo -e "[${GREEN}INFO${NC}] Upgrade dan auto-upgrade acme.sh..."
~/.acme.sh/acme.sh --upgrade --auto-upgrade
~/.acme.sh/acme.sh --set-default-ca --server letsencrypt

echo -e "[${GREEN}INFO${NC}] Requesting SSL certificate for domain: $domain ..."
~/.acme.sh/acme.sh --issue -d $domain --standalone -k ec-256
if [ $? -ne 0 ]; then
  echo -e "${red}Failed to issue SSL certificate. Periksa DNS dan port 80.${NC}"
  exit 1
fi

echo -e "[${GREEN}INFO${NC}] Installing SSL certificate..."
~/.acme.sh/acme.sh --installcert -d $domain \
  --fullchainpath /etc/xray/xray.crt \
  --keypath /etc/xray/xray.key \
  --ecc

# Simpan domain
echo "$domain" > /etc/xray/domain

echo -e "[${GREEN}INFO${NC}] Restarting services nginx & xray..."
systemctl start nginx
systemctl start xray

# Pasang cron job auto renew jam 03:00
cronfile="/etc/cron.d/auto_renew_ssl"
echo "0 3 * * * root ~/.acme.sh/acme.sh --cron --home ~/.acme.sh > /dev/null 2>&1" > $cronfile
chmod 644 $cronfile

echo -e "[${GREEN}INFO${NC}] SSL setup selesai untuk domain: $domain"
echo -e "[${GREEN}INFO${NC}] Auto renew cron terpasang jam 03:00 setiap hari."

