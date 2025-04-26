#!/bin/bash

# Warna
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

function tambah_website() {
    echo -e "${YELLOW}Menambahkan Website Baru${NC}"
    read -rp "Masukkan nama domain (contoh: domainmu.com): " domain

    mkdir -p /var/www/$domain
    chown -R www-data:www-data /var/www/$domain
    chmod -R 755 /var/www/$domain

    cat > /var/www/$domain/index.html <<-END
<html>
<head><title>Selamat Datang di $domain</title></head>
<body><h1>Website $domain Berjalan dengan Apache!</h1></body>
</html>
END

    cat > /etc/apache2/sites-available/$domain.conf <<-END
<VirtualHost *:80>
    ServerAdmin admin@$domain
    ServerName $domain
    ServerAlias www.$domain
    DocumentRoot /var/www/$domain
    ErrorLog \${APACHE_LOG_DIR}/$domain-error.log
    CustomLog \${APACHE_LOG_DIR}/$domain-access.log combined
</VirtualHost>
END

    a2ensite $domain.conf
    systemctl reload apache2

    echo -e "${YELLOW}Mendapatkan sertifikat SSL Let's Encrypt untuk $domain...${NC}"
    certbot --apache --non-interactive --agree-tos -m admin@$domain -d $domain -d www.$domain

    systemctl restart apache2
    echo -e "${GREEN}Website $domain berhasil dibuat dengan SSL aktif!${NC}"
}

function hapus_website() {
    echo -e "${YELLOW}Menghapus Website${NC}"
    read -rp "Masukkan nama domain yang akan dihapus (contoh: domainmu.com): " domain

    a2dissite $domain.conf
    systemctl reload apache2

    rm -f /etc/apache2/sites-available/$domain.conf
    rm -rf /var/www/$domain
    certbot delete --cert-name $domain

    systemctl restart apache2
    echo -e "${GREEN}Website $domain berhasil dihapus.${NC}"
}

function list_website() {
    echo -e "${YELLOW}Daftar Website Aktif:${NC}"
    ls /etc/apache2/sites-enabled/ | sed 's/.conf$//'
}

function renew_ssl() {
    echo -e "${YELLOW}Perpanjang SSL Manual${NC}"
    certbot renew --force-renewal
    systemctl reload apache2
    echo -e "${GREEN}Perpanjangan SSL selesai.${NC}"
}

function uninstall_webserver() {
    echo -e "${RED}WARNING: Ini akan menghapus semua website, SSL, dan konfigurasi apache2!${NC}"
    read -rp "Yakin mau lanjut? (yes/no): " confirm
    if [[ "$confirm" == "yes" ]]; then
        echo -e "${YELLOW}Menghapus Apache2, website, dan SSL...${NC}"
        
        systemctl stop apache2
        apt purge apache2* certbot python3-certbot* -y
        apt autoremove --purge -y
        apt clean

        rm -rf /var/www/*
        rm -rf /etc/apache2
        rm -rf /etc/letsencrypt
        rm -rf /var/log/apache2

        echo -e "${GREEN}Apache2, website, dan SSL berhasil dihapus bersih.${NC}"
    else
        echo -e "${RED}Batal menghapus Web Server.${NC}"
    fi
}

function install_webserver() {
    echo -e "${YELLOW}Menginstall Apache2 dan Certbot...${NC}"
    apt update -y
    apt install apache2 certbot python3-certbot-apache -y
    systemctl enable apache2
    systemctl start apache2
    echo -e "${GREEN}Apache2 dan Certbot berhasil dipasang.${NC}"
}

function cek_instalasi() {
    if ! command -v apache2 > /dev/null; then
        echo -e "${YELLOW}Apache2 belum terinstall.${NC}"
    fi

    if ! command -v certbot > /dev/null; then
        echo -e "${YELLOW}Certbot belum terinstall.${NC}"
    fi
}

# Main Program
cek_instalasi
while true; do
    clear
    echo -e "${GREEN}=== Apache Multi Website Manager ===${NC}"
    echo "[1] Tambah Website Baru"
    echo "[2] Hapus Website"
    echo "[3] Lihat Website Aktif"
    echo "[4] Perpanjang SSL Manual"
    echo "[5] Uninstall Web Server (hapus semua)"
    echo "[6] Install Web Server (Apache2 + Certbot)"
    echo "[0] Exit"
    echo
    read -rp "Pilih opsi: " opsi

    case $opsi in
        1) tambah_website ;;
        2) hapus_website ;;
        3) list_website ;;
        4) renew_ssl ;;
        5) uninstall_webserver ;;
        6) install_webserver ;;
        0) exit ;;
        *) echo -e "${RED}Pilihan tidak valid.${NC}"; sleep 1 ;;
    esac
done
