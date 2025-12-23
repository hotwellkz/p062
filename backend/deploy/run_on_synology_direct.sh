#!/bin/bash
# Скрипт для прямого запуска на Synology
# Выполните на Synology: bash run_on_synology_direct.sh

cd /volume1/shortsai/app/backend || {
    echo "ERROR: Directory /volume1/shortsai/app/backend not found"
    exit 1
}

echo "========================================"
echo "Running deployment on Synology"
echo "========================================"
echo ""

# Проверка структуры
echo "Checking repository structure..."
ls -la
echo ""

# Проверка наличия папки deploy
if [ ! -d "deploy" ]; then
    echo "ERROR: deploy directory not found"
    echo "Current directory: $(pwd)"
    echo "Contents:"
    ls -la
    echo ""
    echo "Trying to find deploy scripts..."
    find . -name "synology_deploy.sh" -type f 2>/dev/null
    exit 1
fi

# Исправление окончаний строк
echo "Fixing line endings..."
find deploy -name "*.sh" -type f -exec sed -i 's/\r$//' {} \; 2>/dev/null || true
echo "✓ Line endings fixed"
echo ""

# Проверка Node.js
echo "Checking Node.js..."
export PATH="/volume1/@appstore/Node.js_v20/usr/local/bin:$PATH"
if ! command -v node &> /dev/null; then
    echo "ERROR: Node.js not found in PATH"
    echo "Trying to find Node.js..."
    ls -la /volume1/@appstore/Node.js_v20/usr/local/bin/node
    ls -la /usr/local/bin/node
    exit 1
fi

NODE_VERSION=$(node -v)
echo "✓ Node.js: $NODE_VERSION"
echo ""

# Запуск деплоя
echo "Starting deployment..."
bash deploy/synology_deploy.sh





