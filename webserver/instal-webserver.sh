#!/bin/bash
# Installer Web Server (Apache) Port 8080/8888
# By ChatGPT

clear
echo "======================================="
echo "        Installer Web Server           "
echo "======================================="
echo ""
echo "Pilih opsi:"
echo "1. Instal Apache Web Server"
echo "2. Uninstall Apache Web Server"
read -p "Pilih [1/2]: " option_choice

if [[ "$option_choice" == "1" ]]; then
    # Pilih port untuk Web Server
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

    # Hapus file lama Apache jika ada
    echo "Menghapus file lama Apache (jika ada)..."
    rm -rf /etc/apache2/*
    rm -rf /var/www/html/*

    # Update sistem dan install apache2
    echo ""
    echo "Mengupdate sistem dan menginstal Apache2..."
    apt update -y && apt install apache2 -y

    # Pastikan file konfigurasi default ada
    echo "Memastikan konfigurasi Apache ada..."
    if [ ! -f /etc/apache2/apache2.conf ]; then
        echo "Membuat file apache2.conf..."
        cat <<EOF > /etc/apache2/apache2.conf
# apache2.conf file

ServerRoot "/etc/apache2"
Listen $port

# LoadModule directives for the Apache modules
IncludeOptional sites-enabled/*.conf
EOF
    fi

    # Pastikan VirtualHost ada
    echo "Memastikan VirtualHost ada untuk port $port..."
    if [ ! -f /etc/apache2/sites-available/000-default.conf ]; then
        echo "Membuat file 000-default.conf..."
        cat <<EOF > /etc/apache2/sites-available/000-default.conf
<VirtualHost *:$port>
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/html
    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF
    fi

    # Mengatur Apache untuk listen di port yang dipilih
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

elif [[ "$option_choice" == "2" ]]; then
    # Uninstall Apache Web Server
    echo "Menghapus Apache Web Server..."
    systemctl stop apache2
    apt-get purge apache2 apache2-utils apache2-bin apache2.2-common -y
    apt-get autoremove -y
    rm -rf /etc/apache2
    rm -rf /var/www/html

    echo "Apache Web Server berhasil dihapus."
else
    echo "Pilihan tidak valid!"
    exit 1
fi
