#!/bin/bash

BOT_DIR="/etc/bot"
mkdir -p $BOT_DIR

# Daftar fungsi bot yang tersedia
list_fungsi=("management-akun" "limitip" "bot-admin")

# Warna
RED='\033[1;31m'
GREEN='\033[1;32m'
NC='\033[0m'

# Fungsi tambah / ganti bot per fungsi
set_bot() {
    clear
    echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "        SET BOT NOTIFIKASI         "
    echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e " Fungsi bot yang tersedia:"
    
    for i in "${!list_fungsi[@]}"; do
        echo -e " [$((i+1))] ${list_fungsi[$i]}"
    done

    echo -e " [0] Kembali"
    echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    read -p " Pilih fungsi bot: " pilihan

    if [[ "$pilihan" == "0" || -z "$pilihan" ]]; then
        menu
    elif [[ "$pilihan" =~ ^[1-9][0-9]*$ ]] && (( pilihan <= ${#list_fungsi[@]} )); then
        fungsi="${list_fungsi[$((pilihan-1))]}"
        read -rp " Input Bot Token untuk fungsi '$fungsi' : " bottoken
        read -rp " Input ID Telegram Admin               : " adminid
        echo "#bot# $bottoken $adminid" > "$BOT_DIR/$fungsi.db"
        echo -e "${GREEN}Sukses set bot untuk fungsi '$fungsi'.${NC}"
    else
        echo -e "${RED}Pilihan tidak valid!${NC}"
    fi

    read -n 1 -s -r -p " Tekan Enter untuk kembali ke menu"
    menu
}

# Fungsi hapus bot
hapus_bot() {
    clear
    echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "        HAPUS BOT NOTIFIKASI       "
    echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e " Fungsi bot yang tersedia:"
    
    for i in "${!list_fungsi[@]}"; do
        echo -e " [$((i+1))] ${list_fungsi[$i]}"
    done

    echo -e " [0] Kembali"
    echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    read -p " Pilih fungsi bot yang ingin dihapus: " pilihan

    if [[ "$pilihan" == "0" || -z "$pilihan" ]]; then
        menu
    elif [[ "$pilihan" =~ ^[1-9][0-9]*$ ]] && (( pilihan <= ${#list_fungsi[@]} )); then
        fungsi="${list_fungsi[$((pilihan-1))]}"
        rm -f "$BOT_DIR/$fungsi.db"
        echo -e "${GREEN}Bot untuk fungsi '$fungsi' berhasil dihapus.${NC}"
    else
        echo -e "${RED}Pilihan tidak valid!${NC}"
    fi

    read -n 1 -s -r -p " Tekan Enter untuk kembali ke menu"
    menu
}

# Fungsi lihat semua bot yang tersimpan
lihat_bot() {
    clear
    echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "        DATA BOT TERSIMPAN         "
    echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    for fungsi in "${list_fungsi[@]}"; do
        file="$BOT_DIR/$fungsi.db"
        if [[ -f "$file" ]]; then
            data=$(grep '^#bot#' "$file" | cut -d ' ' -f2-)
            echo -e "$fungsi => $data"
        else
            echo -e "$fungsi => [belum diatur]"
        fi
    done

    echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    read -n 1 -s -r -p " Tekan Enter untuk kembali ke menu"
    menu
}

# Menu utama
menu() {
    clear
    echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "      MENU BOT NOTIFIKASI VPS      "
    echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e " [1] Tambah / Ganti Bot"
    echo -e " [2] Hapus Bot"
    echo -e " [3] Lihat Bot Aktif"
    echo -e " [4] install bot management akun"
    echo -e " [0] Kembali ke menu utama"
    echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    read -p " Pilih opsi: " opsi
    [[ -z "$opsi" ]] && return

    case "$opsi" in
        1) set_bot ;;
        2) hapus_bot ;;
        3) lihat_bot ;;
        4) install_bot_management_akun ;;
        0) clear ; /usr/bin/menu ;;
        *) echo -e "${RED}Opsi tidak valid!${NC}" ; sleep 1 ;;
    esac
    menu
}

menu
