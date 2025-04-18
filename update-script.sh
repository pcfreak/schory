#!/bin/bash

# Warna
green='\e[32m'
red='\e[31m'
blue='\e[34m'
NC='\e[0m'

# URL base repo GitHub
REPO_URL="https://raw.githubusercontent.com/kanghory/schory/main/allmenu"

# Direktori lokal tempat script akan disimpan
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
    # Hapus file lama sebelum mengunduh yang baru
    echo -e "${green}Menghapus file lama: $script...${NC}"
    rm -f "${SCRIPT_DIR}/${script}"

    # Update file
    echo -e "${green}Mengupdate: $script...${NC}"
    wget -q -O "${SCRIPT_DIR}/${script}" "${REPO_URL}/${script}"
    chmod +x "${SCRIPT_DIR}/${script}"
    if [[ -f "${SCRIPT_DIR}/${script}" ]]; then
        echo -e "${green}Sukses update ${script}${NC}"
    else
        echo -e "${red}Gagal update ${script}${NC}"
    fi
done

echo -e "${blue}--- Proses update selesai ---${NC}"

# Tunggu user tekan Enter untuk kembali ke menu
echo -e "${green}Tekan Enter untuk kembali ke menu...${NC}"
read -r

# Jalankan menu.sh setelah Enter
menu.sh
