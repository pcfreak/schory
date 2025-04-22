#!/bin/bash
echo -e "Checking update..."
sleep 2

# Hapus file lama
rm -f /usr/bin/menu
rm -f /usr/bin/menun-ssh
rm -f /usr/bin/menu_pw_host
rm -f /usr/bin/menu-backup
rm -f /usr/bin/usernew
rm -f /usr/bin/backup
rm -f /usr/bin/restore
rm -f /usr/bin/menu_limit_ip_ssh
rm -f /usr/bin/menu_bot.tele.sh
rm -f /usr/bin/trialssh

# Download update
echo -e "${YELLOW}Update all repo...${NC}"

urls=(
    "https://raw.githubusercontent.com/kanghory/schory/main/allmenu/menu_limit_ip_ssh.sh"
    "https://raw.githubusercontent.com/kanghory/schory/main/allmenu/menu.sh"
    "https://raw.githubusercontent.com/kanghory/schory/main/allmenu/menun-ssh.sh"
    "https://raw.githubusercontent.com/kanghory/schory/main/allmenu/menu_pw_host.sh"
    "https://raw.githubusercontent.com/kanghory/schory/main/allmenu/menu-backup.sh"
    "https://raw.githubusercontent.com/kanghory/schory/main/allmenu/usernew.sh"
    "https://raw.githubusercontent.com/kanghory/schory/main/backup/backup.sh"
    "https://raw.githubusercontent.com/kanghory/schory/main/backup/restore.sh"
    "https://raw.githubusercontent.com/kanghory/schory/main/bot/menu_bot_tele.sh"
    "https://raw.githubusercontent.com/kanghory/schory/main/allmenu/trialssh.sh"
)

files=(
    "/usr/bin/menu_limit_ip_ssh"
    "/usr/bin/menu"
    "/usr/bin/menun-ssh"
    "/usr/bin/menu_pw_host"
    "/usr/bin/menu-backup"
    "/usr/bin/usernew"
    "/usr/bin/backup"
    "/usr/bin/restore"
    "/usr/bin/menu_bot_tele"
    "/usr/bin/trialssh"
)

for i in ${!urls[@]}; do
    wget -O ${files[$i]} "${urls[$i]}"
    if [[ $? -eq 0 ]]; then
        chmod +x ${files[$i]}
        echo -e "${GREEN}${files[$i]} successfully updated.${NC}"
    else
        echo -e "${RED}Failed to update ${files[$i]}${NC}"
    fi
done

# Clean up
rm -rf update-script.sh

echo -e "${BLUE}--- All scripts have been updated successfully ---${NC}"
echo -e "${GREEN}Press Enter to return to the menu...${NC}"
read -r

# Run the main menu
menu
