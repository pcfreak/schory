#!/bin/bash
# SL - Restore & Telegram Notification

# Warna
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

# Setup Direktori Config
CONFIG_DIR="/root/.backup_config"
BOT_TOKEN_FILE="$CONFIG_DIR/bot_token"
ADMIN_ID_FILE="$CONFIG_DIR/admin_id"

# Ambil Token & Admin ID Telegram
if [[ -f "$BOT_TOKEN_FILE" ]]; then
    bot_token=$(cat "$BOT_TOKEN_FILE")
else
    echo -e "${RED}Bot Token tidak ditemukan! Jalankan script backup terlebih dahulu.${NC}"
    exit 1
fi

if [[ -f "$ADMIN_ID_FILE" ]]; then
    admin_id=$(cat "$ADMIN_ID_FILE")
else
    echo -e "${RED}Admin ID Telegram tidak ditemukan! Jalankan script backup terlebih dahulu.${NC}"
    exit 1
fi

# Ambil IP dan Info Client
MYIP=$(wget -qO- ipinfo.io/ip)
Name=$(curl -sS https://raw.githubusercontent.com/kanghory/schory/main/izin | grep "$MYIP" | awk '{print $2}')
Exp=$(curl -sS https://raw.githubusercontent.com/kanghory/schory/main/izin | grep "$MYIP" | awk '{print $3}')

if [[ -z "$Name" || -z "$Exp" ]]; then
    echo -e "${RED}Gagal mendapatkan data client dari izin!${NC}"
    exit 1
fi

# Minta Link Backup
clear
figlet "Restore" | lolcat
echo -e "${CYAN}Silakan input link file backup dari Google Drive:${NC}"
read -rp "Link: " url

# Unduh dan Ekstrak
mkdir -p /root/restore-temp
cd /root/restore-temp || exit
wget -O backup.zip "$url"
unzip -o backup.zip > /dev/null 2>&1
RESTORE_DIR="/root/restore-temp/backup"

# Proses Restore
echo -e "${GREEN}Memulai proses restore...${NC}"

cp -f "$RESTORE_DIR/passwd" /etc/
cp -f "$RESTORE_DIR/group" /etc/
cp -f "$RESTORE_DIR/shadow" /etc/
cp -f "$RESTORE_DIR/gshadow" /etc/
cp -f "$RESTORE_DIR/crontab" /etc/

cp -rf "$RESTORE_DIR/klmpk" /etc/
cp -rf "$RESTORE_DIR/xray" /etc/
cp -rf "$RESTORE_DIR/slowdns" /etc/
cp -rf "$RESTORE_DIR/public_html" /home/vps/

if [[ -f "$RESTORE_DIR/nsdomain" ]]; then
    cp -f "$RESTORE_DIR/nsdomain" /root/
fi

# Notifikasi Telegram
message=$(cat <<EOF
<b>♻️ Restore Selesai</b>

<b>┌────────────────────────────────────┐</b>
<b>│ 👤 Client    : <code>$Name</code></b>
<b>│ ⏰ Expired   : <code>$Exp</code></b>
<b>│ 🧑‍💻 Developer : KANGHORY TUNNELING</b>
<b>│ ⚙️ Version   : SUPER LTS</b>
<b>└────────────────────────────────────┘</b>

✅ File konfigurasi berhasil dikembalikan.
EOF
)

curl -s -X POST "https://api.telegram.org/bot${bot_token}/sendMessage" \
     --data-urlencode "chat_id=${admin_id}" \
     --data-urlencode "parse_mode=HTML" \
     --data-urlencode "text=${message}" > /dev/null

# Bersihkan
rm -rf /root/restore-temp

# Tampilkan Hasil
echo -e "${GREEN}Restore berhasil! Silakan cek Telegram Anda.${NC}"
