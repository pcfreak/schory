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

    # Backup konfigurasi default nginx
    sudo cp /etc/nginx/sites-available/default /etc/nginx/sites-available/default.bak

    # Buat konfigurasi reverse proxy ke Apache
    DOMAIN="$1"
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

    # Reload Nginx
    sudo systemctl reload nginx
    echo "Nginx berhasil dikonfigurasi sebagai reverse proxy ke Apache."
}

# Fungsi untuk menginstal SSL Let's Encrypt
install_ssl() {
    echo "Menginstal SSL Let's Encrypt..."
    sudo apt install -y certbot python3-certbot-nginx
    sudo certbot --nginx -d "$DOMAIN"
    echo "SSL Let's Encrypt berhasil diterapkan."
}

# Fungsi gabungan instalasi
install_all() {
    echo "Instalasi Web Server dan Reverse Proxy..."

    DOMAIN="$1"

    install_apache
    install_nginx "$DOMAIN"

    echo ""
    echo "Website seharusnya sudah bisa diakses di http://$DOMAIN"
    echo "Sekarang, pastikan domain mengarah ke IP server INI."
    echo "Kalau sudah online, lanjutkan manual untuk SSL dengan perintah:"
    echo "    sudo certbot --nginx -d $DOMAIN"
}

# Fungsi hapus semua
remove_all() {
    echo "Menghapus Apache dan Nginx..."
    sudo apt remove --purge -y apache2 nginx
    sudo apt autoremove -y
    echo "Selesai menghapus."
}

# Menu utama
while true; do
    clear
    echo "Pilih opsi:"
    echo "1) Install Web Server (Apache, Nginx Reverse Proxy)"
    echo "2) Remove Web Server"
    read -p "Masukkan pilihan (1-2): " pilihan

    case $pilihan in
        1)
            read -p "Masukkan domain atau IP server: " DOMAIN
            install_all "$DOMAIN"
            ;;
        2)
            remove_all
            ;;
        *)
            echo "Pilihan tidak valid!"
            ;;
    esac
    read -p "Tekan Enter untuk kembali ke menu..."
done
