#!/bin/bash
# SL - Backup & Telegram Notification

# Warna
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

# Konfigurasi Direktori
CONFIG_DIR="/root/.backup_config"
mkdir -p "$CONFIG_DIR"

# Ambil Token & Admin Telegram
BOT_TOKEN_FILE="$CONFIG_DIR/bot_token"
ADMIN_ID_FILE="$CONFIG_DIR/admin_id"

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

# Mulai Proses Backup
clear
figlet "Backup"
echo -e "${GREEN}Backup sedang diproses untuk client: $Name ($MYIP)${NC}"

BACKUP_DIR="/backup"
BACKUP_FILE="/$MYIP-$DATE.zip"

rm -rf "$BACKUP_DIR"
mkdir -p "$BACKUP_DIR"

# Backup File Penting
cp /etc/passwd "$BACKUP_DIR/"
cp /etc/group "$BACKUP_DIR/"
cp /etc/shadow "$BACKUP_DIR/"
cp /etc/gshadow "$BACKUP_DIR/"
cp /etc/crontab "$BACKUP_DIR/"
cp -rf /etc/klmpk "$BACKUP_DIR/"
cp -rf /etc/xray "$BACKUP_DIR/xray"
cp -rf /etc/slowdns "$BACKUP_DIR/slowdns"
cp -rf /home/vps/public_html "$BACKUP_DIR/public_html"

# Backup nsdomain jika file
if [[ -f /root/nsdomain ]]; then
    cp -f /root/nsdomain "$BACKUP_DIR/nsdomain"
fi

# Buat File Zip
zip -r "$BACKUP_FILE" "$BACKUP_DIR" > /dev/null 2>&1

# Upload ke Google Drive
rclone copy "$BACKUP_FILE" dr:backup/

# Ambil Link Download
url=$(rclone link "dr:backup/$MYIP-$DATE.zip")
if [[ -n "$url" ]]; then
    id=$(echo "$url" | awk -F'=' '{print $2}')
    link="https://drive.google.com/u/4/uc?id=${id}&export=download"
else
    link="Gagal mendapatkan link backup."
fi

# IP, Tanggal, dan Jam
MYIP=$(wget -qO- ipinfo.io/ip)
DATE=$(date +"%Y-%m-%d")
TIME=$(date +"%H:%M:%S")

# Ambil Nama dan Exp dari izin online
Name=$(curl -sS https://raw.githubusercontent.com/kanghory/schory/main/izin | grep "$MYIP" | awk '{print $2}')
Exp=$(curl -sS https://raw.githubusercontent.com/kanghory/schory/main/izin | grep "$MYIP" | awk '{print $3}')

# Validasi jika kosong
if [[ -z "$Name" || -z "$Exp" ]]; then
    echo -e "${RED}Gagal mendapatkan data client dari izin!${NC}"
    exit 1
fi

# Kirim Notifikasi Telegram
message=$(cat <<EOF
<b>🧰 Backup VPS Selesai</b>

<b>┌────────────────────────────────────┐</b>
<b>│ 👤 Client    : <code>$Name</code></b>
<b>│ ⏰ Expired   : <code>$Exp</code></b>
<b>│ 🧑‍💻 Developer : KANGHORY TUNNELING</b>
<b>│ ⚙️ Version   : SUPER LTS</b>
<b>└────────────────────────────────────┘</b>

🖥️ <b>IP VPS</b>  : <code>$MYIP</code>
📅 <b>Tanggal</b> : <code>$DATE $TIME</code>
📥 <b>Link</b>    : <a href="$link">Download</a>
EOF
)

curl -s -X POST "https://api.telegram.org/bot${bot_token}/sendMessage" \
     --data-urlencode "chat_id=${admin_id}" \
     --data-urlencode "parse_mode=HTML" \
     --data-urlencode "text=${message}" > /dev/null

# Bersihkan
rm -rf "$BACKUP_DIR"
rm -f "$BACKUP_FILE"

# Tampilkan Info
clear
echo -e "${GREEN}Backup selesai! Link dikirim ke Telegram Anda.${NC}"
echo "=================================="
echo "Client      : $Name"
echo "Expired     : $Exp"
echo "IP VPS      : $MYIP"
echo "Tanggal     : $DATE"
echo "Download    : $link"
echo "=================================="
