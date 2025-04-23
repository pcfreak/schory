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

# cek all servis dan notif tele jika ada yg blm jalan
show_status_limitssh() {
    clear
    echo -e "=== MENU LIMIT IP SSH ==="

    # Warna ANSI bersinar
    green="\e[1;92m"
    red="\e[1;91m"
    yellow="\e[1;93m"
    reset="\e[0m"

    # Emoji
    checkmark="✅"
    crossmark="❌"

    # Function kirim notifikasi Telegram
    send_telegram_notification() {
        local message="$1"
        local BOT_FILE="/etc/bot/limitip.db"

        if [[ -f "$BOT_FILE" ]]; then
            local BOT_LINE=$(grep -E '^#bot#' "$BOT_FILE")
            local BOT_TOKEN=$(echo "$BOT_LINE" | awk '{print $2}')
            local BOT_CHATID=$(echo "$BOT_LINE" | awk '{print $3}')

            [[ -z $BOT_TOKEN || -z $BOT_CHATID ]] && return

            curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
                -d "chat_id=${BOT_CHATID}" \
                -d "text=${message}" \
                -d "parse_mode=HTML" >/dev/null 2>&1
        fi
    }

    local SERVICES=("limitssh.service" "cron" "atd")
    local alert_message=""

    for service in "${SERVICES[@]}"; do
        echo -e "\n=== STATUS SERVICE: $service ==="

        local is_active=$(systemctl is-active "$service")
        local is_enabled=$(systemctl is-enabled "$service" 2>/dev/null)

        if [[ "$is_active" == "active" ]]; then
            echo -e "Status Aktif  : ${green}${checkmark} Aktif${reset}"
        else
            echo -e "Status Aktif  : ${red}${crossmark} Tidak Aktif${reset}"
            alert_message+="$service <code>tidak aktif</code>\n"
        fi

        if [[ "$is_enabled" == "enabled" ]]; then
            echo -e "Auto Start    : ${green}${checkmark} Enabled${reset}"
        else
            echo -e "Auto Start    : ${red}${crossmark} Disabled${reset}"
        fi

        systemctl status "$service" --no-pager | grep -E "Loaded:|Main PID:|Memory:" | sed 's/^/     /'
        journalctl -u "$service" -n 5 --no-pager 2>/dev/null | sed 's/^/Log Terakhir (5 baris):\n     /'
    done

    if [[ -n "$alert_message" ]]; then
        send_telegram_notification "🔺<b>Service Mati di VPS</b>🔺\n$alert_message"
    fi
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
enable_all_limit_services() {
    local SERVICES=("limitssh.service" "cron" "atd")
    local status_message="✅<b>Aktifkan Service</b>✅\n<code>"

    echo -e "\n\e[1;93m== MENGAKTIFKAN SEMUA SERVICE LIMIT IP SSH ==\e[0m"

    for service in "${SERVICES[@]}"; do
        echo -e "\n\e[1;96m=> Mengaktifkan $service...\e[0m"
        systemctl enable "$service" >/dev/null 2>&1
        systemctl start "$service"

        local status=$(systemctl is-active "$service")
        if [[ "$status" == "active" ]]; then
            echo -e "\e[1;92m✅ $service berhasil aktif\e[0m"
            status_message+=$(printf '%-20s : Aktif ✅\n' "$service")
        else
            echo -e "\e[1;91m❌ Gagal mengaktifkan $service\e[0m"
            status_message+=$(printf '%-20s : Gagal ❌\n' "$service")
        fi
    done

    status_message+="</code>"
    echo -e "\n\e[1;92mSelesai mengaktifkan semua service.\e[0m"
    send_telegram_notification "$status_message"
}

# Nonaktifkan service limitssh
disable_all_services() {
    local SERVICES=("limitssh.service" "cron" "atd")
    local status_message="❌<b>Nonaktifkan Service</b>❌\n"

    echo -e "\n\e[1;93m== MENONAKTIFKAN SEMUA SERVICE ==\e[0m"

    for service in "${SERVICES[@]}"; do
        echo -e "\n\e[1;96m=> ❌ Menonaktifkan ❌ $service...\e[0m"
        systemctl stop "$service" >/dev/null 2>&1
        systemctl disable "$service" >/dev/null 2>&1

        local status=$(systemctl is-active "$service")
        if [[ "$status" == "inactive" ]]; then
            echo -e "\e[1;92m✅ $service berhasil dinonaktifkan\e[0m"
            status_message+="\n<b>${service}</b> : <code>Nonaktif</code> ✅"
        else
            echo -e "\e[1;91m❌ Gagal menonaktifkan $service\e[0m"
            status_message+="\n<b>${service}</b> : <code>Gagal Dinonaktifkan</code> ❌"
        fi
    done

    echo -e "\n\e[1;92mSelesai menonaktifkan semua service.\e[0m"
    send_telegram_notification "$status_message"
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
refresh_services_and_notify() {
    local services=("limitssh.service" "cron" "atd")
    local status_message="✅<b>Update Status Service</b>✅\n"
    local GREEN="\e[92;1m"
    local RED="\e[91;1m"
    local NC="\e[0m"

    echo -e "\n\033[1;36m== MENYEGARKAN STATUS SEMUA SERVICE ==\033[0m"
    
    for service in "${services[@]}"; do
        echo -ne "• Memproses ${service} ... "

        systemctl daemon-reexec >/dev/null 2>&1
        systemctl daemon-reload >/dev/null 2>&1
        systemctl enable "$service" >/dev/null 2>&1
        systemctl restart "$service" >/dev/null 2>&1

        local active=$(systemctl is-active "$service")
        local enabled=$(systemctl is-enabled "$service" 2>/dev/null)

        if [[ "$active" == "active" ]]; then
            echo -e "${GREEN}[AKTIF]${NC}"
            status_message+="\n<b>${service}</b> : <code>Aktif</code> ✅"
        else
            echo -e "${RED}[TIDAK AKTIF]${NC}"
            status_message+="\n<b>${service}</b> : <code>Tidak Aktif</code> ❌"
        fi
    done

    echo -e "\n\033[1;32mSelesai memperbarui semua status service.\033[0m"
    send_telegram_notification "$status_message"
}


# Menu utama
while true; do
    clear
    echo -e "\e[1;34m=== MENU LIMIT IP SSH ===\e[0m"
    show_status_limitssh
    echo -e "1. Lihat Semua Limit IP"
    echo -e "2. Set / Ubah Limit IP"
    echo -e "3. Hapus Limit IP"
    echo -e "4. Aktifkan all services Limit IP"
    echo -e "5. Nonaktifkan all Service Limit IP"
    echo -e "6. Lihat Durasi Akun Terkunci"
    echo -e "7. Set Durasi Akun Terkunci"
    echo -e "8. Cek Status Service"
    echo -e "9. refresh all services Limit IP"
    echo -e "0. Keluar"
    echo
    read -rp "Pilih opsi [0-9]: " opt
    case $opt in
        1) list_limit ;;
        2) set_limit ;;
        3) delete_limit ;;
        4) enable_all_limit_services ;;
        5) disable_all_services ;;
        6) show_lock_duration ;;
        7) set_lock_duration ;;
        8) show_status_limitssh ;;
        9) refresh_services_and_notify ;;
        0) clear && menu ;;
        *) echo "Opsi tidak valid." && sleep 1 ;;
    esac
    read -n 1 -s -r -p "Tekan enter untuk kembali ke menu..."
done
