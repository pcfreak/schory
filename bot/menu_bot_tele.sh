#!/bin/bash

# Directory untuk menyimpan bot token dan ID
BOT_DIR="/etc/bot"
mkdir -p $BOT_DIR

# Fungsi untuk menambahkan bot baru
add_bot() {
    clear
    echo -e "\033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    echo -e " \e[1;97;101m          ADD BOT NOTIFIKASI          \e[0m"
    echo -e "\033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    echo -e "${grenbo}Tutorial Creat Bot and ID Telegram${NC}"
    echo -e "${grenbo}[*] Create Bot and Token Bot : @BotFather${NC}"
    echo -e "${grenbo}[*] Info Id Telegram : @MissRose_bot , perintah /info${NC}"
    echo -e "\033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"

    read -rp "[*] Input your Bot Token : " -e bottoken 
    read -rp "[*] Input Your Id Telegram : " -e admin
    echo -e "\033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    clear

    # Simpan bot token dan ID ke dalam file terpisah sesuai jenis bot
    echo "#bot# ${bottoken} ${admin}" >> "$BOT_DIR/${bottoken}.db"

    echo -e "\033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    echo -e " \e[1;97;101m      SUCCESS ADD BOT NOTIFIKASI      \e[0m"
    echo -e "\033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    echo " Bot Token    : $bottoken"
    echo " ID Telegram  : $admin"
    echo -e "\033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    read -n 1 -s -r -p "Press [ Enter ] to back menu"
    menu
}

# Fungsi untuk mengganti bot yang sudah ada
change_bot() {
    clear
    echo -e "\033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    echo -e " \e[1;97;101m          CHANGE BOT NOTIFIKASI         \e[0m"
    echo -e "\033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"

    read -rp "[*] Input Bot Token yang akan diganti : " -e bottoken
    read -rp "[*] Input Bot Token Baru : " -e new_bottoken 
    read -rp "[*] Input ID Telegram Baru : " -e new_admin

    # Update file database bot yang lama
    if [[ -f "$BOT_DIR/${bottoken}.db" ]]; then
        sed -i "s/^#bot# ${bottoken}/#bot# ${new_bottoken}/g" "$BOT_DIR/${bottoken}.db"
        sed -i "s/${bottoken}/${new_bottoken}/g" "$BOT_DIR/${bottoken}.db"
    fi

    # Simpan bot baru
    echo "#bot# ${new_bottoken} ${new_admin}" >> "$BOT_DIR/${new_bottoken}.db"

    echo -e "\033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    echo -e " \e[1;97;101m      SUCCESS CHANGE BOT NOTIFIKASI     \e[0m"
    echo -e "\033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    echo " Bot Token Baru  : $new_bottoken"
    echo " ID Telegram Baru: $new_admin"
    echo -e "\033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    read -n 1 -s -r -p "Press [ Enter ] to back menu"
    menu
}

# Fungsi untuk menghapus bot
delete_bot() {
    clear
    echo -e "\033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    echo -e " \e[1;97;101m          DELETE BOT NOTIFIKASI          \e[0m"
    echo -e "\033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    
    read -rp "[*] Input Bot Token yang akan dihapus : " -e bottoken
    
    if [[ -f "$BOT_DIR/${bottoken}.db" ]]; then
        rm -f "$BOT_DIR/${bottoken}.db"
        echo -e "\033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
        echo -e " \e[1;97;101m      SUCCESS DELETE BOT NOTIFIKASI     \e[0m"
        echo -e "\033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
        echo " Bot Token    : $bottoken"
        echo -e "\033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    else
        echo -e "Bot token tidak ditemukan!"
    fi
    read -n 1 -s -r -p "Press [ Enter ] to back menu"
    menu
}

# Menu utama
menu() {
    clear
    echo -e "\033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    echo -e " \e[1;97;101m          MENU BOT NOTIFIKASI           \e[0m"
    echo -e "\033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    echo -e "${grenbo}[1]${NC}${YELL} Add Bot Notifikasi${NC}"
    echo -e "${grenbo}[2]${NC}${YELL} Change Bot Notifikasi${NC}"
    echo -e "${grenbo}[3]${NC}${YELL} Delete Bot Notifikasi${NC}"
    echo -e "${grenbo}[0]${NC}${YELL} Back To Main Menu${NC}"
    echo -e "\033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"

    read -p "  Select From Options [ 1 - 3 or 0 ] : " option
    case $option in
        1) add_bot ;;
        2) change_bot ;;
        3) delete_bot ;;
        0) exit ;;
        *) menu ;;
    esac
}

menu
