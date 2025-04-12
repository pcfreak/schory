#!/bin/bash

# Interface yang digunakan (ganti jika bukan eth0)
IFACE="eth0"

# Folder kuota
KUOTA_DIR="/etc/klmpk/limit/ssh/kuota"
mkdir -p $KUOTA_DIR

# Loop semua user SSH (UID >= 1000 dan bukan nobody)
for user in $(awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}' /etc/passwd); do
    kuota_file="$KUOTA_DIR/$user"
    stat_file="/tmp/stat-${user}.txt"

    # Ambil vnstat statistik
    vnstat --oneline -i $IFACE > /tmp/vnstat-log

    # Ambil total RX dan TX (dalam MB)
    RX_MB=$(vnstat -i $IFACE --oneline | cut -d ";" -f 4 | sed 's/[^0-9.]//g')
    TX_MB=$(vnstat -i $IFACE --oneline | cut -d ";" -f 5 | sed 's/[^0-9.]//g')

    # Konversi MB ke GB
    RX_GB=$(echo "$RX_MB / 1024" | bc)
    TX_GB=$(echo "$TX_MB / 1024" | bc)
    TOTAL_GB=$(echo "$RX_GB + $TX_GB" | bc)

    # Load total sebelumnya
    if [ -f "$kuota_file" ]; then
        TOTAL_BEFORE=$(cat "$kuota_file")
    else
        TOTAL_BEFORE=0
    fi

    TOTAL_NOW=$(echo "$TOTAL_BEFORE + $TOTAL_GB" | bc)

    # Simpan total baru
    echo "$TOTAL_NOW" > "$kuota_file"

    # Cek apakah user punya file limit kuota dalam GB
    if [ -f "$KUOTA_DIR/${user}-limit" ]; then
        LIMIT_GB=$(cat "$KUOTA_DIR/${user}-limit")
        is_over=$(echo "$TOTAL_NOW > $LIMIT_GB" | bc)
        if [ "$is_over" -eq 1 ]; then
            usermod -L $user
            echo "User $user melebihi kuota, dinonaktifkan."
        fi
    fi
done
