#!/bin/bash
# Проверка структуры и запуск деплоя на Synology

echo "========================================"
echo "Checking repository structure"
echo "========================================"
echo ""

cd /volume1/shortsai/app/backend || exit 1

echo "Current directory: $(pwd)"
echo ""
echo "Contents:"
ls -la
echo ""

# Проверка папки deploy
if [ -d "deploy" ]; then
    echo "✓ deploy directory exists"
    echo "Contents of deploy:"
    ls -la deploy/
    echo ""
    
    # Запуск деплоя
    echo "Starting deployment..."
    export PATH="/volume1/@appstore/Node.js_v20/usr/local/bin:$PATH"
    find deploy -name "*.sh" -type f -exec sed -i 's/\r$//' {} \; 2>/dev/null || true
    bash deploy/synology_deploy.sh
else
    echo "✗ deploy directory NOT found"
    echo ""
    echo "Updating repository..."
    cd /volume1/shortsai/app
    git pull origin main || echo "Git pull failed, trying to fetch..."
    git fetch origin main
    git reset --hard origin/main || true
    echo ""
    echo "Checking again..."
    cd backend
    if [ -d "deploy" ]; then
        echo "✓ deploy directory now exists"
        export PATH="/volume1/@appstore/Node.js_v20/usr/local/bin:$PATH"
        find deploy -name "*.sh" -type f -exec sed -i 's/\r$//' {} \; 2>/dev/null || true
        bash deploy/synology_deploy.sh
    else
        echo "✗ deploy directory still not found"
        echo "Repository structure:"
        find . -maxdepth 2 -type d | head -20
        exit 1
    fi
fi





