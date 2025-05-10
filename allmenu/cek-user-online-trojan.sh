#!/bin/bash

# Lokasi log access Xray
LOG_FILE="/var/log/xray/access.log"

# Waktu 1 menit lalu
ONE_MIN_AGO=$(date -d '1 minute ago' +%s)

# Lokasi file user Trojan aktif
USER_FILE="/etc/xray/config.json"

# Ambil semua user Trojan dari config
USER_LIST=$(grep '^###' "$USER_FILE" | cut -d ' ' -f 2)

# Header
clear
echo "────────────────────────────────────────────────────────────"
echo "              • TROJAN ONLINE NOW (Last 1 Min) •"
echo "────────────────────────────────────────────────────────────"
printf "%-15s %-15s %-15s %-15s %s\n" "USERNAME" "IP AKTIF" "LIMIT IP" "TOLERANSI IP" "STATUS"
echo "────────────────────────────────────────────────────────────"

TOTAL_IP_GLOBAL=()

for USER in $USER_LIST; do
    # Ambil IP yang akses dalam 1 menit terakhir untuk user ini
    USER_IPS=$(awk -v t=$ONE_MIN_AGO -v u="$USER" '
    {
        cmd = "date -d \"" $1 " " $2 "\" +%s"
        cmd | getline logtime
        close(cmd)
        if (logtime >= t && $0 ~ "email: " u) {
            for (i=1;i<=NF;i++) {
                if ($i == "from" && $(i+1) ~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:/)
                    print $(i+1)
            }
        }
    }' "$LOG_FILE" | cut -d':' -f1 | cut -d'.' -f1,2,3 | sort -u)

    COUNT_IP=$(echo "$USER_IPS" | wc -l)
    LIMIT_IP=$(cat /etc/klmpk/limit/trojan/ip/$USER 2>/dev/null)
    [[ -z "$LIMIT_IP" ]] && LIMIT_IP=1

    # Asumsikan 2 IP = 1 device login
    TOLERANSI_IP=$((COUNT_IP / 2))
    [[ $((COUNT_IP % 2)) -ne 0 ]] && TOLERANSI_IP=$((TOLERANSI_IP + 1))

    STATUS="Aman"
    [[ "$TOLERANSI_IP" -gt "$LIMIT_IP" ]] && STATUS="Melebihi"

    printf "%-15s %-15s %-15s %-15s %s\n" "$USER" "$COUNT_IP" "$LIMIT_IP" "$TOLERANSI_IP" "$STATUS"

    if [[ $COUNT_IP -gt 0 ]]; then
        echo "  # IP Aktif (3 Oktet):"
        echo "$USER_IPS" | sed 's/^/   - /'
        TOTAL_IP_GLOBAL+=($USER_IPS)
        echo ""
    fi
done

# Hitung total IP unik semua user
TOTAL=$(printf "%s\n" "${TOTAL_IP_GLOBAL[@]}" | sort -u | wc -l)

echo "────────────────────────────────────────────────────────────"
echo "Total IP aktif terdeteksi (3 oktet): $TOTAL"
echo "────────────────────────────────────────────────────────────"
read -n 1 -s -r -p "   Tekan sembarang tombol untuk kembali ke menu"
echo
