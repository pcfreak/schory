#!/bin/bash

LIMIT_DIR="/etc/klmpk/limit/trojan/ip"
LOG_FILE="/var/log/xray/access.log"
NOW=$(date +%s)
ONE_MIN_AGO=$((NOW - 60))
LOCK_TIME_DEFAULT=900  # 15 menit

# File database bot Telegram
BOT_FILE="/etc/bot/limitip.db"
[[ -f "$BOT_FILE" ]] || exit 1
read -r _ bottoken idtelegram < <(grep '^#bot#' "$BOT_FILE")
[[ -z "$bottoken" || -z "$idtelegram" ]] && exit 1

# Ambil semua user Trojan aktif dalam 1 menit terakhir
USERS=$(awk -v t=$ONE_MIN_AGO '$0 ~ /email:/ {
    split($0, a, " ");
    gsub("email:", "", a[length(a)]);
    cmd="date -d \"" a[1] " " a[2] "\" +%s";
    cmd | getline logtime;
    close(cmd);
    if (logtime >= t) print a[length(a)];
}' "$LOG_FILE" | sort | uniq)

if [ -z "$USERS" ]; then
    echo "Tidak ada user Trojan yang aktif dalam 1 menit terakhir."
    exit 0
fi

echo "──────────────────────────────────────────────────────────────"
echo "              • TROJAN ONLINE NOW (Last 1 Min) •"
echo "──────────────────────────────────────────────────────────────"
echo "USERNAME        IP AKTIF        LIMIT IP        TOLERANSI IP     STATUS"
echo "──────────────────────────────────────────────────────────────"

for USER in $USERS; do
    LIMIT_FILE="$LIMIT_DIR/$USER"
    
    if [ ! -f "$LIMIT_FILE" ]; then
        LIMIT_IP=1
    else
        LIMIT_IP=$(cat "$LIMIT_FILE")
    fi
    
    # Ambil IP dari log dalam 1 menit terakhir
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

    # Membandingkan toleransi dengan limit IP
    if [ "$TOLERANSI" -gt "$LIMIT_IP" ]; then
        # Jika melebihi limit, kunci akun
        echo "$USER melebihi limit IP. Mengunci akun..."

        # Simpan log penguncian
        echo "$(date): $USER melebihi limit IP, akun terkunci." >> /var/log/trojan-lock.log

        # Kirim notifikasi ke Telegram
        curl -s -X POST https://api.telegram.org/bot${bottoken}/sendMessage \
            -d chat_id="${idtelegram}" \
            -d text="Akun Trojan $USER melebihi batas IP, akun terkunci!"

        # Kunci akun (misalnya pindahkan ke direktori backup atau tambahkan status lock pada config)
        mv "$LIMIT_DIR/$USER" "$LIMIT_DIR/locked/$USER"
        
        # Durasi default penguncian akun 15 menit
        echo "Akun $USER terkunci selama $LOCK_TIME_DEFAULT detik."
        sleep $LOCK_TIME_DEFAULT

        # Buka akun setelah durasi berakhir
        mv "$LIMIT_DIR/locked/$USER" "$LIMIT_DIR/$USER"
        echo "$(date): $USER dibuka kembali setelah penguncian." >> /var/log/trojan-lock.log

        # Kirim notifikasi bahwa akun dibuka
        curl -s -X POST https://api.telegram.org/bot${bottoken}/sendMessage \
            -d chat_id="${idtelegram}" \
            -d text="Akun Trojan $USER telah dibuka kembali setelah penguncian."

    else
        STATUS="Dalam Batas"
    fi

    # Menampilkan status
    printf "%-15s %-15s %-15s %-15s %s\n" "$USER" "$IP_AKTIF" "$LIMIT_IP" "$TOLERANSI" "$STATUS"
    echo "  # IP Aktif (3 Oktet):"
    echo "$USER_IPS" | sed 's/^/   - /'
    echo ""
done

echo "──────────────────────────────────────────────────────────────"
echo "Monitoring selesai."
echo "──────────────────────────────────────────────────────────────"
