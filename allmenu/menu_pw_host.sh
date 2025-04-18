#!/bin/bash

# Warna untuk tampilan terminal
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'  # Reset warna

clear
# Menampilkan header menu
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${WHITE}               ⇱ GANTI PASSWORD LOGIN & HOSTNAME VPS ⇲                 ${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
# Pilihan menu
echo -e " ${CYAN}[${NC}1${CYAN}]${NC} •${YELLOW} Ubah Password Login VPS (root)${NC}"
echo -e " ${CYAN}[${NC}2${CYAN}]${NC} •${YELLOW} Ubah Hostname VPS${NC}"
echo -e " ${CYAN}[${NC}x${CYAN}]${NC} •${YELLOW} Kembali ke Menu Utama${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Membaca pilihan pengguna
read -p " Pilih opsi : " pilih

# Menentukan tindakan berdasarkan pilihan pengguna
case $pilih in
  1)
    # Mengubah password root (login VPS)
    echo -e "${YELLOW}Masukkan password baru untuk VPS (root):${NC}"
    passwd root
    # Kembali ke menu setelah selesai
    read -n1 -r -p "Tekan enter untuk kembali..." ; /usr/bin/menu_pw_host
    ;;
  2)
    # Mengubah hostname VPS
    read -p "Masukkan hostname baru: " newhost

    # Mengubah hostname ke huruf kecil (lowercase)
    newhost=$(echo "$newhost" | tr '[:upper:]' '[:lower:]')

    # Validasi hostname:
    # - Tidak boleh kosong
    # - Harus mengandung huruf, angka, titik (.), dan strip (-)
    # - Tidak boleh diawali atau diakhiri dengan simbol
    # - Tidak boleh hanya angka
    if [[ -z "$newhost" || \
          ! "$newhost" =~ ^[a-z0-9]([a-z0-9.-]*[a-z0-9])?$ || \
          "$newhost" =~ ^[0-9]+$ || \
          "$newhost" =~ [-.]$ || "$newhost" =~ ^[-.] ]]; then
      echo -e "${RED}Hostname tidak valid!${NC}"
      echo -e "${YELLOW}Gunakan huruf, angka, titik (.), strip (-), dan tidak boleh diawali/diakhiri simbol.${NC}"
      read -n1 -r -p "Tekan enter untuk kembali..." ; /usr/bin/menu_pw_host
    fi

    # Simpan hostname lama
    oldhost=$(hostname)

    # Ubah hostname menggunakan hostnamectl
    hostnamectl set-hostname "$newhost"

    # Output pesan berhasil
    echo -e "${GREEN}Hostname berhasil diganti menjadi: $newhost${NC}"

    # Simpan log perubahan hostname ke file log
    echo "$(date '+%Y-%m-%d %H:%M:%S') | $oldhost -> $newhost" >> /var/log/hostname-change.log

    # Kembali ke menu setelah selesai
    read -n1 -r -p "Tekan enter untuk kembali..." ; /usr/bin/menu_pw_host
    ;;
  x)
    # Kembali ke menu utama
    clear
    /usr/bin/menu
    ;;
  *)
    # Jika pilihan tidak valid
    echo -e "${RED}Pilihan tidak valid!${NC}" ; sleep 1 ; /usr/bin/menu_pw_host
    ;;
esac
