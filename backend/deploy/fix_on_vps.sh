#!/bin/bash
# Скрипт для исправления и запуска на VPS
# Запустите этот скрипт прямо на VPS: bash fix_on_vps.sh

set -e

echo "========================================"
echo "Fixing and running synology-port-forward.sh"
echo "========================================"
echo ""

# Исправляем окончания строк
echo "[1/3] Fixing line endings (CRLF -> LF)..."
sed -i 's/\r$//' /root/synology-port-forward.sh
echo "✓ Line endings fixed"
echo ""

# Устанавливаем права
echo "[2/3] Setting executable permissions..."
chmod +x /root/synology-port-forward.sh
echo "✓ Permissions set"
echo ""

# Запускаем скрипт
echo "[3/3] Running synology-port-forward.sh..."
echo ""
bash /root/synology-port-forward.sh

echo ""
echo "========================================"
echo "Done!"
echo "========================================"





