#!/bin/bash

LIMIT_DIR="/etc/klmpk/limit/trojan/ip"
LOG_FILE="/var/log/xray/access.log"
NOW=$(date +%s)
ONE_MIN_AGO=$((NOW - 60))

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
    echo -e "──────────────────────────────────────────────────────────────"
    echo -e "Tidak ada user Trojan yang aktif dalam 1 menit terakhir."
    echo -e "──────────────────────────────────────────────────────────────"
    exit 0
fi

echo -e "──────────────────────────────────────────────────────────────"
echo -e "              • TROJAN ONLINE NOW (Last 1 Min) •"
echo -e "──────────────────────────────────────────────────────────────"
echo -e "USERNAME        IP AKTIF        LIMIT IP        TOLERANSI IP     STATUS"
echo -e "──────────────────────────────────────────────────────────────"

TOTAL_TOLERANSI=0

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
    TOTAL_TOLERANSI=$((TOTAL_TOLERANSI + TOLERANSI))

    STATUS=$(if [ "$TOLERANSI" -gt "$LIMIT_IP" ]; then echo -e "\e[31mMelebihi\e[0m"; else echo "Dalam Batas"; fi)

    printf "%-15s %-15s %-15s %-15s %s\n" "$USER" "$IP_AKTIF" "$LIMIT_IP" "$TOLERANSI" "$STATUS"

    echo "  # IP Aktif (3 Oktet):"
    echo "$USER_IPS" | sed 's/^/   - /'
    echo ""
done

echo -e "──────────────────────────────────────────────────────────────"
echo -e "Total IP aktif terdeteksi (3 oktet): $TOTAL_TOLERANSI"
echo -e "──────────────────────────────────────────────────────────────"
read -n 1 -s -r -p "   Tekan sembarang tombol untuk kembali ke menu"
menu-trojan
