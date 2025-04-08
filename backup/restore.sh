#!/bin/bash
# SL - Restore Data VPS

# ==========================================
# Warna
RED='\033[0;31m'
NC='\033[0m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'

# ==========================================
# Awal
clear
figlet "Restore" | lolcat
echo -e "${CYAN}Restore ini hanya berfungsi jika file backup berasal dari autoscript ini.${NC}"
echo -e "${GREEN}Silakan masukkan link Google Drive backup ZIP Anda:${NC}"
read -rp "Link File Backup: " url

# ==========================================
# Unduh dan Ekstrak
cd /root || exit
wget -O backup.zip "$url"

if [[ ! -f backup.zip ]]; then
    echo -e "${RED}Gagal mengunduh file backup.${NC}"
    exit 1
fi

unzip -o backup.zip -d /root/restore-temp > /dev/null 2>&1
rm -f backup.zip
echo -e "${GREEN}Backup berhasil diekstrak.${NC}"

# ==========================================
# Mulai Restore
RESTORE_DIR="/root/restore-temp"

echo -e "${CYAN}Memulai proses restore...${NC}"

# File penting sistem
cp -f "$RESTORE_DIR/passwd" /etc/
cp -f "$RESTORE_DIR/group" /etc/
cp -f "$RESTORE_DIR/shadow" /etc/
cp -f "$RESTORE_DIR/gshadow" /etc/
cp -f "$RESTORE_DIR/crontab" /etc/

# Direktori dan file konfigurasi
rsync -a "$RESTORE_DIR/klmpk/" /etc/klmpk/
rsync -a "$RESTORE_DIR/xray/" /etc/xray/
rsync -a "$RESTORE_DIR/nsdomain/" /root/nsdomain/
rsync -a "$RESTORE_DIR/slowdns/" /etc/slowdns/
rsync -a "$RESTORE_DIR/public_html/" /home/vps/public_html/

# Bersihkan
rm -rf "$RESTORE_DIR"

echo -e "${GREEN}Restore selesai! Silakan reboot jika diperlukan.${NC}"
