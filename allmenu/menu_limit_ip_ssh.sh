#!/bin/bash
export TERM=xterm
LIMIT_DIR="/etc/klmpk/limit/ssh/ip"
SERVICE="limitssh.service"
LOCK_DURATION_FILE="/etc/klmpk/limit/ssh/lock_duration"
DEFAULT_LOCK_DURATION=15

# Pastikan direktori limit ada
[[ ! -d $LIMIT_DIR ]] && mkdir -p $LIMIT_DIR

# Jika file lock_duration belum ada, buat dengan default 15 menit
if [[ ! -f $LOCK_DURATION_FILE ]]; then
    echo "$DEFAULT_LOCK_DURATION" > "$LOCK_DURATION_FILE"
fi

# Fungsi menampilkan status service
function show_status() {
    SERVICE="$1"
    if [[ -z "$SERVICE" ]]; then
        echo -e "\n\e[1;31m[!] Masukkan nama service sebagai argumen.\e[0m"
        return 1
    fi

    echo -e "\n\e[1;36m=== STATUS SERVICE: $SERVICE ===\e[0m"

    # Status aktif dan auto start
    systemctl is-enabled "$SERVICE" &>/dev/null && enabled="Enabled" || enabled="Disabled"
    status=$(systemctl is-active "$SERVICE")
    echo -e "Status Aktif  : \e[1;33m$status\e[0m"
    echo -e "Auto Start    : \e[1;33m$enabled\e[0m"

    # Ringkasan systemctl status
    echo -e "\n\e[1;36mRingkasan Service:\e[0m"
    systemctl status "$SERVICE" --no-pager | grep -E "Loaded:|Active:|Main PID:|Tasks:|Memory:|CPU:"

    # Log terakhir
    echo -e "\n\e[1;36mLog Terakhir (5 baris):\e[0m"
    journalctl -u "$SERVICE" -n 5 --no-pager --quiet

    # Tampilkan juga status cron dan atd
    for svc in cron atd; do
        echo -e "\n\e[1;36m=== STATUS SERVICE: $svc ===\e[0m"
        systemctl is-enabled "$svc" &>/dev/null && enabled="Enabled" || enabled="Disabled"
        status=$(systemctl is-active "$svc")
        echo -e "Status Aktif  : \e[1;33m$status\e[0m"
        echo -e "Auto Start    : \e[1;33m$enabled\e[0m"
        echo -e "\n\e[1;36mRingkasan Service:\e[0m"
        systemctl status "$svc" --no-pager | grep -E "Loaded:|Active:|Main PID:|Tasks:|Memory:|CPU:"
        echo -e "\n\e[1;36mLog Terakhir (5 baris):\e[0m"
        journalctl -u "$svc" -n 5 --no-pager --quiet
    done
}

# Lihat semua user + limit
function list_limit() {
    echo -e "\n\e[1;33m=== Daftar Limit IP SSH ===\e[0m"
    if [ "$(ls -A $LIMIT_DIR)" ]; then
        for file in $LIMIT_DIR/*; do
            user=$(basename "$file")
            limit=$(cat "$file")
            printf "User: \e[1;32m%-15s\e[0m | Limit IP: \e[1;31m%s\e[0m\n" "$user" "$limit"
        done
    else
        echo "Belum ada limit IP yang diset."
    fi
}

# Set atau ubah limit
function set_limit() {
    read -p "Masukkan username SSH: " user
    id -u "$user" &>/dev/null || { echo "User tidak ditemukan!"; return; }

    read -p "Masukkan limit IP (angka): " limit
    if [[ "$limit" =~ ^[0-9]+$ && "$limit" -gt 0 ]]; then
        echo "$limit" > "$LIMIT_DIR/$user"
        echo "Limit IP untuk \e[1;32m$user\e[0m diatur ke \e[1;31m$limit\e[0m."
    else
        echo "Input tidak valid. Harus angka lebih dari 0."
    fi
}

# Hapus limit
function delete_limit() {
    read -p "Masukkan username yang ingin dihapus limitnya: " user
    if [[ -f "$LIMIT_DIR/$user" ]]; then
        rm -f "$LIMIT_DIR/$user"
        echo "Limit IP untuk \e[1;32m$user\e[0m telah dihapus."
    else
        echo "User tidak memiliki limit IP yang disimpan."
    fi
}

# Aktifkan service limitssh
function start_service() {
    systemctl enable $SERVICE
    systemctl start $SERVICE
    echo -e "\e[1;32mService $SERVICE diaktifkan.\e[0m"
}

# Nonaktifkan service limitssh
function stop_service() {
    systemctl stop $SERVICE
    systemctl disable $SERVICE
    echo -e "\e[1;31mService $SERVICE dinonaktifkan.\e[0m"
}

# Menampilkan durasi akun terkunci
function show_lock_duration() {
    lock_duration=$(cat $LOCK_DURATION_FILE)
    echo -e "Durasi akun terkunci saat melanggar limit IP adalah: \e[1;31m$lock_duration menit\e[0m"
}

# Mengatur durasi akun terkunci
function set_lock_duration() {
    read -p "Masukkan durasi akun terkunci dalam menit (default 15 menit): " duration
    duration=${duration:-$DEFAULT_LOCK_DURATION}  # Menggunakan default jika kosong

    if [[ "$duration" =~ ^[0-9]+$ && "$duration" -gt 0 ]]; then
        echo "$duration" > "$LOCK_DURATION_FILE"
        echo -e "Durasi akun terkunci telah diatur ke \e[1;31m$duration menit\e[0m"
    else
        echo "Input tidak valid. Harus angka lebih dari 0."
    fi
}

# Restart service limitssh
function restart_service() {
    systemctl restart $SERVICE
    echo -e "\e[1;33mService $SERVICE berhasil direstart.\e[0m"
}

# Menu utama
while true; do
    clear
    echo -e "\e[1;34m=== MENU LIMIT IP SSH ===\e[0m"
    show_status
    echo -e "1. Lihat Semua Limit IP"
    echo -e "2. Set / Ubah Limit IP"
    echo -e "3. Hapus Limit IP"
    echo -e "4. Aktifkan Service Limit IP"
    echo -e "5. Nonaktifkan Service Limit IP"
    echo -e "6. Lihat Durasi Akun Terkunci"
    echo -e "7. Set Durasi Akun Terkunci"
    echo -e "8. Cek Status Service"
    echo -e "9. Restart Service Limit IP"
    echo -e "0. Keluar"
    echo
    read -rp "Pilih opsi [0-9]: " opt
    case $opt in
        1) list_limit ;;
        2) set_limit ;;
        3) delete_limit ;;
        4) start_service ;;
        5) stop_service ;;
        6) show_lock_duration ;;
        7) set_lock_duration ;;
        8) show_status ;;
        9) restart_service ;;
        0) clear && menu ;;
        *) echo "Opsi tidak valid." && sleep 1 ;;
    esac
    read -n 1 -s -r -p "Tekan enter untuk kembali ke menu..."
done
