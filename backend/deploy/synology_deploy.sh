#!/bin/bash

# ============================================
# Скрипт деплоя на Synology
# ============================================
# Выполняет полный деплой backend на Synology NAS
# ============================================

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Загрузка конфигурации
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/config.sh" ]; then
    source "$SCRIPT_DIR/config.sh"
else
    echo -e "${RED}❌ Ошибка: config.sh не найден${NC}"
    exit 1
fi

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

section "Деплой ShortsAI Backend на Synology"

# 1. Создание директорий
info "Создаю директории..."
mkdir -p "$SYNO_APP_PATH" || error "Не удалось создать $SYNO_APP_PATH"
mkdir -p "$SYNO_STORAGE_PATH" || error "Не удалось создать $SYNO_STORAGE_PATH"
success "Директории созданы"

# 2. Клонирование/обновление репозитория
section "Работа с репозиторием"

cd "$SYNO_APP_PATH" || error "Не удалось перейти в $SYNO_APP_PATH"

if [ -d "$SYNO_APP_PATH/.git" ]; then
    info "Репозиторий уже существует, обновляю..."
    
    # Исправление прав доступа
    chown -R "$SYNO_USER:users" "$SYNO_APP_PATH" 2>/dev/null || true
    chmod -R 755 "$SYNO_APP_PATH" 2>/dev/null || true
    
    # Отмена локальных изменений перед обновлением
    git fetch origin "$GITHUB_BRANCH" || error "Не удалось получить изменения из репозитория"
    git reset --hard "origin/$GITHUB_BRANCH" || error "Не удалось обновить репозиторий"
    git clean -fd || true
    
    success "Репозиторий обновлён"
else
    info "Клонирую репозиторий..."
    git clone -b "$GITHUB_BRANCH" "$GITHUB_REPO_URL" "$SYNO_APP_PATH" || error "Не удалось клонировать репозиторий"
    
    chown -R "$SYNO_USER:users" "$SYNO_APP_PATH" 2>/dev/null || true
    chmod -R 755 "$SYNO_APP_PATH" 2>/dev/null || true
    
    success "Репозиторий клонирован"
fi

# 3. Переход в директорию backend
cd "$SYNO_BACKEND_PATH" || error "Директория backend не найдена: $SYNO_BACKEND_PATH"

# Исправление окончаний строк для скриптов
find . -name "*.sh" -type f -exec sed -i 's/\r$//' {} \; 2>/dev/null || true

# 4. Проверка Node.js
section "Проверка Node.js"

# Проверяем различные возможные пути к Node.js на Synology
NODE_CMD=""
if command -v node &> /dev/null; then
    NODE_CMD="node"
elif [ -f "/volume1/@appstore/Node.js_v20/usr/local/bin/node" ]; then
    NODE_CMD="/volume1/@appstore/Node.js_v20/usr/local/bin/node"
    export PATH="/volume1/@appstore/Node.js_v20/usr/local/bin:$PATH"
elif [ -f "/usr/local/bin/node" ]; then
    NODE_CMD="/usr/local/bin/node"
    export PATH="/usr/local/bin:$PATH"
elif [ -f "/opt/bin/node" ]; then
    NODE_CMD="/opt/bin/node"
    export PATH="/opt/bin:$PATH"
fi

if [ -z "$NODE_CMD" ]; then
    error "Node.js не установлен. Установите через Synology Package Center или ipkg"
    info "Инструкции: см. backend/deploy/SETUP_SYNOLOGY_NODEJS.md"
    exit 1
fi

NODE_VERSION=$($NODE_CMD -v)
info "Node.js версия: $NODE_VERSION (путь: $NODE_CMD)"

# Проверка npm
NPM_CMD=""
if command -v npm &> /dev/null; then
    NPM_CMD="npm"
elif [ -f "/volume1/@appstore/Node.js_v20/usr/local/bin/npm" ]; then
    NPM_CMD="/volume1/@appstore/Node.js_v20/usr/local/bin/npm"
elif [ -f "/usr/local/bin/npm" ]; then
    NPM_CMD="/usr/local/bin/npm"
elif [ -f "/opt/bin/npm" ]; then
    NPM_CMD="/opt/bin/npm"
fi

if [ -z "$NPM_CMD" ]; then
    error "npm не установлен"
    exit 1
fi

NPM_VERSION=$($NPM_CMD -v)
info "npm версия: $NPM_VERSION (путь: $NPM_CMD)"

# 5. Установка зависимостей
section "Установка зависимостей"

info "Устанавливаю зависимости (включая dev для компиляции)..."
$NPM_CMD install || error "Не удалось установить зависимости"
success "Зависимости установлены"

# 6. Компиляция TypeScript
section "Компиляция TypeScript"

info "Компилирую TypeScript..."
$NPM_CMD run build || error "Не удалось скомпилировать TypeScript"
success "TypeScript скомпилирован"

# 7. Настройка .env
section "Настройка .env"

ENV_FILE=".env"
ENV_EXAMPLE_FILE="env.example"

if [ ! -f "$ENV_FILE" ]; then
    info "Создаю .env из $ENV_EXAMPLE_FILE..."
    if [ -f "$ENV_EXAMPLE_FILE" ]; then
        cp "$ENV_EXAMPLE_FILE" "$ENV_FILE"
        success ".env создан из примера"
        info "⚠️  ВАЖНО: Заполните секреты в $ENV_FILE перед запуском!"
    else
        error "Файл $ENV_EXAMPLE_FILE не найден"
    fi
else
    info ".env уже существует, не трогаю"
fi

# Обновление критичных переменных в .env (если они не установлены)
info "Обновляю критичные переменные в .env..."

# Удаляем старые записи для избежания дубликатов
sed -i '/^NODE_ENV=/d' "$ENV_FILE" 2>/dev/null || true
sed -i '/^PORT=/d' "$ENV_FILE" 2>/dev/null || true
sed -i '/^STORAGE_ROOT=/d' "$ENV_FILE" 2>/dev/null || true
sed -i '/^BACKEND_URL=/d' "$ENV_FILE" 2>/dev/null || true

# Добавляем новые значения
cat >> "$ENV_FILE" << EOF

# ============================================
# Production Settings (Synology) - Auto-generated
# ============================================
NODE_ENV=$NODE_ENV
PORT=$BACKEND_PORT
STORAGE_ROOT=$SYNO_STORAGE_PATH
BACKEND_URL=$BACKEND_URL
EOF

success ".env настроен"

# 8. Установка pm2
section "Настройка pm2"

PM2_CMD="pm2"

if ! command -v pm2 &> /dev/null; then
    info "Устанавливаю pm2 глобально..."
    $NPM_CMD install -g pm2 || error "Не удалось установить pm2"
    success "pm2 установлен"
    
    # Определяем путь к pm2
    if command -v pm2 &> /dev/null; then
        PM2_CMD="pm2"
    elif [ -f "/usr/local/bin/pm2" ]; then
        PM2_CMD="/usr/local/bin/pm2"
    elif [ -f "/volume1/@appstore/Node.js_v20/usr/local/bin/pm2" ]; then
        PM2_CMD="/volume1/@appstore/Node.js_v20/usr/local/bin/pm2"
    else
        PM2_CMD="$(npm bin -g)/pm2"
    fi
else
    info "pm2 уже установлен"
    # Определяем путь к pm2
    if command -v pm2 &> /dev/null; then
        PM2_CMD="pm2"
    elif [ -f "/usr/local/bin/pm2" ]; then
        PM2_CMD="/usr/local/bin/pm2"
    elif [ -f "/volume1/@appstore/Node.js_v20/usr/local/bin/pm2" ]; then
        PM2_CMD="/volume1/@appstore/Node.js_v20/usr/local/bin/pm2"
    else
        PM2_CMD="$(npm bin -g)/pm2"
    fi
fi

# Настройка автозапуска pm2
info "Настраиваю автозапуск pm2..."
$PM2_CMD startup 2>/dev/null || info "Автозапуск pm2 уже настроен или требует ручной настройки"
success "pm2 настроен"

# 9. Остановка старого процесса (если запущен)
info "Останавливаю старый процесс (если запущен)..."
$PM2_CMD stop "$PM2_APP_NAME" 2>/dev/null || true
$PM2_CMD delete "$PM2_APP_NAME" 2>/dev/null || true

# 10. Запуск через pm2
section "Запуск backend"

info "Запускаю backend через pm2..."

# Создаём директорию для логов
mkdir -p "$(dirname "$SYNO_APP_PATH")/logs" 2>/dev/null || true

$PM2_CMD start dist/index.js \
    --name "$PM2_APP_NAME" \
    --node-args="--max-old-space-size=2048" \
    --log-date-format="YYYY-MM-DD HH:mm:ss Z" \
    --merge-logs \
    --log "$(dirname "$SYNO_APP_PATH")/logs/backend.log" \
    || error "Не удалось запустить backend"

success "Backend запущен через pm2"

# Сохранение конфигурации pm2
$PM2_CMD save || info "Не удалось сохранить конфигурацию pm2"

# 11. Проверка health endpoint
section "Проверка работоспособности"

info "Жду запуска backend (5 секунд)..."
sleep 5

# Проверка локального health endpoint
info "Проверяю локальный health endpoint..."
LOCAL_HEALTH_URL="http://127.0.0.1:$BACKEND_PORT/health"

if curl -f -s "$LOCAL_HEALTH_URL" > /dev/null 2>&1; then
    success "✅ Backend запущен локально и отвечает на $LOCAL_HEALTH_URL"
    
    # Проверка публичного health endpoint (если BACKEND_URL настроен)
    if [ -n "$BACKEND_URL" ] && [ "$BACKEND_URL" != "http://localhost:$BACKEND_PORT" ]; then
        info "Проверяю публичный health endpoint..."
        PUBLIC_HEALTH_URL="$BACKEND_URL/health"
        
        if curl -f -s -m 10 "$PUBLIC_HEALTH_URL" > /dev/null 2>&1; then
            success "✅ Backend успешно задеплоен и доступен публично: $PUBLIC_HEALTH_URL"
        else
            info "⚠️  Backend не отвечает на публичный URL: $PUBLIC_HEALTH_URL"
            info "   Это может быть нормально, если проброс портов ещё не настроен на VPS"
            info "   Проверьте настройку iptables на VPS и убедитесь, что порт $VPS_PUBLIC_PORT проброшен"
        fi
    else
        info "⚠️  BACKEND_URL не настроен или указывает на localhost"
        info "   Настройте BACKEND_URL в .env для публичного доступа"
    fi
else
    info "⚠️  Backend не отвечает локально на $LOCAL_HEALTH_URL"
    info "Проверьте логи: $PM2_CMD logs $PM2_APP_NAME"
    info "Или: tail -f $(dirname "$SYNO_APP_PATH")/logs/backend.log"
fi

# 12. Статус pm2
section "Статус pm2"

$PM2_CMD status

section "Деплой завершён!"

info "Информация о деплое:"
echo -e "${GREEN}  Приложение:${NC} $SYNO_BACKEND_PATH"
echo -e "${GREEN}  Публичный URL:${NC} $BACKEND_URL"
echo -e "${GREEN}  Локальный URL:${NC} http://127.0.0.1:$BACKEND_PORT"
echo -e "${GREEN}  Логи:${NC} $(dirname "$SYNO_APP_PATH")/logs/backend.log"
echo ""
info "Полезные команды:"
echo -e "${GREEN}  Просмотр логов:${NC} $PM2_CMD logs $PM2_APP_NAME"
echo -e "${GREEN}  Статус:${NC} $PM2_CMD status"
echo -e "${GREEN}  Перезапуск:${NC} $PM2_CMD restart $PM2_APP_NAME"
echo -e "${GREEN}  Остановка:${NC} $PM2_CMD stop $PM2_APP_NAME"
echo ""

success "Готово!"

