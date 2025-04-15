#!/bin/bash
# SUPER LTS RESTORE by KANGHORY

# Warna
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

# Cek dan install pv & dialog
if ! command -v pv &> /dev/null || ! command -v dialog &> /dev/null; then
    echo -e "${RED}pv dan dialog belum terinstall. Menginstall dulu...${NC}"
    apt update -y && apt install -y pv dialog
fi

# Input Link
clear
figlet "Restore" | lolcat
echo -e "${CYAN}Masukkan link file backup dari Google Drive:${NC}"
read -rp "Link: " url

[[ -z "$url" ]] && { echo -e "${RED}Link tidak boleh kosong!${NC}"; exit 1; }

# Setup direktori restore
RESTORE_TEMP="/root/restore-temp"
mkdir -p "$RESTORE_TEMP"
cd "$RESTORE_TEMP" || exit

echo -e "${CYAN}Mengunduh file backup...${NC}"
wget -qO backup.zip "$url"

[[ ! -f "backup.zip" ]] && { echo -e "${RED}Gagal mengunduh backup. Pastikan link benar.${NC}"; exit 1; }

unzip -o backup.zip > /dev/null 2>&1
RESTORE_DIR="${RESTORE_TEMP}/backup"

[[ ! -d "$RESTORE_DIR" ]] && { echo -e "${RED}Folder 'backup' tidak ditemukan.${NC}"; exit 1; }

# Fungsi animasi file
restore_progress_file() {
    local file="$1" dest="$2"
    (
        echo "0"; sleep 0.2
        echo "30"; sleep 0.4
        echo "70"; sleep 0.4
        echo "100"; sleep 0.2
    ) | dialog --gauge "Memulihkan file $file..." 8 50 0
    [[ -f "$RESTORE_DIR/$file" ]] && pv "$RESTORE_DIR/$file" > "$dest"
}

# Fungsi animasi direktori
restore_progress_dir() {
    local dir="$1" dest="$2"
    (
        echo "0"; sleep 0.3
        echo "40"; sleep 0.5
        echo "80"; sleep 0.5
        echo "100"; sleep 0.3
    ) | dialog --gauge "Menyalin direktori $dir..." 8 50 0
    [[ -d "$RESTORE_DIR/$dir" ]] && cp -rf "$RESTORE_DIR/$dir" "$dest"
}

# Restore file & folder
restore_progress_file "passwd" "/etc/passwd"
restore_progress_file "group" "/etc/group"
restore_progress_file "shadow" "/etc/shadow"
restore_progress_file "gshadow" "/etc/gshadow"
restore_progress_file "crontab" "/etc/crontab"

restore_progress_dir "klmpk" "/etc/"
restore_progress_dir "xray" "/etc/"
restore_progress_dir "slowdns" "/etc/"
restore_progress_dir "public_html" "/home/vps/"

[[ -f "$RESTORE_DIR/nsdomain" ]] && cp -f "$RESTORE_DIR/nsdomain" /root/

# Cleanup
rm -rf "$RESTORE_TEMP"

# Ambil info client
MYIP=$(wget -qO- ipinfo.io/ip)
Name=$(curl -sS https://raw.githubusercontent.com/kanghory/schory/main/izin | grep "$MYIP" | awk '{print $2}')
Exp=$(curl -sS https://raw.githubusercontent.com/kanghory/schory/main/izin | grep "$MYIP" | awk '{print $3}')

# Konfigurasi Telegram
CONFIG_DIR="/root/.backup_config"
BOT_TOKEN_FILE="$CONFIG_DIR/bot_token"
ADMIN_ID_FILE="$CONFIG_DIR/admin_id"

[[ ! -f "$BOT_TOKEN_FILE" ]] && dialog --title "Bot Token" --inputbox "Masukkan Bot Token Telegram Anda:" 10 50 2> "$BOT_TOKEN_FILE"
[[ ! -f "$ADMIN_ID_FILE" ]] && dialog --title "Admin ID" --inputbox "Masukkan ID Admin Telegram Anda:" 10 50 2> "$ADMIN_ID_FILE"

bot_token=$(cat "$BOT_TOKEN_FILE")
admin_id=$(cat "$ADMIN_ID_FILE")

# Kirim notifikasi Telegram
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

# Dialog selesai
dialog --title "Restore Selesai" --msgbox "Restore berhasil!\n\nClient : $Name\nExpired : $Exp\nIP     : $MYIP" 10 50

echo -e "\n${GREEN}Restore selesai dan notifikasi Telegram telah dikirim!${NC}"
