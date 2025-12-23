#!/bin/bash
# Автоматический деплой с использованием пароля
# ВНИМАНИЕ: После использования удалите этот файл!

VPS_IP="159.255.37.158"
VPS_USER="root"
VPS_PASS="6999LqJiQguX"
SYNO_IP="10.8.0.2"
SYNO_USER="admin"
SYNO_PASS="6999LqJiQguX"

echo "========================================"
echo "Auto-deploying to Synology"
echo "========================================"
echo ""

# Установка sshpass если нужно
if ! command -v sshpass &> /dev/null; then
    echo "Installing sshpass..."
    apt-get update -qq && apt-get install -y -qq sshpass
fi

# 1. Копируем скрипты на VPS
echo "[1/4] Copying files to VPS..."
sshpass -p "$VPS_PASS" scp -o StrictHostKeyChecking=no backend/deploy/synology_deploy.sh "$VPS_USER@$VPS_IP:/tmp/"
sshpass -p "$VPS_PASS" scp -o StrictHostKeyChecking=no backend/deploy/config.sh "$VPS_USER@$VPS_IP:/tmp/"
echo "✓ Files copied to VPS"
echo ""

# 2. Копируем с VPS на Synology
echo "[2/4] Copying files to Synology via VPN..."
sshpass -p "$VPS_PASS" ssh -o StrictHostKeyChecking=no "$VPS_USER@$VPS_IP" "sshpass -p '$SYNO_PASS' scp -o StrictHostKeyChecking=no /tmp/synology_deploy.sh /tmp/config.sh $SYNO_USER@$SYNO_IP:/tmp/"
echo "✓ Files copied to Synology"
echo ""

# 3. Запускаем деплой на Synology
echo "[3/4] Running deployment on Synology..."
sshpass -p "$VPS_PASS" ssh -o StrictHostKeyChecking=no "$VPS_USER@$VPS_IP" "sshpass -p '$SYNO_PASS' ssh -o StrictHostKeyChecking=no $SYNO_USER@$SYNO_IP 'cd /volume1/shortsai/app/backend && find deploy -name \"*.sh\" -type f -exec sed -i \"s/\\r\$//\" {} \\; 2>/dev/null || true && bash deploy/synology_deploy.sh'"
echo ""

# 4. Проверка
echo "[4/4] Checking deployment..."
sshpass -p "$VPS_PASS" ssh -o StrictHostKeyChecking=no "$VPS_USER@$VPS_IP" "curl -s http://10.8.0.2:8080/health || echo 'Backend not responding yet'"
echo ""

echo "========================================"
echo "Deployment completed!"
echo "========================================"
echo ""
echo "IMPORTANT: Delete this file after use!"
echo "rm backend/deploy/auto_deploy_with_password.sh"





