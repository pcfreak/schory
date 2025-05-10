#!/bin/bash

CONFIG_FILE="/etc/xray/config.json"
LOCK_DIR="/etc/klmpk/lock/trojan"
BACKUP_DIR="/etc/klmpk/backup/trojan"
BOT_FILE="/etc/bot/limitip.db"
STATUS_FILE="/tmp/status-trojan.log"

[[ -f "$BOT_FILE" ]] || exit
read -r _ bottoken idtelegram < <(grep '^#bot#' "$BOT_FILE")
[[ -z "$bottoken" || -z "$idtelegram" ]] && exit

# Jalankan skrip cek user online & simpan statusnya
bash /usr/bin/cek-user-online-trojan > "$STATUS_FILE"

# Baca user yang statusnya 'Melebihi'
grep -E '\x1b\[31mMelebihi\x1b\[0m' "$STATUS_FILE" | while read -r line; do
    USER=$(echo "$line" | awk '{print $1}')
    [[ -z "$USER" ]] && continue

    [[ -f "$LOCK_DIR/$USER.lock" ]] && continue  # Sudah dikunci, skip

    # Backup akun
    jq ".inbounds[].settings.clients[] | select(.email==\"$USER\")" "$CONFIG_FILE" > "$BACKUP_DIR/$USER.json"

    # Hapus dari config.json
    jq --arg user "$USER" '(.inbounds[].settings.clients) |= map(select(.email != $user))' "$CONFIG_FILE" > /tmp/config.tmp && mv /tmp/config.tmp "$CONFIG_FILE"

    # Restart Xray
    systemctl restart xray

    # Paksa diskonek berdasarkan IP aktif (ambil dari log 1 menit)
    IP_LIST=$(awk -v u="$USER" '$0 ~ "email: " u {
        for (i=1;i<=NF;i++) {
            if ($i ~ /^from$/ && $(i+1) ~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:/)
                print $(i+1)
        }
    }' /var/log/xray/access.log | cut -d':' -f1 | sort -u)

    for ip in $IP_LIST; do
        IP3=$(echo $ip | cut -d'.' -f1-3)
        pkill -f "xray.*$IP3"
    done

    # Tulis lock & set timer unlock (default 15 menit)
    echo $(( $(date +%s) + 900 )) > "$LOCK_DIR/$USER.lock"

    # Kirim Notif Telegram
    curl -s -X POST "https://api.telegram.org/bot${bottoken}/sendMessage" \
        -d chat_id="${idtelegram}" \
        -d text="Akun Trojan *$USER* melebihi batas IP, akun *dikunci sementara* selama 15 menit." \
        -d parse_mode="Markdown"
done

# Proses unlock akun yang waktunya selesai
for file in "$LOCK_DIR"/*.lock; do
    [[ ! -f "$file" ]] && continue
    USER=$(basename "$file" .lock)
    UNLOCK_TIME=$(cat "$file")
    NOW=$(date +%s)

    if (( NOW >= UNLOCK_TIME )); then
        # Restore dari backup
        [[ -f "$BACKUP_DIR/$USER.json" ]] || continue
        TMP_JSON=$(mktemp)

        jq --argjson user "$(cat "$BACKUP_DIR/$USER.json")" \
            '(.inbounds[].settings.clients) += [$user]' "$CONFIG_FILE" > "$TMP_JSON" && mv "$TMP_JSON" "$CONFIG_FILE"

        systemctl restart xray
        rm -f "$file" "$BACKUP_DIR/$USER.json"

        curl -s -X POST "https://api.telegram.org/bot${bottoken}/sendMessage" \
            -d chat_id="${idtelegram}" \
            -d text="Akun Trojan *$USER* sudah *dibuka kembali* setelah dikunci 15 menit." \
            -d parse_mode="Markdown"
    fi
done
