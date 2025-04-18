#!/bin/bash

# Warna
green='\e[32m'
red='\e[31m'
blue='\e[34m'
NC='\e[0m'

# Base URL GitHub
REPO_URL="https://raw.githubusercontent.com/kanghory/schory/main"

# Daftar script dengan format target=source
SCRIPT_LIST=(
    "/usr/bin/menu.sh=allmenu/menu.sh"
    "/usr/bin/menun-ssh.sh=allmenu/menun-ssh.sh"
    "/usr/bin/menu_pw_host.sh=allmenu/menu_pw_host.sh"
    "/usr/bin/menu-backup.sh=allmenu/menu-backup.sh"
    "/usr/bin/usernew.sh=allmenu/usernew.sh"
    "/usr/bin/backup.sh=backup/backup.sh"
    "/usr/bin/restore.sh=backup/restore.sh"
)

echo -e "${blue}--- Memulai proses update script ---${NC}"

for entry in "${SCRIPT_LIST[@]}"; do
    target_path="${entry%%=*}"
    source_path="${entry#*=}"
    file_name=$(basename "$target_path")

    echo -e "${green}Mengupdate: $file_name${NC}"

    # URL dengan bypass cache
    URL="${REPO_URL}/${source_path}?nocache=$(date +%s)"

    # Unduh dan simpan ke lokasi target
    if wget -q --show-progress -O "${target_path}" "${URL}"; then
        chmod +x "${target_path}"
        echo -e "${green}Sukses update ${file_name}${NC}"
    else
        echo -e "${red}Gagal update ${file_name}${NC}"
    fi
done

echo -e "${blue}--- Semua script selesai diupdate ---${NC}"
echo -e "${green}Tekan Enter untuk kembali ke menu...${NC}"
read -r

# Jalankan menu utama
menu.sh
