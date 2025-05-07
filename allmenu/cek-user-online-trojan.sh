#!/bin/bash

# Path ke file log Xray
LOG_FILE="/var/log/xray/access.log"

# Path ke config Xray
CONFIG_FILE="/etc/xray/config.json"

# Fungsi untuk mendeteksi IP aktif berdasarkan log
detect_active_ips() {
    echo "Menampilkan hasil deteksi user Trojan yang online:"
    echo "Username             IP Aktif   Limit IP"
    echo "-----------------------------------------------"
    
    # Ambil semua log dalam 1 menit terakhir (sesuaikan waktu sesuai kebutuhan)
    LAST_MINUTE=$(date --date='1 minute ago' +%s)
    CURRENT_TIME=$(date +%s)
    
    # Filter log berdasarkan waktu dan user
    cat "$LOG_FILE" | while read -r line; do
        LOG_TIME=$(echo "$line" | awk '{print $1" "$2}')
        LOG_TIMESTAMP=$(date -d "$LOG_TIME" +%s)

        # Cek apakah log ada dalam 1 menit terakhir
        if [ "$LOG_TIMESTAMP" -ge "$LAST_MINUTE" ] && [ "$LOG_TIMESTAMP" -le "$CURRENT_TIME" ]; then
            USERNAME=$(echo "$line" | grep -oP '(?<=email: )\S+')
            IP=$(echo "$line" | grep -oP '(?<=from )\d+\.\d+\.\d+\.\d+')
            SUBNET=$(echo "$IP" | cut -d'.' -f1,2)
            
            # Deteksi dan tampilkan IP
            if [ ! -z "$USERNAME" ] && [ ! -z "$IP" ]; then
                ACTIVE_IPS["$USERNAME"]="$IP"
                echo -e "$USERNAME \t $IP \t 1"  # Tampilkan IP aktif dan limit (sesuaikan dengan aturan limit IP)
            fi
        fi
    done
}

# Fungsi untuk membaca file JSON konfigurasi Xray dan memprosesnya
process_config() {
    echo "Memproses konfigurasi Xray..."
    if ! jq . "$CONFIG_FILE" > /dev/null 2>&1; then
        echo "Config JSON tidak valid, silakan periksa file $CONFIG_FILE"
        exit 1
    fi
    # Lanjutkan dengan proses validasi config lainnya jika diperlukan
}

# Menjalankan deteksi IP aktif dan validasi konfigurasi
process_config
detect_active_ips
