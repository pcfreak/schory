#!/bin/bash

# Install Apache di port 8888
install_apache() {
    echo "Installing Apache..."
    apt update
    apt install -y apache2

    echo "Configuring Apache to listen on port 8888..."
    sed -i 's/Listen 80/Listen 8888/' /etc/apache2/ports.conf
    sed -i 's/<VirtualHost \*:80>/<VirtualHost *:8888>/' /etc/apache2/sites-available/000-default.conf

    systemctl restart apache2
    echo "Apache installed and configured on port 8888."
}

# Install Nginx dan konfigurasi proxy ke Apache
install_nginx() {
    echo "Installing Nginx..."
    apt install -y nginx

    echo "Configuring Nginx as reverse proxy..."
    cat > /etc/nginx/sites-available/default <<EOF
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    server_name $DOMAIN;

    location / {
        proxy_pass http://127.0.0.1:8888;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOF

    systemctl restart nginx
    echo "Nginx installed and configured to proxy to Apache."
}

# Install SSL Let's Encrypt
install_ssl() {
    echo "Installing Certbot SSL..."
    apt install -y certbot python3-certbot-nginx

    echo "Issuing SSL Certificate for $DOMAIN..."
    certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos -m admin@$DOMAIN
}

# Install semua
install_all() {
    DOMAIN="$1"
    if [[ -z $DOMAIN ]]; then
        echo "Error: Domain tidak boleh kosong!"
        exit 1
    fi

    install_apache
    install_nginx
    install_ssl

    echo "All installations completed successfully!"
}

# Uninstall semua
uninstall_all() {
    echo "Uninstalling Apache, Nginx, and Certbot..."

    systemctl stop apache2 nginx
    apt purge -y apache2 nginx certbot python3-certbot-nginx
    apt autoremove -y
    rm -rf /etc/apache2 /etc/nginx /etc/letsencrypt

    echo "Uninstallation complete. Web servers and SSL removed."
}

# Menu
while true; do
    clear
    echo "===== Web Server Manager ====="
    echo "1) Install Apache + Nginx + SSL"
    echo "2) Uninstall Apache + Nginx + SSL"
    echo "0) Exit"
    echo "==============================="
    read -p "Choose an option: " menu

    case $menu in
        1)
            read -p "Enter your domain (example.com): " DOMAIN
            install_all "$DOMAIN"
            ;;
        2)
            uninstall_all
            ;;
        0)
            exit
            ;;
        *)
            echo "Invalid option!"
            ;;
    esac
    read -p "Press Enter to continue..."
done
