#!/bin/bash
# Продолжение деплоя вручную (если скрипт завис на установке pm2)
# Выполните на Synology

cd /volume1/shortsai/app/backend || exit 1

export PATH="/volume1/@appstore/Node.js_v20/usr/local/bin:$PATH"

echo "========================================"
echo "Continuing deployment manually"
echo "========================================"
echo ""

# 1. Проверка pm2
echo "[1/4] Checking pm2..."
PM2_CMD=""
if command -v pm2 &> /dev/null; then
    PM2_CMD="pm2"
    echo "✓ pm2 found in PATH"
elif [ -f "/usr/local/bin/pm2" ]; then
    PM2_CMD="/usr/local/bin/pm2"
    echo "✓ pm2 found at /usr/local/bin/pm2"
elif [ -f "/volume1/@appstore/Node.js_v20/usr/local/bin/pm2" ]; then
    PM2_CMD="/volume1/@appstore/Node.js_v20/usr/local/bin/pm2"
    echo "✓ pm2 found at /volume1/@appstore/Node.js_v20/usr/local/bin/pm2"
else
    echo "✗ pm2 not found, trying to install..."
    npm install -g pm2 || {
        echo "Global install failed, trying local..."
        npm install pm2
        PM2_CMD="./node_modules/.bin/pm2"
    }
    if [ -z "$PM2_CMD" ]; then
        PM2_CMD="pm2"  # Try anyway
    fi
fi

PM2_VERSION=$($PM2_CMD -v 2>/dev/null || echo "unknown")
echo "pm2 version: $PM2_VERSION"
echo ""

# 2. Остановка старого процесса
echo "[2/4] Stopping old process..."
$PM2_CMD stop shortsai-backend 2>/dev/null || true
$PM2_CMD delete shortsai-backend 2>/dev/null || true
echo "✓ Old process stopped"
echo ""

# 3. Запуск backend
echo "[3/4] Starting backend..."
mkdir -p /volume1/shortsai/logs

$PM2_CMD start dist/index.js \
    --name shortsai-backend \
    --node-args="--max-old-space-size=2048" \
    --log-date-format="YYYY-MM-DD HH:mm:ss Z" \
    --merge-logs \
    --log /volume1/shortsai/logs/backend.log

if [ $? -eq 0 ]; then
    echo "✓ Backend started"
else
    echo "✗ Failed to start backend"
    exit 1
fi
echo ""

# 4. Сохранение и автозапуск
echo "[4/4] Saving pm2 configuration..."
$PM2_CMD save 2>/dev/null || echo "⚠ Could not save pm2 config"
$PM2_CMD startup 2>/dev/null || echo "⚠ Could not setup startup"
echo "✓ Configuration saved"
echo ""

# 5. Проверка
echo "========================================"
echo "Checking deployment..."
echo "========================================"
echo ""

sleep 5

$PM2_CMD status
echo ""

echo "Testing health endpoint..."
HEALTH=$(curl -s http://127.0.0.1:8080/health 2>/dev/null)
if [ -n "$HEALTH" ]; then
    echo "✓ Health endpoint: $HEALTH"
else
    echo "⚠ Health endpoint not responding yet"
    echo "Check logs: $PM2_CMD logs shortsai-backend"
fi

echo ""
echo "========================================"
echo "Deployment completed!"
echo "========================================"





