#!/bin/bash

# Warna
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

clear
echo -e "${GREEN}Installer Web Server${NC}"
echo "======================================="
echo "Pilih opsi:"
echo "1. Instal Apache Web Server"
echo "2. Uninstall Apache Web Server"
read -rp "Pilih [1/2]: " opsi

if [[ $opsi == "1" ]]; then
    echo "Memasang Apache2..."
    apt update -y
    apt install apache2 -y

    echo "Menghapus file default..."
    rm -f /var/www/html/index.html

    echo "Membuat file index baru..."
    echo "<html><head><title>Web Server Aktif</title></head><body><h1>Apache di Port 8888 Aktif!</h1></body></html>" > /var/www/html/index.html

    echo "Mengatur Apache listen di port 8888..."
    echo "Listen 8888" > /etc/apache2/ports.conf

    echo "Membuat VirtualHost baru..."
    cat > /etc/apache2/sites-available/webku.conf <<-END
<VirtualHost *:8888>
    ServerAdmin admin@webku.com
    DocumentRoot /var/www/html
    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
END

    echo "Menonaktifkan default site..."
    a2dissite 000-default.conf

    echo "Mengaktifkan site webku.conf..."
    a2ensite webku.conf

    echo "Restarting Apache..."
    systemctl restart apache2

    echo -e "${GREEN}======================================="
    echo "Apache Web Server sudah aktif di port 8888"
    echo "Akses via: http://$(curl -s ipv4.icanhazip.com):8888/"
    echo "=======================================${NC}"

elif [[ $opsi == "2" ]]; then
    echo "Menghapus Apache2 dan membersihkan file..."
    systemctl stop apache2
    apt purge apache2* -y
    apt autoremove -y
    rm -rf /etc/apache2
    rm -rf /var/www/html/*
    echo -e "${RED}======================================="
    echo "Apache Web Server berhasil dihapus."
    echo "=======================================${NC}"
else
    echo -e "${RED}Opsi tidak valid.${NC}"
fi
