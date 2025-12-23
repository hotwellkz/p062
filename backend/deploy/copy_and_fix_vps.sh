#!/bin/bash

# Скрипт для копирования файла на VPS с автоматическим исправлением окончаний строк

VPS_IP="159.255.37.158"
VPS_USER="root"
FILE="backend/vps/synology-port-forward.sh"
REMOTE_PATH="/root/synology-port-forward.sh"

echo "Copying file to VPS..."
scp "$FILE" "$VPS_USER@$VPS_IP:$REMOTE_PATH"

echo "Fixing line endings and running script on VPS..."
ssh "$VPS_USER@$VPS_IP" << 'EOF'
sed -i 's/\r$//' /root/synology-port-forward.sh
chmod +x /root/synology-port-forward.sh
bash /root/synology-port-forward.sh
EOF

echo "Done!"





