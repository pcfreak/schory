#!/bin/bash
# SUPER LTS RESTORE by KANGHORY

# Warna
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

# Pastikan pv & dialog terinstall
if ! command -v pv &> /dev/null || ! command -v dialog &> /dev/null; then
    echo -e "${RED}pv dan dialog belum terinstall. Menginstall dulu...${NC}"
    apt update -y && apt install -y pv dialog
fi

# Input Link
clear
figlet "Restore" | lolcat
echo -e "${CYAN}Masukkan link file backup dari Google Drive:${NC}"
read -rp "Link: " url

# Setup directory
mkdir -p /root/restore-temp
cd /root/restore-temp || exit

# Download & unzip
echo -e "${CYAN}Mengunduh file backup...${NC}"
wget -qO backup.zip "$url"
unzip -o backup.zip > /dev/null 2>&1

RESTORE_DIR="/root/restore-temp/backup"

# Progress dialog loading
(
echo "10"; sleep 0.5
echo "30"; sleep 1
echo "50"; sleep 1
echo "75"; sleep 1
echo "100"; sleep 1
) | dialog --title "Proses Restore" --gauge "Mengembalikan file konfigurasi..." 10 60 0

# Restore file dengan efek loading
pv "$RESTORE_DIR/passwd" > /etc/passwd
pv "$RESTORE_DIR/group" > /etc/group
pv "$RESTORE_DIR/shadow" > /etc/shadow
pv "$RESTORE_DIR/gshadow" > /etc/gshadow
pv "$RESTORE_DIR/crontab" > /etc/crontab

cp -rf "$RESTORE_DIR/klmpk" /etc/
cp -rf "$RESTORE_DIR/xray" /etc/
cp -rf "$RESTORE_DIR/slowdns" /etc/
cp -rf "$RESTORE_DIR/public_html" /home/vps/
[[ -f "$RESTORE_DIR/nsdomain" ]] && cp -f "$RESTORE_DIR/nsdomain" /root/

# Bersihkan temp
rm -rf /root/restore-temp

# Ambil info IP & client
MYIP=$(wget -qO- ipinfo.io/ip)
Name=$(curl -sS https://raw.githubusercontent.com/kanghory/schory/main/izin | grep "$MYIP" | awk '{print $2}')
Exp=$(curl -sS https://raw.githubusercontent.com/kanghory/schory/main/izin | grep "$MYIP" | awk '{print $3}')

# Tampilkan info restore selesai
dialog --title "Restore Selesai" --msgbox "Restore berhasil dilakukan!\n\nClient : $Name\nExpired : $Exp\nIP     : $MYIP" 10 50

# Setup Telegram
CONFIG_DIR="/root/.backup_config"
mkdir -p "$CONFIG_DIR"
BOT_TOKEN_FILE="$CONFIG_DIR/bot_token"
ADMIN_ID_FILE="$CONFIG_DIR/admin_id"

if [[ ! -f "$BOT_TOKEN_FILE" ]]; then
    dialog --title "Bot Token" --inputbox "Masukkan Bot Token Telegram Anda:" 10 50 2> "$BOT_TOKEN_FILE"
fi
if [[ ! -f "$ADMIN_ID_FILE" ]]; then
    dialog --title "Admin ID" --inputbox "Masukkan ID Admin Telegram Anda:" 10 50 2> "$ADMIN_ID_FILE"
fi

bot_token=$(cat "$BOT_TOKEN_FILE")
admin_id=$(cat "$ADMIN_ID_FILE")

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

echo -e "\n${GREEN}Restore selesai dan notifikasi Telegram telah dikirim!${NC}"
