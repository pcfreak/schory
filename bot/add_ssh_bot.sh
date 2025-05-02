#!/bin/bash

# Token bot Telegram
TOKEN="YOUR_BOT_TOKEN"
CHAT_ID="YOUR_CHAT_ID"

# Fungsi untuk mengirim pesan ke Telegram
send_message() {
    local message=$1
    curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" -d chat_id="$CHAT_ID" -d text="$message"
}

# Ambil argumen yang diterima (username, password, limit IP, masa aktif)
Login="$1"
Pass="$2"
iplimit="$3"
masaaktif="$4"

# Validasi input
if [[ -z "$Login" || -z "$Pass" || -z "$iplimit" || -z "$masaaktif" ]]; then
    send_message "ERROR: Semua argumen harus diisi!"
    exit 1
fi

# Cek apakah username sudah ada
if id "$Login" &>/dev/null; then
    send_message "ERROR: Username $Login sudah ada!"
    exit 1
fi

# Buat akun SSH baru
useradd -m -s /bin/bash "$Login"
echo "$Login:$Pass" | chpasswd

# Tentukan masa aktif akun
exp_date=$(date -d "$masaaktif days" +"%Y-%m-%d")
echo "$Login" >> "/etc/ssh/expired_users"  # Menyimpan info expired

# Cek dan atur limit IP
mkdir -p /etc/klmpk/limit/ssh/ip/$Login
echo "$iplimit" > "/etc/klmpk/limit/ssh/ip/$Login/ip_limit"

# Kirim pesan berhasil ke Telegram
send_message "Akun SSH berhasil dibuat:\n\nUsername: $Login\nPassword: $Pass\nLimit IP: $iplimit\nExpired: $exp_date"

# Tampilkan informasi akun yang telah dibuat
echo "Akun SSH berhasil dibuat."
echo "Username: $Login"
echo "Password: $Pass"
echo "Limit IP: $iplimit"
echo "Expired: $exp_date"
