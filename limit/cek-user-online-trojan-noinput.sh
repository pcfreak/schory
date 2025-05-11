#!/bin/bash
LIMIT_DIR="/etc/klmpk/limit/trojan/ip"
LOG_FILE="/var/log/xray/access.log"
NOW=$(date +%s)
ONE_MIN_AGO=$((NOW - 60))

echo -e "  • TROJAN ONLINE NOW (Last 1 Min) •"
echo -e "──────────────────────────────────────────────────────────────"
printf "%-15s %-15s %-15s %-15s %-10s\n" "USERNAME" "IP AKTIF" "LIMIT IP" "TOLERANSI IP" "STATUS"
echo -e "──────────────────────────────────────────────────────────────"

# Ambil semua user aktif dari log dalam 1 menit terakhir
USERS=$(awk -v t=$ONE_MIN_AGO '$0 ~ /email:/ {
    split($0, a, " ");
    gsub("email:", "", a[length(a)]);
    cmd="date -d \"" a[1] " " a[2] "\" +%s";
    cmd | getline logtime;
    close(cmd);
    if (logtime >= t) print a[length(a)];
}' "$LOG_FILE" | sort | uniq)

TOTAL_TOLERANSI=0

for USER in $USERS; do
    LIMIT_FILE="$LIMIT_DIR/$USER"
    [[ -f "$LIMIT_FILE" ]] && LIMIT_IP=$(cat "$LIMIT_FILE") || LIMIT_IP=1

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
    STATUS="Aman"
    [[ "$TOLERANSI" -gt "$LIMIT_IP" ]] && STATUS="Melebihi"

    printf "%-15s %-15s %-15s %-15s %-10s\n" "$USER" "$IP_AKTIF" "$LIMIT_IP" "$TOLERANSI" "$STATUS"
    echo "  # IP Aktif (3 Oktet):"
    echo "$USER_IPS" | sed 's/^/   - /'
    echo "──────────────────────────────────────────────────────────────"
    TOTAL_TOLERANSI=$((TOTAL_TOLERANSI + TOLERANSI))
done

echo "Total IP aktif terdeteksi (3 oktet): $TOTAL_TOLERANSI"
echo -e "──────────────────────────────────────────────────────────────"
