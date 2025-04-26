#!/bin/bash
# Installer Web Server (Apache) Port 8080/8888
# By ChatGPT

clear
echo "======================================="
echo "        Installer Web Server           "
echo "======================================="
echo ""
echo "Pilih port untuk Web Server:"
echo "1. 8080"
echo "2. 8888"
read -p "Pilih [1/2]: " port_choice

if [[ "$port_choice" == "1" ]]; then
    port="8080"
elif [[ "$port_choice" == "2" ]]; then
    port="8888"
else
    echo "Pilihan tidak valid!"
    exit 1
fi

# Update sistem dan install apache2
echo ""
echo "Mengupdate sistem dan menginstal Apache2..."
apt update -y && apt install apache2 -y

# Konfigurasi port Apache
echo "Mengatur Apache untuk listen di port $port..."
sed -i "s/Listen 80/Listen $port/g" /etc/apache2/ports.conf
sed -i "s/<VirtualHost \*:80>/<VirtualHost *:$port>/g" /etc/apache2/sites-available/000-default.conf

# Restart apache2
echo "Restarting Apache2..."
systemctl restart apache2

# Buka port di firewall jika ufw aktif
if systemctl is-active --quiet ufw; then
    echo "Membuka port $port di firewall (ufw)..."
    ufw allow $port/tcp
fi

# Cek status
echo ""
echo "======================================="
echo "Apache Web Server sudah aktif di port $port"
echo "Akses via: http://$(curl -s ifconfig.me):$port/"
echo "======================================="
