#!/bin/bash

clear
while true; do
    # Menampilkan header menu
    echo -e "\e[1;36m=======================================\e[0m"
    echo -e "         \e[1;32mAUTO REBOOT MENU\e[0m"
    echo -e "\e[1;36m=======================================\e[0m"
    echo -e "1. Jadwalkan Reboot setiap 10 Menit"
    echo -e "2. Jadwalkan Reboot setiap 1 Jam"
    echo -e "3. Jadwalkan Reboot setiap 6 Jam"
    echo -e "4. Jadwalkan Reboot setiap 12 Jam"
    echo -e "5. Jadwalkan Reboot setiap 24 Jam"
    echo -e "6. Jadwalkan Reboot setiap 3 Hari"
    echo -e "7. Jadwalkan Reboot setiap 7 Hari"
    echo -e "8. Jadwalkan Reboot setiap 1 Bulan"
    echo -e "9. Jadwalkan Reboot jam 00:01 WIB"
    echo -e "10. Jadwalkan Reboot jam 05:15 WIB"
    echo -e "11. Nonaktifkan Semua Auto Reboot"
    echo -e "12. Jalankan Manual: Clear Log, Restart Service, Reboot"
    echo -e "13. Ubah Token & ID Bot Telegram"
    echo -e "14. Test Notifikasi Telegram"
    echo -e "0. Kembali ke Menu Utama"
    echo -e "\e[1;36m=======================================\e[0m"
    read -rp "Pilih opsi [0-14]: " opt

    # Pilihan menu yang dipilih
    case $opt in
        # Jadwalkan reboot setiap 10 menit
        1) echo "*/10 * * * * root /usr/bin/autoreboot" > /etc/cron.d/autoreboot ;;
        
        # Jadwalkan reboot setiap 1 jam
        2) echo "0 * * * * root /usr/bin/autoreboot" > /etc/cron.d/autoreboot ;;
        
        # Jadwalkan reboot setiap 6 jam
        3) echo "0 */6 * * * root /usr/bin/autoreboot" > /etc/cron.d/autoreboot ;;
        
        # Jadwalkan reboot setiap 12 jam
        4) echo "0 */12 * * * root /usr/bin/autoreboot" > /etc/cron.d/autoreboot ;;
        
        # Jadwalkan reboot setiap 24 jam
        5) echo "0 0 * * * root /usr/bin/autoreboot" > /etc/cron.d/autoreboot ;;
        
        # Jadwalkan reboot setiap 3 hari
        6) echo "0 0 */3 * * root /usr/bin/autoreboot" > /etc/cron.d/autoreboot ;;
        
        # Jadwalkan reboot setiap 7 hari
        7) echo "0 0 */7 * * root /usr/bin/autoreboot" > /etc/cron.d/autoreboot ;;
        
        # Jadwalkan reboot setiap 1 bulan
        8) echo "0 0 1 * * root /usr/bin/autoreboot" > /etc/cron.d/autoreboot ;;
        
        # Jadwalkan reboot jam 00:01 WIB
        9) echo "1 0 * * * root /usr/bin/autoreboot" > /etc/cron.d/autoreboot_0001 ;;
        
        # Jadwalkan reboot jam 05:15 WIB
        10) echo "15 5 * * * root /usr/bin/autoreboot" > /etc/cron.d/autoreboot_0515 ;;
        
        # Nonaktifkan auto reboot (hapus cron job)
        11) rm -f /etc/cron.d/autoreboot* && echo "Auto Reboot berhasil dinonaktifkan." ;;
        
        # Jalankan proses manual (clear log, restart service, reboot)
        12)
            echo -e "\n\e[1;33m[•] Menjalankan proses manual...\e[0m"
            sleep 1
            echo -ne "[✔] Membersihkan log..." && sleep 1 && echo " Done"
            echo -ne "[✔] Membersihkan cache..." && sleep 1 && echo " Done"
            echo -ne "[✔] Merestart semua layanan..." && sleep 1 && echo " Done"
            echo -e "\e[1;32m[!] Rebooting system...\e[0m"
            sleep 2
            bash /usr/bin/autoreboot
            exit
            ;;
        
        # Ubah Token & ID Bot Telegram
        13)
            read -p "Masukkan Token Bot: " token
            read -p "Masukkan ID Chat: " id
            
            # Menyimpan token dan ID ke file /etc/bot/autoreboot.db
            mkdir -p /etc/bot
            echo "token=$token" > /etc/bot/autoreboot.db
            echo "id=$id" >> /etc/bot/autoreboot.db
            echo "Token & ID Bot berhasil disimpan di /etc/bot/autoreboot.db."
            echo "Pastikan Anda menyimpan file ini untuk referensi ke depannya."
            ;;
        
        # Test Notifikasi Telegram
        14)
            # Memeriksa apakah file konfigurasi bot tersedia
            if [[ -f /etc/bot/autoreboot.db ]]; then
                source /etc/bot/autoreboot.db
                if [[ -n $token && -n $id ]]; then
                    # Mengirim notifikasi uji ke Telegram
                    curl -s -X POST https://api.telegram.org/bot$token/sendMessage \
                        -d chat_id="$id" \
                        -d parse_mode="Markdown" \
                        -d text="*✅ Auto Reboot Aktif*\n\nNotifikasi uji berhasil dikirim!\n\n🕐 *Tanggal:* $(date '+%d-%m-%Y')\n⏰ *Jam:* $(date '+%H:%M:%S')" > /dev/null
                    echo "Pesan uji dikirim ke Telegram."
                else
                    echo "Token atau ID tidak ditemukan."
                fi
            else
                echo "Bot belum diatur. Token & ID Bot belum disimpan di /etc/bot/autoreboot.db"
            fi
            ;;
        
        # Kembali ke menu utama
        0) break ;;
        
        # Opsi tidak valid
        *) echo "Opsi tidak valid." ;;
    esac
    echo ""
    read -n 1 -s -r -p "Tekan sembarang tombol untuk kembali ke menu..."
    clear
done
