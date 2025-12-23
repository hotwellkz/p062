#!/bin/bash
# Скрипт для деплоя на Synology через VPS (VPN туннель)
# Используйте, если прямой SSH к Synology не работает

VPS_IP="159.255.37.158"
VPS_USER="root"
SYNO_IP="10.8.0.2"
SYNO_USER="admin"
LOCAL_SCRIPT="backend/deploy/synology_deploy.sh"
LOCAL_CONFIG="backend/deploy/config.sh"

echo "========================================"
echo "Deploying to Synology via VPS (VPN)"
echo "========================================"
echo ""

# 1. Копируем на VPS
echo "[1/3] Copying files to VPS..."
scp "$LOCAL_SCRIPT" "$VPS_USER@$VPS_IP:/tmp/synology_deploy.sh"
scp "$LOCAL_CONFIG" "$VPS_USER@$VPS_IP:/tmp/config.sh"
echo "✓ Files copied to VPS"
echo ""

# 2. Копируем с VPS на Synology через VPN
echo "[2/3] Copying files from VPS to Synology via VPN..."
ssh "$VPS_USER@$VPS_IP" "scp /tmp/synology_deploy.sh /tmp/config.sh $SYNO_USER@$SYNO_IP:/tmp/"
echo "✓ Files copied to Synology"
echo ""

# 3. Запускаем деплой на Synology
echo "[3/3] Running deployment on Synology..."
ssh "$VPS_USER@$VPS_IP" "ssh $SYNO_USER@$SYNO_IP 'sed -i \"s/\\r\$//\" /tmp/synology_deploy.sh && chmod +x /tmp/*.sh && bash /tmp/synology_deploy.sh'"
echo ""

echo "========================================"
echo "Deployment completed!"
echo "========================================"





