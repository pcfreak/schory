#!/bin/bash
# SL - Restore Config & Telegram Notif (with loading)

# Warna
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

# Fungsi animasi loading
loading() {
    local pid=$!
    local spin='-\|/'
    local i=0
    tput civis
    while kill -0 "$pid" 2>/dev/null; do
        i=$(( (i+1) %4 ))
        printf "\r${CYAN}Proses restore sedang berjalan ${spin:$i:1}${NC}"
        sleep 0.1
    done
    tput cnorm
    echo -e "\r${GREEN}Restore file selesai.${NC}"
}

# Input Link Backup
clear
figlet "Restore" | lolcat
echo -e "${CYAN}Silakan input link file backup dari Google Drive:${NC}"
read -rp "Link: " url

# Download dan Ekstrak
mkdir -p /root/restore-temp
cd /root/restore-temp || exit
wget -q --show-progress -O backup.zip "$url"
unzip -o backup.zip > /dev/null 2>&1
RESTORE_DIR="/root/restore-temp/backup"

# Mulai proses restore dengan loading
{
    cp -f "$RESTORE_DIR/passwd" /etc/
    cp -f "$RESTORE_DIR/group" /etc/
    cp -f "$RESTORE_DIR/shadow" /etc/
    cp -f "$RESTORE_DIR/gshadow" /etc/
    cp -f "$RESTORE_DIR/crontab" /etc/

    cp -rf "$RESTORE_DIR/klmpk" /etc/
    cp -rf "$RESTORE_DIR/xray" /etc/
    cp -rf "$RESTORE_DIR/slowdns" /etc/
    cp -rf "$RESTORE_DIR/public_html" /home/vps/

    [[ -f "$RESTORE_DIR/nsdomain" ]] && cp -f "$RESTORE_DIR/nsdomain" /root/
} & loading

# Bersihkan folder sementara
rm -rf /root/restore-temp

# Ambil IP dan Data Client
MYIP=$(wget -qO- ipinfo.io/ip)
Name=$(curl -sS https://raw.githubusercontent.com/kanghory/schory/main/izin | grep "$MYIP" | awk '{print $2}')
Exp=$(curl -sS https://raw.githubusercontent.com/kanghory/schory/main/izin | grep "$MYIP" | awk '{print $3}')

# Ambil atau Input Bot Token & Admin ID
CONFIG_DIR="/root/.backup_config"
mkdir -p "$CONFIG_DIR"

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

echo -e "${GREEN}Notifikasi Telegram terkirim.${NC}"
