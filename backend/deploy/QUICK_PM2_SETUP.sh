#!/bin/bash

# ============================================
# Быстрая установка и настройка PM2
# ============================================
# Использование: bash deploy/QUICK_PM2_SETUP.sh
# ============================================

set -e

echo "============================================"
echo "Быстрая установка PM2 на Synology"
echo "============================================"
echo ""

# Определяем директорию
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ "$SCRIPT_DIR" == *"deploy"* ]]; then
    BACKEND_DIR="$(dirname "$SCRIPT_DIR")"
else
    BACKEND_DIR="$SCRIPT_DIR"
fi

cd "$BACKEND_DIR" || exit 1

echo "Текущая директория: $(pwd)"
echo ""

# Шаг 1: Установка pm2
echo "Шаг 1: Установка pm2 локально..."
npm install pm2 --save-dev
echo "✅ pm2 установлен"
echo ""

# Шаг 2: Проверка сборки
echo "Шаг 2: Проверка сборки..."
if [ ! -f "dist/index.js" ]; then
    echo "⚠️  dist/index.js не найден, собираю проект..."
    npm run build
fi
echo "✅ Проект готов"
echo ""

# Шаг 3: Остановка старого процесса
echo "Шаг 3: Остановка старого процесса..."
node_modules/.bin/pm2 stop shortsai-backend 2>/dev/null || true
node_modules/.bin/pm2 delete shortsai-backend 2>/dev/null || true
echo "✅ Старый процесс остановлен"
echo ""

# Шаг 4: Запуск backend
echo "Шаг 4: Запуск backend..."
node_modules/.bin/pm2 start dist/index.js --name shortsai-backend
echo "✅ Backend запущен"
echo ""

# Шаг 5: Сохранение конфигурации
echo "Шаг 5: Сохранение конфигурации PM2..."
node_modules/.bin/pm2 save
echo "✅ Конфигурация сохранена"
echo ""

# Шаг 6: Настройка автозапуска
echo "Шаг 6: Настройка автозапуска..."
echo ""
echo "⚠️  ВАЖНО: PM2 выдаст команду для настройки автозапуска."
echo "   Скопируйте и выполните ИМЕННО ТУ КОМАНДУ, которую выдаст pm2!"
echo ""
echo "Выполняю pm2 startup..."
echo ""

STARTUP_CMD=$(node_modules/.bin/pm2 startup 2>&1 | grep -E "sudo env" || echo "")

if [ -n "$STARTUP_CMD" ]; then
    echo "============================================"
    echo "Выполните эту команду:"
    echo "============================================"
    echo "$STARTUP_CMD"
    echo "============================================"
    echo ""
    echo "⚠️  Скопируйте команду выше и выполните её вручную"
    echo "   (потребуется пароль admin для sudo)"
    echo ""
else
    echo "⚠️  PM2 не выдал команду автоматически"
    echo "Попробуйте выполнить вручную:"
    echo "  node_modules/.bin/pm2 startup"
    echo "И выполните команду, которую он выдаст"
fi

# Шаг 7: Статус
echo ""
echo "Шаг 7: Статус PM2..."
node_modules/.bin/pm2 status

echo ""
echo "============================================"
echo "✅ Установка завершена!"
echo "============================================"
echo ""
echo "Полезные команды:"
echo "  Перезапуск: node_modules/.bin/pm2 restart shortsai-backend"
echo "  Логи: node_modules/.bin/pm2 logs shortsai-backend"
echo "  Статус: node_modules/.bin/pm2 status"
echo ""
echo "Для удобства создайте алиас:"
echo "  echo 'alias pm2=\"$(pwd)/node_modules/.bin/pm2\"' >> ~/.bashrc"
echo "  source ~/.bashrc"
echo ""




