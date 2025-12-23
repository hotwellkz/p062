#!/bin/bash
# Скрипт для установки Node.js на Synology
# Запустите на Synology: bash install_nodejs_synology.sh

set -e

echo "========================================"
echo "Installing Node.js on Synology"
echo "========================================"
echo ""

# Проверка, запущен ли на Synology
if [ ! -d "/volume1" ]; then
    echo "ERROR: This script must be run on Synology NAS"
    echo "Current system: $(uname -a)"
    exit 1
fi

echo "Detected Synology NAS"
echo ""

# Метод 1: Через Synology Package Center (рекомендуется)
echo "[Method 1] Checking if Node.js is available via Package Center..."
echo "If Node.js is not installed:"
echo "  1. Open DSM web interface"
echo "  2. Go to Package Center"
echo "  3. Search for 'Node.js'"
echo "  4. Install Node.js v20 (or latest LTS)"
echo ""

# Метод 2: Через ipkg (если доступен)
if command -v ipkg &> /dev/null; then
    echo "[Method 2] ipkg is available"
    echo "Installing Node.js via ipkg..."
    ipkg update
    ipkg install node
    echo "✓ Node.js installed via ipkg"
elif [ -f "/opt/bin/ipkg" ]; then
    echo "[Method 2] ipkg found at /opt/bin/ipkg"
    /opt/bin/ipkg update
    /opt/bin/ipkg install node
    echo "✓ Node.js installed via ipkg"
else
    echo "[Method 2] ipkg not available"
    echo "  Install ipkg first or use Package Center"
fi

# Метод 3: Ручная установка через nvm (если нужно)
echo ""
echo "[Method 3] Manual installation via nvm (if needed):"
echo "  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash"
echo "  source ~/.bashrc"
echo "  nvm install 20"
echo "  nvm use 20"
echo ""

# Проверка установки
echo "========================================"
echo "Checking Node.js installation..."
echo "========================================"

if command -v node &> /dev/null; then
    NODE_VERSION=$(node -v)
    echo "✓ Node.js is installed: $NODE_VERSION"
    
    if command -v npm &> /dev/null; then
        NPM_VERSION=$(npm -v)
        echo "✓ npm is installed: $NPM_VERSION"
    else
        echo "✗ npm is not found"
    fi
else
    echo "✗ Node.js is NOT installed"
    echo ""
    echo "Please install Node.js using one of the methods above"
    echo "Then run the deployment script again"
    exit 1
fi

echo ""
echo "========================================"
echo "Node.js installation check completed"
echo "========================================"





