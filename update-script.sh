#!/bin/bash

# Warna
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[1;34m'
NC='\033[0m'

echo -e "${YELLOW}Checking for updates...${NC}"
sleep 2

# Hapus script lama
rm -f /usr/bin/menu
rm -f /usr/bin/menun-ssh
rm -f /usr/bin/menu_pw_host
rm -f /usr/bin/menu-backup
rm -f /usr/bin/usernew
rm -f /usr/bin/backup
rm -f /usr/bin/restore
rm -f /usr/bin/menu_limit_ip_ssh

# Download script terbaru
echo -e "${YELLOW}Downloading updated scripts...${NC}"
wget -q -O /usr/bin/menu "https://raw.githubusercontent.com/kanghory/schory/main/allmenu/menu.sh"
wget -q -O /usr/bin/menun-ssh "https://raw.githubusercontent.com/kanghory/schory/main/allmenu/menun-ssh.sh"
wget -q -O /usr/bin/menu_pw_host "https://raw.githubusercontent.com/kanghory/schory/main/allmenu/menu_pw_host.sh"
wget -q -O /usr/bin/menu-backup "https://raw.githubusercontent.com/kanghory/schory/main/allmenu/menu-backup.sh"
wget -q -O /usr/bin/usernew "https://raw.githubusercontent.com/kanghory/schory/main/allmenu/usernew.sh"
wget -q -O /usr/bin/backup "https://raw.githubusercontent.com/kanghory/schory/main/backup/backup.sh"
wget -q -O /usr/bin/restore "https://raw.githubusercontent.com/kanghory/schory/main/backup/restore.sh"
wget -q -O /usr/bin/menu_limit_ip_ssh "https://raw.githubusercontent.com/kanghory/schory/main/allmenu/menu_limit_ip_ssh.sh"

# Beri izin eksekusi
chmod +x /usr/bin/menu
chmod +x /usr/bin/menun-ssh
chmod +x /usr/bin/menu_pw_host
chmod +x /usr/bin/menu-backup
chmod +x /usr/bin/usernew
chmod +x /usr/bin/backup
chmod +x /usr/bin/restore
chmod +x /usr/bin/menu_limit_ip_ssh

# Hapus file ini jika perlu
rm -f update-script.sh

echo -e "${BLUE}--- Semua script selesai diupdate ---${NC}"
echo -e "${GREEN}Tekan Enter untuk kembali ke menu...${NC}"
read -r

# Jalankan menu utama
menu
