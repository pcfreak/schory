#!/bin/bash
# SUPER LTS BACKUP by KANGHORY

# Warna
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

# Konfigurasi Direktori
CONFIG_DIR="/root/.backup_config"
mkdir -p "$CONFIG_DIR"

BOT_TOKEN_FILE="$CONFIG_DIR/bot_token"
ADMIN_ID_FILE="$CONFIG_DIR/admin_id"

# Ambil Token dan Admin ID Telegram
if [[ ! -f "$BOT_TOKEN_FILE" ]]; then
    echo -e "${GREEN}Masukkan Bot Token Telegram Anda:${NC}"
    read -rp "Bot Token: " bot_token
    echo "$bot_token" > "$BOT_TOKEN_FILE"
else
    bot_token=$(cat "$BOT_TOKEN_FILE")
fi

if [[ ! -f "$ADMIN_ID_FILE" ]]; then
    echo -e "${GREEN}Masukkan ID Admin Telegram Anda:${NC}"
    read -rp "Admin ID: " admin_id
    echo "$admin_id" > "$ADMIN_ID_FILE"
else
    admin_id=$(cat "$ADMIN_ID_FILE")
fi

# Cek apakah rclone sudah terpasang
if ! command -v rclone &> /dev/null; then
    echo -e "${RED}rclone tidak terpasang!${NC}"
    exit 1
else
    echo -e "${GREEN}rclone ditemukan, melanjutkan proses...${NC}"
fi

# Cek koneksi rclone ke Google Drive (pastikan remote rclone bernama 'dr')
rclone check dr:backup /tmp/test-backup > /dev/null 2>&1
if [[ $? -ne 0 ]]; then
    echo -e "${RED}Gagal terhubung ke remote Google Drive!${NC}"
    exit 1
else
    echo -e "${GREEN}Koneksi ke Google Drive berhasil!${NC}"
fi

# Cek koneksi Telegram
if ! curl -s --head "https://api.telegram.org/bot${bot_token}/getMe" | grep "200 OK" > /dev/null; then
    echo -e "${RED}Koneksi Telegram gagal!${NC}"
    exit 1
else
    echo -e "${GREEN}Koneksi Telegram berhasil!${NC}"
fi

# Ambil IP, Tanggal, dan Jam
MYIP=$(wget -qO- ipinfo.io/ip)
HOST=$(hostname)
DATE=$(date +"%Y-%m-%d")
TIME=$(date +"%H:%M:%S")
STAMP=$(date +"%Y-%m-%d-%H%M%S")
BACKUP_FILE="/root/${HOST}-${MYIP}-${STAMP}.zip"
BACKUP_DIR="/root/backup"

# Ambil nama dan Exp dari izin
Name=$(curl -sS https://raw.githubusercontent.com/kanghory/schory/main/izin | grep "$MYIP" | awk '{print $2}')
Exp=$(curl -sS https://raw.githubusercontent.com/kanghory/schory/main/izin | grep "$MYIP" | awk '{print $3}')

if [[ -z "$Name" || -z "$Exp" ]]; then
    echo -e "${RED}Gagal mendapatkan data client dari izin!${NC}"
    exit 1
fi

# Mulai proses backup
clear
figlet "Backup" | lolcat
echo -e "${CYAN}Backup sedang diproses untuk client: ${NC}$Name ($MYIP)"

# Hapus direktori backup sebelumnya jika ada
rm -rf "$BACKUP_DIR"
mkdir -p "$BACKUP_DIR"

# Backup file penting
cp /etc/passwd "$BACKUP_DIR/"
cp /etc/group "$BACKUP_DIR/"
cp /etc/shadow "$BACKUP_DIR/"
cp /etc/gshadow "$BACKUP_DIR/"
cp /etc/crontab "$BACKUP_DIR/"
cp -rf /etc/klmpk "$BACKUP_DIR/"
cp -rf /etc/xray "$BACKUP_DIR/xray"
cp -rf /etc/slowdns "$BACKUP_DIR/slowdns"
cp -rf /home/vps/public_html "$BACKUP_DIR/public_html"

[[ -f /root/nsdomain ]] && cp -f /root/nsdomain "$BACKUP_DIR/nsdomain"

# Buat file zip
cd /root && zip -r "$BACKUP_FILE" "$(basename "$BACKUP_DIR")" > /dev/null 2>&1

# Upload ke Google Drive (pastikan remote rclone bernama 'dr')
rclone copy "$BACKUP_FILE" dr:backup/

# Ambil link download
url=$(rclone link "dr:backup/$(basename "$BACKUP_FILE")")
if [[ -n "$url" ]]; then
    id=$(echo "$url" | awk -F'=' '{print $2}')
    link="https://drive.google.com/u/4/uc?id=${id}&export=download"
else
    link="Gagal mendapatkan link backup."
fi

# Kirim notifikasi Telegram
message=$(cat <<EOF
<b>🧰 Backup VPS Selesai</b>
<b>┌─────────────────────┐</b>
<b>│ 👤 Client    : <code>$Name</code></b>
<b>│ ⏰ Expired   : <code>$Exp</code></b>
<b>│ 🧑‍💻 Developer : KANGHORY TUNNELING</b>
<b>│ ⚙️ Version   : SUPER LTS</b>
🖥️ <b>IP VPS</b>  : <code>$MYIP</code>
📅 <b>Tanggal</b> : <code>$DATE $TIME</code>
📥 <b>Link</b>    : <a href="$link">Download</a>
<b>└─────────────────────┘</b>
EOF
)

curl -s -X POST "https://api.telegram.org/bot${bot_token}/sendMessage" \
    --data-urlencode "chat_id=${admin_id}" \
    --data-urlencode "parse_mode=HTML" \
    --data-urlencode "text=${message}" > /dev/null

# Bersihkan file lokal untuk menghindari beban disk
rm -rf "$BACKUP_DIR"
rm -f "$BACKUP_FILE"

# Tampilkan info
clear
echo -e "${GREEN}Backup selesai dan link dikirim ke Telegram Anda!${NC}"
echo "=================================="
echo "Client      : $Name"
echo "Expired     : $Exp"
echo "IP VPS      : $MYIP"
echo "Tanggal     : $DATE $TIME"
echo "Download    : $link"
echo "=================================="
