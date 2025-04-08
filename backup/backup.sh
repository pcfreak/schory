#!/bin/bash
# SL - Backup & Telegram Notification

# ==========================================
# Warna
RED='\033[0;31m'
NC='\033[0m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
LIGHT='\033[0;37m'

# ==========================================
# Setup Direktori Penyimpanan Konfigurasi
CONFIG_DIR="/root/.backup_config"
mkdir -p "$CONFIG_DIR"

# Mendapatkan IP dan Tanggal
IP=$(wget -qO- ipinfo.io/ip)
DATE=$(date +"%Y-%m-%d")

# ==========================================
# Setup Bot Token dan Admin ID Telegram
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

clear
figlet "Backup"
echo -e "${GREEN}Mohon Menunggu, Proses Backup sedang berlangsung !!${NC}"

# ==========================================
# Proses Backup
BACKUP_DIR="/backup"
BACKUP_FILE="/root/${IP}-${DATE}.zip"
LOG_FILE="/root/backup-log.txt"

rm -rf "$BACKUP_DIR"
mkdir -p "$BACKUP_DIR"

# Salin file sistem penting
cp /etc/passwd "$BACKUP_DIR/"
cp /etc/group "$BACKUP_DIR/"
cp /etc/shadow "$BACKUP_DIR/"
cp /etc/gshadow "$BACKUP_DIR/"
cp /etc/crontab "$BACKUP_DIR/"

# Salin direktori yang diperlukan
rsync -a /etc/klmpk/ "$BACKUP_DIR/klmpk/"
rsync -a /etc/xray/ "$BACKUP_DIR/xray/"
rsync -a /root/nsdomain/ "$BACKUP_DIR/nsdomain/"
rsync -a /etc/slowdns/ "$BACKUP_DIR/slowdns/"
rsync -a /home/vps/public_html/ "$BACKUP_DIR/public_html/"

# Buat file zip
cd /backup
zip -r "$BACKUP_FILE" ./* > /dev/null 2>&1
cd

# Cek apakah file zip berhasil dibuat
if [[ ! -f "$BACKUP_FILE" ]]; then
    curl -s -X POST "https://api.telegram.org/bot${bot_token}/sendMessage" \
        --data-urlencode "chat_id=${admin_id}" \
        --data-urlencode "text=Gagal membuat file backup!" \
        --data-urlencode "parse_mode=HTML"
    exit 1
fi

# ==========================================
# Upload ke Google Drive via rclone
if ! rclone about dr: &>/dev/null; then
    echo -e "${RED}Gagal terhubung ke Google Drive (rclone)!${NC}"
    exit 1
fi

rclone copy "$BACKUP_FILE" dr:backup/

# Dapatkan Link Backup
url=$(rclone link "dr:backup/${IP}-${DATE}.zip")
if [[ -n "$url" ]]; then
    id=$(echo "$url" | awk -F'=' '{print $2}')
    link="https://drive.google.com/u/4/uc?id=${id}&export=download"
else
    link="Gagal mendapatkan link backup."
fi

# ==========================================
# Kirim Notifikasi ke Telegram
message=$(cat <<EOF
<b>🔹 Backup Selesai!</b>

📌 <b>Detail Backup</b>
━━━━━━━━━━━━━━━━━━
🖥️ IP VPS  : <code>$IP</code>
📅 Tanggal : <code>$DATE</code>
📥 Link    : <a href="$link">Download</a>
━━━━━━━━━━━━━━━━━━
EOF
)

response=$(curl -s -X POST "https://api.telegram.org/bot${bot_token}/sendMessage" \
     --data-urlencode "chat_id=${admin_id}" \
     --data-urlencode "parse_mode=HTML" \
     --data-urlencode "text=${message}")

if [[ $(echo "$response" | jq -r '.ok') == "true" ]]; then
    echo -e "${GREEN}Notifikasi berhasil dikirim ke Telegram.${NC}"
else
    echo -e "${RED}Gagal mengirim notifikasi ke Telegram!${NC}"
    echo "Response Telegram: $response"
fi

# ==========================================
# Bersihkan dan Logging
rm -rf "$BACKUP_DIR"
rm -f "$BACKUP_FILE"
echo "[$DATE] Backup sukses - $IP - $link" >> "$LOG_FILE"

# Tampilkan Hasil di Terminal
clear
echo -e "${GREEN}Detail Backup${NC}"
echo "=================================="
echo "IP VPS        : $IP"
echo "Link Backup   : $link"
echo "Tanggal       : $DATE"
echo "=================================="
echo -e "${GREEN}Silahkan cek Telegram Anda!${NC}"
