#!/bin/bash

# ============================================
# Скрипт для установки и запуска на Synology
# ============================================
# Запускайте ЭТОТ скрипт НА SYNOLOGY
# Использование: bash setup_on_synology.sh
# ============================================

set -e

# Цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

error() {
    echo -e "${RED}❌ Ошибка: $1${NC}" >&2
    exit 1
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

info() {
    echo -e "${YELLOW}ℹ️  $1${NC}"
}

section() {
    echo ""
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}============================================${NC}"
    echo ""
}

# Определяем текущую директорию backend
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ "$SCRIPT_DIR" == *"deploy"* ]]; then
    BACKEND_DIR="$(dirname "$SCRIPT_DIR")"
else
    BACKEND_DIR="$SCRIPT_DIR"
fi

cd "$BACKEND_DIR" || error "Не удалось перейти в директорию backend: $BACKEND_DIR"

section "🚀 Установка и запуск ShortsAI Backend на Synology"

info "Текущая директория: $(pwd)"

# Шаг 1: Проверка Node.js и PM2
section "Шаг 1: Проверка Node.js и PM2"
info "Проверяю Node.js..."
if command -v node &> /dev/null; then
    NODE_VERSION=$(node -v)
    success "Node.js: $NODE_VERSION"
else
    error "Node.js не установлен. Установите через Package Center."
fi

info "Проверяю npm..."
if command -v npm &> /dev/null; then
    NPM_VERSION=$(npm -v)
    success "npm: $NPM_VERSION"
else
    error "npm не установлен."
fi

info "Проверяю pm2..."
if command -v pm2 &> /dev/null; then
    PM2_VERSION=$(pm2 -v)
    success "pm2: $PM2_VERSION"
else
    info "pm2 не установлен, устанавливаю локально..."
    # Сначала пробуем установить локально (быстрее и надёжнее)
    if [ -f "package.json" ] && grep -q '"pm2"' package.json; then
        info "Устанавливаю pm2 из package.json..."
        npm install pm2 --save-dev --no-audit --prefer-offline 2>&1 | head -20 || true
        # Используем локальный pm2
        if [ -f "node_modules/.bin/pm2" ]; then
            alias pm2="node_modules/.bin/pm2"
            success "pm2 установлен локально"
        else
            info "Локальная установка не удалась, пробую глобально (может занять время)..."
            timeout 60 npm install -g pm2 2>&1 | head -20 || {
                info "⚠️  Глобальная установка не удалась или зависла"
                info "Попробуйте установить pm2 вручную:"
                info "  1. npm install pm2 --save-dev"
                info "  2. Затем используйте: node_modules/.bin/pm2 start dist/index.js --name shortsai-backend"
                error "Не удалось установить pm2 автоматически"
            }
        fi
    else
        info "Пробую установить pm2 глобально (может занять время)..."
        timeout 60 npm install -g pm2 2>&1 | head -20 || {
            info "⚠️  Установка pm2 не удалась"
            info "Попробуйте установить вручную:"
            info "  npm install -g pm2"
            error "Не удалось установить pm2"
        }
    fi
    success "pm2 установлен"
fi

# Шаг 2: Настройка .env
section "Шаг 2: Настройка .env"
if [ ! -f ".env" ]; then
    if [ -f "env.example" ]; then
        info ".env не найден, создаю из env.example..."
        cp env.example .env
        info "⚠️  ВАЖНО: Настройте .env вручную!"
        info "   Выполните: nano .env"
    else
        info "⚠️  .env не найден и env.example отсутствует"
    fi
else
    success ".env уже существует"
fi

# Шаг 3: Установка зависимостей и сборка
section "Шаг 3: Установка зависимостей и сборка"
info "Устанавливаю зависимости..."
rm -rf node_modules
npm install || error "Не удалось установить зависимости"
success "Зависимости установлены"

info "Собираю проект..."
npm run build || error "Не удалось собрать проект"
success "Проект собран"

# Шаг 4: Запуск через PM2
section "Шаг 4: Запуск через PM2"
info "Останавливаю старый процесс (если есть)..."
pm2 stop shortsai-backend 2>/dev/null || true
pm2 delete shortsai-backend 2>/dev/null || true

info "Запускаю backend через PM2..."
if [ -f "dist/index.js" ]; then
    # Используем локальный pm2 если доступен
    if [ -f "node_modules/.bin/pm2" ]; then
        node_modules/.bin/pm2 start dist/index.js --name shortsai-backend || error "Не удалось запустить backend"
    else
        pm2 start dist/index.js --name shortsai-backend || error "Не удалось запустить backend"
    fi
else
    error "Файл dist/index.js не найден. Убедитесь, что сборка прошла успешно."
fi

info "Настраиваю автозапуск..."
if [ -f "node_modules/.bin/pm2" ]; then
    node_modules/.bin/pm2 save || error "Не удалось сохранить конфигурацию PM2"
else
    pm2 save || error "Не удалось сохранить конфигурацию PM2"
fi

info "Проверяю статус..."
if [ -f "node_modules/.bin/pm2" ]; then
    node_modules/.bin/pm2 status
else
    pm2 status
fi
success "Backend запущен через PM2"

# Шаг 5: Проверка работы
section "Шаг 5: Проверка работы backend"
info "Определяю порт из .env..."
if [ -f ".env" ]; then
    PORT=$(grep -E '^PORT=' .env | cut -d'=' -f2 | tr -d '"' | tr -d "'" || echo "8080")
else
    PORT="8080"
fi
if [ -z "$PORT" ]; then
    PORT="8080"
fi
info "Порт backend: $PORT"

info "Проверяю health endpoint..."
sleep 2
HEALTH_RESPONSE=$(curl -s http://localhost:$PORT/health || curl -s http://localhost:$PORT/ || echo "ERROR")
if [ "$HEALTH_RESPONSE" != "ERROR" ] && [ -n "$HEALTH_RESPONSE" ]; then
    success "Backend отвечает!"
    echo "Ответ: $HEALTH_RESPONSE"
else
    info "⚠️  Backend не отвечает на health endpoint"
    info "Проверьте логи: pm2 logs shortsai-backend"
fi

section "🎉 Установка завершена!"

success "Backend успешно установлен и запущен на Synology!"
echo ""
info "Полезные команды:"
echo -e "  ${GREEN}Перезапустить backend:${NC} pm2 restart shortsai-backend"
echo -e "  ${GREEN}Просмотр логов:${NC} pm2 logs shortsai-backend"
echo -e "  ${GREEN}Статус:${NC} pm2 status"
echo -e "  ${GREEN}Проверка health:${NC} curl http://localhost:$PORT/health"
echo ""

