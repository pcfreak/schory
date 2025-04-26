#!/bin/bash

# Fungsi untuk menginstal Apache
install_apache() {
    echo "Menginstal Apache web server..."
    sudo apt update
    sudo apt install -y apache2
    echo "Apache berhasil diinstal."

    # Konfigurasi Apache agar listen di port 700
    echo "Mengonfigurasi Apache untuk mendengarkan di port 700..."
    sudo sed -i 's/Listen 80/Listen 700/' /etc/apache2/ports.conf
    sudo sed -i 's/<VirtualHost \*:80>/<VirtualHost *:700>/' /etc/apache2/sites-available/000-default.conf

    # Restart Apache untuk menerapkan konfigurasi
    sudo systemctl restart apache2
    echo "Apache dikonfigurasi di port 700."
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
    sudo certbot --nginx -d "$DOMAIN"
    echo "SSL Let's Encrypt berhasil diinstal dan diterapkan."
}

# Fungsi untuk menginstal dan mengonfigurasi Nginx untuk multi-website dan SSL
install_all() {
    echo "Menginstal semua web server dan SSL Let's Encrypt..."

    # Simpan DOMAIN dari parameter
    DOMAIN="$1"

    # Install Apache
    install_apache
    
    # Install Nginx
    install_nginx

    # Backup konfigurasi default nginx
    sudo cp /etc/nginx/sites-available/default /etc/nginx/sites-available/default.bak

    echo "Membuat konfigurasi Nginx untuk domain/IP: $DOMAIN"

    # Konfigurasi Nginx untuk meneruskan ke Apache di port 700
    cat > /etc/nginx/sites-available/default <<EOF
server {
    listen 80;
    server_name $DOMAIN;

    location / {
        proxy_pass http://127.0.0.1:700;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

    # Reload Nginx agar konfigurasi diterapkan
    sudo systemctl reload nginx

    # Install SSL Let's Encrypt
    install_ssl

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
            read -p "Masukkan domain atau IP untuk konfigurasi multi-website dan SSL (contoh: example.com atau 192.168.1.1): " DOMAIN
            install_all "$DOMAIN"
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
