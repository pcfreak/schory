#!/bin/bash

LIMIT_DIR="/etc/klmpk/limit/trojan/ip"
CONFIG_FILE="/etc/xray/config.json"
BACKUP_DIR="/etc/klmpk/backup/trojan"
LOCK_DIR="/etc/klmpk/lock/trojan"
BOT_FILE="/etc/bot/limitip.db"
LOG_FILE="/var/log/xray/access.log"
TEMP_STATUS="/tmp/status-trojan-limit.txt"
DURASI_LOCK=900  # Default 15 menit (dalam detik)

# Cek bot
[[ -f "$BOT_FILE" ]] || exit 0
read -r _ bottoken idtelegram < <(grep '^#bot#' "$BOT_FILE")
[[ -z "$bottoken" || -z "$idtelegram" ]] && exit 0

mkdir -p "$BACKUP_DIR" "$LOCK_DIR"

# Jalankan script cek user online tanpa input
/usr/bin/cek-user-online-trojan-noinput > "$TEMP_STATUS"

# Baca baris hasil status (parsing aman)
grep -E "^\w" "$TEMP_STATUS" | tail -n +5 | awk '{print $1,$2,$3,$4,$5}' | while read -r user ipaktif limitip toleransi status; do
    user=$(echo "$user" | tr -d '[:space:]')
    limitip=$(echo "$limitip" | tr -d '[:space:]')
    toleransi=$(echo "$toleransi" | tr -d '[:space:]')

    [[ -z "$user" || -z "$limitip" || -z "$toleransi" ]] && continue

    if [[ "$toleransi" -gt "$limitip" ]]; then
        if [[ ! -f "$LOCK_DIR/$user.lock" ]]; then
            # Backup
            jq ".inbounds[].settings.clients[] | select(.email==\"$user\")" "$CONFIG_FILE" > "$BACKUP_DIR/$user.json"

            # Hapus akun dari config
            TMP=$(mktemp)
            jq "(.inbounds[].settings.clients) |= map(select(.email!=\"$user\"))" "$CONFIG_FILE" > "$TMP" && mv "$TMP" "$CONFIG_FILE"
            systemctl restart xray

            date +%s > "$LOCK_DIR/$user.lock"

            curl -s -X POST "https://api.telegram.org/bot${bottoken}/sendMessage" \
                -d chat_id="${idtelegram}" \
                -d text="Akun Trojan *$user* melebihi batas IP, akun *terkunci!*" \
                -d parse_mode="Markdown" > /dev/null
        fi
    fi
done

# Cek akun yang waktunya dibuka kembali
for lock_file in "$LOCK_DIR"/*.lock; do
    [[ -f "$lock_file" ]] || continue
    user=$(basename "$lock_file" .lock)
    waktu_kunci=$(cat "$lock_file")
    sekarang=$(date +%s)
    selisih=$((sekarang - waktu_kunci))

    if [[ "$selisih" -ge "$DURASI_LOCK" ]]; then
        if [[ -f "$BACKUP_DIR/$user.json" ]]; then
            TMP=$(mktemp)
            jq --argjson data "$(cat "$BACKUP_DIR/$user.json")" \
               '(.inbounds[].settings.clients) += [$data]' "$CONFIG_FILE" > "$TMP" && mv "$TMP" "$CONFIG_FILE"
            systemctl restart xray

            rm -f "$lock_file" "$BACKUP_DIR/$user.json"

            curl -s -X POST "https://api.telegram.org/bot${bottoken}/sendMessage" \
                -d chat_id="${idtelegram}" \
                -d text="Akun Trojan *$user* sudah dibuka kembali setelah terkunci 15 menit." \
                -d parse_mode="Markdown" > /dev/null
        fi
    fi
done
