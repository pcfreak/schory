#!/bin/bash

# Fungsi untuk menginstal Apache
install_apache() {
    echo "Menginstal Apache web server..."
    sudo apt update
    sudo apt install -y apache2
    echo "Apache berhasil diinstal."

    # Mengonfigurasi Apache untuk mendengarkan di port 8888
    echo "Mengonfigurasi Apache untuk mendengarkan di port 8888..."
    sudo sed -i 's/Listen 80/Listen 8888/' /etc/apache2/ports.conf
    sudo sed -i 's/VirtualHost *:80/VirtualHost *:8888/' /etc/apache2/sites-available/000-default.conf
    
    # Restart Apache untuk menerapkan konfigurasi
    sudo systemctl restart apache2
    echo "Apache dikonfigurasi di port 8888."
}

# Fungsi untuk menginstal Nginx
install_nginx() {
    echo "Menginstal Nginx web server..."
    sudo apt update
    sudo apt install -y nginx
    echo "Nginx berhasil diinstal."
}

# Fungsi untuk menginstal SSL Let's Encrypt
install_ssl() {
    echo "Menginstal SSL Let's Encrypt..."
    sudo apt install -y certbot python3-certbot-nginx
    sudo certbot --nginx -d $DOMAIN
    echo "SSL Let's Encrypt berhasil diinstal dan diterapkan."
}

# Fungsi untuk menginstal dan mengonfigurasi Nginx untuk multi-website dan SSL
install_all() {
    echo "Menginstal semua web server dan SSL Let's Encrypt..."

    # Install Apache
    install_apache
    
    # Install Nginx
    install_nginx
    
    # Ganti dengan domain/IP atau IP lokal server
    DOMAIN="${1:-$(hostname -I | awk '{print $1}')}"  # IP lokal jika tidak diberikan domain

    # Install SSL Let's Encrypt untuk Nginx
    install_ssl

    # Konfigurasi Nginx untuk multi-website
    echo "Membuat konfigurasi Nginx untuk domain/IP: $DOMAIN"

    # Backup file default nginx
    sudo cp /etc/nginx/sites-available/default /etc/nginx/sites-available/default.bak

    # Ganti placeholder dengan domain/IP
    sudo sed -i "s/yourdomain.com/$DOMAIN/g" /etc/nginx/sites-available/default

    # Konfigurasi Nginx untuk meneruskan port 80 dan 443 ke Apache (port 8888)
    sudo sed -i '/server_name/c\server_name $DOMAIN;' /etc/nginx/sites-available/default
    sudo sed -i 's|proxy_pass http://127.0.0.1:8888;|proxy_pass http://127.0.0.1:8888;|' /etc/nginx/sites-available/default
    
    # Reload Nginx agar konfigurasi diterapkan
    sudo systemctl reload nginx

    echo "Semua web server (Apache dan Nginx) berhasil diinstal dan dikonfigurasi."
}

# Fungsi untuk menghapus semua web server
remove_all() {
    echo "Menghapus semua web server (Apache dan Nginx)..."
    sudo apt remove --purge -y apache2 nginx
    sudo apt autoremove -y
    echo "Semua web server berhasil dihapus."
}

# Menu pilihan
while true; do
    clear
    echo "Pilih opsi:"
    echo "1) Instal Semua Web Server (Apache, Nginx, SSL)"
    echo "2) Hapus Semua Web Server (Apache dan Nginx)"
    read -p "Masukkan pilihan (1-2): " pilihan

    case $pilihan in
        1)
            echo "Masukkan domain atau IP untuk konfigurasi multi-website dan SSL (contoh: example.com atau 192.168.1.1):"
            read DOMAIN
            install_all $DOMAIN
            ;;
        2)
            remove_all
            ;;
        *)
            echo "Pilihan tidak valid!"
            ;;
    esac
    read -p "Tekan Enter untuk melanjutkan..."
done
