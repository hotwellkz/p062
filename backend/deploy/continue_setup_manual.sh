#!/bin/bash

# ============================================
# Продолжение установки вручную
# ============================================
# Используйте этот скрипт, если setup_on_synology.sh завис
# ============================================

set -e

echo "============================================"
echo "Продолжение установки вручную"
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

# Шаг 1: Установка pm2 локально
echo "Шаг 1: Установка pm2 локально..."
if [ -f "package.json" ]; then
    echo "Устанавливаю pm2 из package.json..."
    npm install pm2 --save-dev --no-audit 2>&1 | head -30
    echo ""
fi

# Шаг 2: Проверка pm2
echo "Шаг 2: Проверка pm2..."
if [ -f "node_modules/.bin/pm2" ]; then
    echo "✅ pm2 установлен локально"
    PM2_CMD="node_modules/.bin/pm2"
elif command -v pm2 &> /dev/null; then
    echo "✅ pm2 установлен глобально"
    PM2_CMD="pm2"
else
    echo "❌ pm2 не найден"
    echo "Попробуйте установить вручную:"
    echo "  npm install pm2 --save-dev"
    exit 1
fi

# Шаг 3: Проверка сборки
echo ""
echo "Шаг 3: Проверка сборки..."
if [ ! -f "dist/index.js" ]; then
    echo "⚠️  dist/index.js не найден, собираю проект..."
    npm run build || {
        echo "❌ Сборка не удалась"
        exit 1
    }
fi
echo "✅ Проект собран"

# Шаг 4: Остановка старого процесса
echo ""
echo "Шаг 4: Остановка старого процесса..."
$PM2_CMD stop shortsai-backend 2>/dev/null || true
$PM2_CMD delete shortsai-backend 2>/dev/null || true

# Шаг 5: Запуск backend
echo ""
echo "Шаг 5: Запуск backend..."
$PM2_CMD start dist/index.js --name shortsai-backend || {
    echo "❌ Не удалось запустить backend"
    exit 1
}

# Шаг 6: Сохранение конфигурации
echo ""
echo "Шаг 6: Сохранение конфигурации PM2..."
$PM2_CMD save || {
    echo "⚠️  Не удалось сохранить конфигурацию"
}

# Шаг 7: Настройка автозапуска
echo ""
echo "Шаг 7: Настройка автозапуска..."
echo ""
echo "⚠️  ВАЖНО: PM2 выдаст команду для настройки автозапуска."
echo "   Скопируйте и выполните ИМЕННО ТУ КОМАНДУ, которую выдаст pm2!"
echo ""
echo "Выполняю pm2 startup..."
echo ""

STARTUP_OUTPUT=$($PM2_CMD startup 2>&1)
echo "$STARTUP_OUTPUT"
echo ""

STARTUP_CMD=$(echo "$STARTUP_OUTPUT" | grep -E "sudo env" || echo "")

if [ -n "$STARTUP_CMD" ]; then
    echo "============================================"
    echo "⚠️  ВЫПОЛНИТЕ ЭТУ КОМАНДУ ВРУЧНУЮ:"
    echo "============================================"
    echo "$STARTUP_CMD"
    echo "============================================"
    echo ""
    echo "⚠️  Скопируйте команду выше и выполните её"
    echo "   (потребуется пароль admin для sudo)"
    echo ""
else
    echo "⚠️  PM2 не выдал команду автоматически"
    echo "Попробуйте выполнить вручную:"
    echo "  $PM2_CMD startup"
    echo "И выполните команду, которую он выдаст"
fi

# Шаг 8: Статус
echo ""
echo "Шаг 8: Статус PM2..."
$PM2_CMD status

echo ""
echo "============================================"
echo "✅ Установка завершена!"
echo "============================================"
echo ""
echo "Полезные команды:"
echo "  Перезапуск: $PM2_CMD restart shortsai-backend"
echo "  Логи: $PM2_CMD logs shortsai-backend"
echo "  Статус: $PM2_CMD status"
echo ""
echo "Для удобства создайте алиас:"
echo "  echo 'alias pm2=\"$PM2_CMD\"' >> ~/.bashrc"
echo "  source ~/.bashrc"
echo ""

