#!/bin/bash

LIMIT_DIR="/etc/klmpk/limit/trojan/ip"
LOG_FILE="/var/log/xray/access.log"
CONFIG_FILE="/etc/xray/config.json"
BACKUP_DIR="/etc/klmpk/backup/trojan"
LOCK_DIR="/etc/klmpk/lock/trojan"
BOT_FILE="/etc/bot/limitip.db"
NOW=$(date +%s)
ONE_MIN_AGO=$((NOW - 60))

mkdir -p "$BACKUP_DIR" "$LOCK_DIR"

[[ -f "$BOT_FILE" ]] || exit
read -r _ BOTTOKEN IDTELEGRAM < <(grep '^#bot#' "$BOT_FILE")
[[ -z "$BOTTOKEN" || -z "$IDTELEGRAM" ]] && exit

# Ambil user aktif
USERS=$(awk -v t=$ONE_MIN_AGO '$0 ~ /email:/ {
    split($0, a, " ");
    gsub("email:", "", a[length(a)]);
    cmd="date -d \"" a[1] " " a[2] "\" +%s";
    cmd | getline logtime;
    close(cmd);
    if (logtime >= t) print a[length(a)];
}' "$LOG_FILE" | sort | uniq)

for USER in $USERS; do
    LIMIT_FILE="$LIMIT_DIR/$USER"
    [ -f "$LIMIT_FILE" ] && LIMIT_IP=$(cat "$LIMIT_FILE") || LIMIT_IP=1

    # Hitung IP unik (3 oktet)
    USER_IPS=$(awk -v t=$ONE_MIN_AGO -v u="$USER" '$0 ~ "email: " u {
        split($0, a, " ");
        gsub("email:", "", a[length(a)]);
        cmd="date -d \"" a[1] " " a[2] "\" +%s";
        cmd | getline logtime;
        close(cmd);
        if (logtime >= t) {
            for (i=1;i<=NF;i++) {
                if ($i ~ /^from$/ && $(i+1) ~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:/)
                    print $(i+1)
            }
        }
    }' "$LOG_FILE" | cut -d':' -f1 | cut -d'.' -f1,2,3 | sort -u)

    IP_AKTIF=$(echo "$USER_IPS" | wc -l)
    TOLERANSI=$(( (IP_AKTIF + 1) / 2 ))

    # Cek apakah melebihi
    if [ "$TOLERANSI" -gt "$LIMIT_IP" ]; then
        # Sudah dikunci belum?
        [ -f "$LOCK_DIR/$USER.lock" ] && continue

        # Backup akun
        jq --arg user "$USER" '.inbounds[].settings.clients[] | select(.email == $user)' "$CONFIG_FILE" > "$BACKUP_DIR/$USER.json"
        # Hapus dari config
        jq --arg user "$USER" '(.inbounds[].settings.clients) |= map(select(.email != $user))' "$CONFIG_FILE" > /tmp/config.tmp && mv /tmp/config.tmp "$CONFIG_FILE"
        systemctl restart xray

        # Tandai lock
        echo $((NOW + 900)) > "$LOCK_DIR/$USER.lock"

        # Notifikasi
        curl -s -X POST https://api.telegram.org/bot${BOTTOKEN}/sendMessage \
            -d chat_id="${IDTELEGRAM}" \
            -d text="Akun Trojan $USER melebihi batas IP ($IP_AKTIF IP aktif / batas $LIMIT_IP), akun terkunci selama 15 menit!"
    fi
done

# Cek akun yang perlu dibuka
for FILE in "$LOCK_DIR"/*.lock; do
    [ -e "$FILE" ] || continue
    USER=$(basename "$FILE" .lock)
    UNLOCK_TIME=$(cat "$FILE")
    [ "$NOW" -lt "$UNLOCK_TIME" ] && continue

    # Kembalikan user
    [ -f "$BACKUP_DIR/$USER.json" ] || continue
    jq --argjson user "$(cat "$BACKUP_DIR/$USER.json")" \
        '.inbounds[].settings.clients += [$user]' "$CONFIG_FILE" > /tmp/config.tmp && mv /tmp/config.tmp "$CONFIG_FILE"
    systemctl restart xray

    rm -f "$LOCK_DIR/$USER.lock" "$BACKUP_DIR/$USER.json"

    # Notif buka kembali
    curl -s -X POST https://api.telegram.org/bot${BOTTOKEN}/sendMessage \
        -d chat_id="${IDTELEGRAM}" \
        -d text="Akun Trojan $USER telah dibuka kembali setelah dikunci selama 15 menit."
done
