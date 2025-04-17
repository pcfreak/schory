#!/bin/bash

clear
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m${NC}"
echo -e "\E[39;1;92m               ⇱ GANTI PASSWORD & HOSTNAME ⇲                 \E[0m"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m${NC}"
echo -e " ${BICyan}[${BIWhite}1${BICyan}]${RED} •${NC} ${YELLOW}Ganti Password VPS $NC"
echo -e " ${BICyan}[${BIWhite}2${BICyan}]${RED} •${NC} ${YELLOW}Ganti Hostname VPS $NC"
echo -e " ${BICyan}[${BIWhite}x${BICyan}]${RED} •${NC} ${YELLOW}Kembali ke Menu Utama $NC"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m${NC}"

read -p " Pilih opsi : " pilih

case $pilih in
  1)
    # Ganti Password
    read -p "Masukkan username: " user
    if id "$user" &>/dev/null; then
      echo "Masukkan password baru:"
      passwd "$user"
    else
      echo -e "${RED}User tidak ditemukan.${NC}"
    fi
    read -n1 -r -p "Tekan enter untuk kembali..." ; ./menu_pw_host.sh
    ;;
  2)
    # Ganti Hostname
    read -p "Masukkan hostname baru: " newhost

    # Validasi input: tidak boleh kosong dan hanya karakter valid (huruf, angka, titik, strip)
    if [[ -z "$newhost" || ! "$newhost" =~ ^[a-zA-Z0-9.-]+$ ]]; then
      echo -e "${RED}Hostname tidak valid! Gunakan huruf, angka, titik (.) atau strip (-).${NC}"
      read -n1 -r -p "Tekan enter untuk kembali..." ; ./menu_pw_host.sh
    fi

    # Ubah hostname ke lowercase
    newhost=$(echo "$newhost" | tr '[:upper:]' '[:lower:]')

    # Simpan hostname lama
    oldhost=$(hostname)

    # Ubah hostname
    hostnamectl set-hostname "$newhost"

    # Output success
    echo -e "${GREEN}Hostname berhasil diganti menjadi: $newhost${NC}"

    # Simpan log perubahan hostname
    echo "$(date '+%Y-%m-%d %H:%M:%S') | $oldhost -> $newhost" >> /var/log/hostname-change.log

    read -n1 -r -p "Tekan enter untuk kembali..." ; ./menu_pw_host.sh
    ;;
  x)
    # Kembali ke menu utama
    clear
    ./menu.sh
    ;;
  *)
    # Opsi tidak valid
    echo -e "${RED}Pilihan tidak valid!${NC}" ; sleep 1 ; ./menu_pw_host.sh
    ;;
esac
