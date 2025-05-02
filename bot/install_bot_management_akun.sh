#!/bin/bash
cd /etc/bot/management-akun
python3 bot_tele.py

chmod +x /etc/bot/management-akun/install_bot_management_akun.sh

BOT_DIR="/etc/bot/management-akun"
DB_FILE="$BOT_DIR/management-akun.db"

mkdir -p "$BOT_DIR"

# Buat database dan tabel token jika belum ada
sqlite3 "$DB_FILE" "CREATE TABLE IF NOT EXISTS bot_token (id INTEGER PRIMARY KEY AUTOINCREMENT, token TEXT);"

# Cek apakah token sudah ada
TOKEN=$(sqlite3 "$DB_FILE" "SELECT token FROM bot_token LIMIT 1;")
if [ -z "$TOKEN" ]; then
    read -rp "Masukkan TOKEN Bot Telegram: " BOT_TOKEN
    sqlite3 "$DB_FILE" "INSERT INTO bot_token (token) VALUES ('$BOT_TOKEN');"
    echo "Token berhasil disimpan di $DB_FILE"
else
    echo "Token sudah ada di database."
fi

REPO="https://raw.githubusercontent.com/kanghory/schory/main/"
wget -q -O /etc/systemd/system/bot_management_akun.service "${REPO}bot/bot_management_akun.service" && chmod +x bot_management_akun.service >/dev/null 2>&1
chmod +x /etc/bot/management-akun/install_bot_management_akun.sh
systemctl daemon-reexec
systemctl daemon-reload
systemctl enable bot_management_akun
systemctl start bot_management_akun


