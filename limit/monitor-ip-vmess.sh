#!/bin/bash

# Lokasi log Xray
LOG="/var/log/xray/access.log"

# Direktori tempat limit IP per user VMess disimpan
LIMIT_DIR="/etc/klmpk/limit/vmess/ip"

# Membaca semua user dari direktori limit
for user in $(ls $LIMIT_DIR); do
    # Membaca limit IP dari file
    limit=$(cat $LIMIT_DIR/$user)

    # Menghitung jumlah IP unik yang digunakan oleh user dalam log
    count=$(grep -w $user $LOG | tail -n 500 | awk '{print $3}' | sed 's/tcp://g' | cut -d: -f1 | sort -u | wc -l)

    # Jika jumlah IP lebih banyak dari limit, lakukan tindakan
    if [[ $count -gt $limit ]]; then
        echo "User $user melewati batas IP ($count/$limit), akun dinonaktifkan."

        # Ambil tanggal expired dari file konfigurasi Xray
        exp=$(grep -wE "^### $user" /etc/xray/config.json | cut -d ' ' -f 3)

        # Hapus user dari konfigurasi Xray untuk menonaktifkan akses
        sed -i "/^### $user $exp/,/^},{/d" /etc/xray/config.json
    fi
done

# Restart Xray untuk menerapkan perubahan
systemctl restart xray
