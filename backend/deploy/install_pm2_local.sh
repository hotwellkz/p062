#!/bin/bash
# Установка pm2 локально и запуск backend
# Выполните на Synology

cd /volume1/shortsai/app/backend || exit 1

export PATH="/volume1/@appstore/Node.js_v20/usr/local/bin:$PATH"

echo "========================================"
echo "Installing pm2 locally and starting backend"
echo "========================================"
echo ""

# 1. Установка pm2 локально
echo "[1/5] Installing pm2 locally..."
if [ ! -f "./node_modules/.bin/pm2" ]; then
    npm install pm2
    if [ $? -ne 0 ]; then
        echo "✗ Failed to install pm2"
        exit 1
    fi
    echo "✓ pm2 installed locally"
else
    echo "✓ pm2 already installed locally"
fi
echo ""

# 2. Определение пути к pm2
PM2_CMD="./node_modules/.bin/pm2"
echo "[2/5] Using pm2: $PM2_CMD"
$PM2_CMD -v
echo ""

# 3. Остановка старого процесса
echo "[3/5] Stopping old process..."
$PM2_CMD stop shortsai-backend 2>/dev/null || true
$PM2_CMD delete shortsai-backend 2>/dev/null || true
echo "✓ Old process stopped"
echo ""

# 4. Запуск backend
echo "[4/5] Starting backend..."
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

# 5. Сохранение и проверка
echo "[5/5] Saving configuration and checking..."
$PM2_CMD save 2>/dev/null || echo "⚠ Could not save pm2 config"
echo "✓ Configuration saved"
echo ""

sleep 5

echo "========================================"
echo "Status:"
echo "========================================"
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
echo "Done! Use '$PM2_CMD' to manage backend"
echo "========================================"





