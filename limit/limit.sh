REPO="https://raw.githubusercontent.com/kanghory/schory/main/"
wget -q -O /etc/systemd/system/limitssh.service "${REPO}limit/limitssh.service" && chmod +x limitssh.service >/dev/null 2>&1
chmod +x /etc/ssh/limit.ssh
systemctl daemon-reload
systemctl enable --now limitssh
