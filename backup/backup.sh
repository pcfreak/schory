#!/bin/bash
# SL - Backup & Telegram Notification

# Warna
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

# --- Info Client ---
Name="NamaClient"       # Ganti dengan nama client
Exp="2025-12-31"        # Ganti dengan tanggal expired

# --- Direktori Config Telegram ---
CONFIG_DIR="/root/.backup_config"
mkdir -p "$CONFIG_DIR"

# IP dan Tanggal
IP=$(wget -qO- ipinfo.io/ip)
DATE=$(date +"%Y-%m-%d")
TIME=$(date +"%H:%M:%S")

# File Config Token & Admin
BOT_TOKEN_FILE="$CONFIG_DIR/bot_token"
ADMIN_ID_FILE="$CONFIG_DIR/admin_id"

# Cek token
if [[ ! -f "$BOT_TOKEN_FILE" ]]; then
    echo -e "${GREEN}Masukkan Bot Token Telegram Anda:${NC}"
    read -rp "Bot Token: " bot_token
    echo "$bot_token" > "$BOT_TOKEN_FILE"
else
    bot_token=$(cat "$BOT_TOKEN_FILE")
fi

# Cek admin ID
if [[ ! -f "$ADMIN_ID_FILE" ]]; then
    echo -e "${GREEN}Masukkan ID Admin Telegram Anda:${NC}"
    read -rp "Admin ID: " admin_id
    echo "$admin_id" > "$ADMIN_ID_FILE"
else
    admin_id=$(cat "$ADMIN_ID_FILE")
fi

# Tampilkan info
clear
figlet "Backup"
echo -e "${GREEN}Mohon tunggu, proses backup sedang berlangsung...${NC}"

# --- Proses Backup ---
BACKUP_DIR="/backup"
BACKUP_FILE="/$IP-$DATE.zip"

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

# Backup nsdomain jika file
if [[ -f /root/nsdomain ]]; then
    cp -f /root/nsdomain "$BACKUP_DIR/nsdomain"
fi

# Buat file zip
zip -r "$BACKUP_FILE" "$BACKUP_DIR" > /dev/null 2>&1

# Upload ke Google Drive
rclone copy "$BACKUP_FILE" dr:backup/

# Ambil link file
url=$(rclone link "dr:backup/$IP-$DATE.zip")
if [[ -n "$url" ]]; then
    id=$(echo "$url" | awk -F'=' '{print $2}')
    link="https://drive.google.com/u/4/uc?id=${id}&export=download"
else
    link="Gagal mendapatkan link backup."
fi

# --- Notifikasi Telegram ---
message=$(cat <<EOF
<b>🧰 Backup VPS Selesai</b>

<b>┌────────────────────────────────────┐</b>
<b>│ 👤 Client    : <code>$Name</code></b>
<b>│ ⏰ Expired   : <code>$Exp</code></b>
<b>│ 🧑‍💻 Developer : KANGHORY TUNNELING</b>
<b>│ ⚙️ Version   : SUPER LTS</b>
<b>└────────────────────────────────────┘</b>

🖥️ <b>IP VPS</b>  : <code>$IP</code>
📅 <b>Tanggal</b> : <code>$DATE $TIME</code>
📥 <b>Link</b>    : <a href="$link">Download</a>
EOF
)

# Kirim ke Telegram
curl -s -X POST "https://api.telegram.org/bot${bot_token}/sendMessage" \
     --data-urlencode "chat_id=${admin_id}" \
     --data-urlencode "parse_mode=HTML" \
     --data-urlencode "text=${message}" > /dev/null

# Hapus backup lokal
rm -rf "$BACKUP_DIR"
rm -f "$BACKUP_FILE"

# --- Info Selesai ---
clear
echo -e "${GREEN}Backup selesai! Link dikirim ke Telegram Anda.${NC}"
echo "=================================="
echo "Client      : $Name"
echo "Expired     : $Exp"
echo "IP VPS      : $IP"
echo "Tanggal     : $DATE"
echo "Download    : $link"
echo "=================================="
