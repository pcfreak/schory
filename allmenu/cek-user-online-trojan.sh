#!/bin/bash

# Menentukan nama user
USER="kanghoryTESTTT"  # Ganti dengan nama user yang sesuai

# Menentukan path file limit IP Trojan untuk user
LIMIT_FILE="/etc/klmpk/limit/trojan/ip/$USER"  # Menggunakan path yang benar sesuai permintaan

# Mengecek apakah file limit IP Trojan ada
if [ ! -f "$LIMIT_FILE" ]; then
  echo "File limit IP Trojan untuk user $USER tidak ditemukan di $LIMIT_FILE. Pastikan file limit IP sudah ada."
  exit 1
fi

# Membaca limit IP dari file
LIMIT_IP=$(cat "$LIMIT_FILE")

# Mengambil dua oktet pertama dari IP yang terdeteksi di log
ACTIVE_IPS=$(grep "email: $USER" /var/log/xray/access.log | awk '{print $3}' | cut -d'.' -f1,2 | sort | uniq)

# Menampilkan daftar IP yang terdeteksi (2 oktet pertama)
echo "Daftar IP Aktif (2 Oktet Pertama):"
echo "$ACTIVE_IPS"

# Cek jumlah IP unik yang terdeteksi
ACTIVE_COUNT=$(echo "$ACTIVE_IPS" | wc -l)

# Menampilkan hasil jumlah IP aktif yang terdeteksi
echo "───────────────────────────────────────────────────────────"
echo "              • TROJAN ONLINE NOW (Last 5 Min) •              "
echo "───────────────────────────────────────────────────────────"
echo ""
echo "USERNAME           IP AKTIF       LIMIT IP       STATUS"
echo "───────────────────────────────────────────────────────────"
echo "$USER     $ACTIVE_COUNT            $LIMIT_IP         $(if [ "$ACTIVE_COUNT" -gt "$LIMIT_IP" ]; then echo -e "\e[31mMelebihi\e[0m"; else echo "Dalam Batas"; fi)"
echo "───────────────────────────────────────────────────────────"
echo ""
echo "Tekan enter untuk kembali ke menu..."
read -n 1 -s
clear
