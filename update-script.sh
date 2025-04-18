#!/bin/bash

# Warna
green='\e[32m'
red='\e[31m'
blue='\e[34m'
NC='\e[0m'

# Base URL GitHub
REPO_URL="https://raw.githubusercontent.com/kanghory/schory/main/allmenu"

# Direktori penyimpanan script
SCRIPT_DIR="/usr/bin"

# Daftar script yang akan diupdate
SCRIPT_LIST=(
    "menu.sh"
    "menun-ssh.sh"
    "menu_pw_host.sh"
    "menu-backup.sh"
    "usernew.sh"
    "add-ssh.sh"
    "backup.sh"
    "restore.sh"
)

echo -e "${blue}--- Memulai proses update script ---${NC}"

for script in "${SCRIPT_LIST[@]}"; do
    echo -e "${green}Mengupdate: $script${NC}"
    
    # Tambahkan parameter waktu untuk bypass cache GitHub
    URL="${REPO_URL}/${script}?nocache=$(date +%s)"
    
    # Unduh dan timpa script lama
    if wget -q --show-progress -O "${SCRIPT_DIR}/${script}" "${URL}"; then
        chmod +x "${SCRIPT_DIR}/${script}"
        echo -e "${green}Sukses update ${script}${NC}"
    else
        echo -e "${red}Gagal update ${script}${NC}"
    fi
done

echo -e "${blue}--- Semua script selesai diupdate ---${NC}"
echo -e "${green}Tekan Enter untuk kembali ke menu...${NC}"
read -r

# Jalankan menu utama
menu.sh
