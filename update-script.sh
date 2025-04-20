#!/bin/bash
echo -e cheking update
sleep 2
#hapus
rm -f /usr/bin/update-script
rm -f /usr/bin/menu
rm -f /usr/bin/menun-ssh
rm -f /usr/bin/menu_pw_host
rm -f /usr/bin/menu-backup
rm -f /usr/bin/usernew
rm -f /usr/bin/backup
rm -f /usr/bin/restore
#download
wget -q -O /usr/bin/update-script "https://raw.githubusercontent.com/kanghory/schory/main/update-script.sh"
wget -O /usr/bin/menu "https://raw.githubusercontent.com/kanghory/schory/main/allmenu/menu.sh"
wget -O /usr/bin/menun-ssh "https://raw.githubusercontent.com/kanghory/schory/main/allmenu/menun-ssh.sh"
wget -O /usr/bin/menu_pw_host "https://raw.githubusercontent.com/kanghory/schory/main/allmenu/menu_pw_host.sh"
wget -O /usr/bin/menu-backup "https://raw.githubusercontent.com/kanghory/schory/main/allmenu/menu-backup.sh"
wget -O /usr/bin/usernew "https://raw.githubusercontent.com/kanghory/schory/main/allmenu/usernew.sh"
wget -O /usr/bin/backup "https://raw.githubusercontent.com/kanghory/schory/main/backup/backup.sh"
wget -O /usr/bin/restore "https://raw.githubusercontent.com/kanghory/schory/main/backup/restore.sh"
#izin
chmod +x /usr/bin/update-script
chmod +x /usr/bin/menu
chmod +x /usr/bin/menun-ssh
chmod +x /usr/bin/menu_pw_host
chmod +x /usr/bin/menu-backup
chmod +x /usr/bin/usernew
chmod +x /usr/bin/backup
chmod +x /usr/bin/restore
rm -rf update-script.sh

echo -e "${blue}--- Semua script selesai diupdate ---${NC}"
echo -e "${green}Tekan Enter untuk kembali ke menu...${NC}"
read -r

# Jalankan menu utama
menu
