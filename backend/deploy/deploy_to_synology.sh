#!/bin/bash

# ============================================
# Скрипт деплоя backend на Synology
# ============================================
# Использование: bash deploy/deploy_to_synology.sh
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

# Переменные
SYNO_HOST="${SYNO_HOST:-192.168.100.222}"
SYNO_USER="${SYNO_USER:-admin}"
SYNO_BACKEND_DIR="${SYNO_BACKEND_DIR:-/volume1/Backends/shortsai-backend}"
SYNO_SSH_KEY="${SYNO_SSH_KEY:-$HOME/.ssh/shortsai_synology}"

# Определяем SSH команду
SSH_CMD="ssh"
SCP_CMD="scp"
if [ -f "$SYNO_SSH_KEY" ]; then
    SSH_CMD="ssh -i $SYNO_SSH_KEY"
    SCP_CMD="scp -i $SYNO_SSH_KEY"
    info "Использую SSH-ключ: $SYNO_SSH_KEY"
fi
SYNO_SSH_KEY="${SYNO_SSH_KEY:-$HOME/.ssh/shortsai_synology}"

# Определяем директорию backend (откуда запускается скрипт)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$BACKEND_DIR" || error "Не удалось перейти в директорию backend"

section "Деплой ShortsAI Backend на Synology"

# Проверка SSH подключения
info "Проверяю SSH подключение..."
SSH_CMD="ssh"
if [ -f "$SYNO_SSH_KEY" ]; then
    SSH_CMD="ssh -i $SYNO_SSH_KEY"
    info "Использую SSH-ключ: $SYNO_SSH_KEY"
fi

if $SSH_CMD -o ConnectTimeout=5 -o BatchMode=yes "$SYNO_USER@$SYNO_HOST" "echo 'SSH OK'" > /dev/null 2>&1; then
    success "SSH подключение работает без пароля"
else
    info "⚠️  SSH подключение требует пароль (будет запрошен при необходимости)"
fi

# Проверка/создание директории на Synology
info "Проверяю директорию на Synology: $SYNO_BACKEND_DIR"
$SSH_CMD "$SYNO_USER@$SYNO_HOST" "mkdir -p $SYNO_BACKEND_DIR && ls -la $SYNO_BACKEND_DIR" || error "Не удалось создать/проверить директорию"
success "Директория готова"

# Копирование файлов через rsync (если доступен) или scp
section "Копирование файлов на Synology"

if command -v rsync &> /dev/null; then
    info "Использую rsync для копирования файлов..."
    if [ -f "$SYNO_SSH_KEY" ]; then
        rsync -avz --delete -e "$SSH_CMD" \
        --exclude=".git" \
        --exclude="node_modules" \
        --exclude="tmp" \
        --exclude="storage/videos" \
        --exclude=".env" \
        --exclude=".env.local" \
        --exclude=".env.production" \
        --exclude="dist" \
        --exclude="*.log" \
        --exclude=".DS_Store" \
        "$BACKEND_DIR/" "$SYNO_USER@$SYNO_HOST:$SYNO_BACKEND_DIR/" || error "Не удалось скопировать файлы через rsync"
    else
        rsync -avz --delete \
        --exclude=".git" \
        --exclude="node_modules" \
        --exclude="tmp" \
        --exclude="storage/videos" \
        --exclude=".env" \
        --exclude=".env.local" \
        --exclude=".env.production" \
        --exclude="dist" \
        --exclude="*.log" \
        --exclude=".DS_Store" \
        "$BACKEND_DIR/" "$SYNO_USER@$SYNO_HOST:$SYNO_BACKEND_DIR/" || error "Не удалось скопировать файлы через rsync"
    fi
    success "Файлы скопированы через rsync"
else
    info "rsync не найден, использую scp..."
    # Создаём временный архив
    TEMP_TAR="/tmp/shortsai_backend_$$.tar.gz"
    info "Создаю архив..."
    tar -czf "$TEMP_TAR" \
        --exclude=".git" \
        --exclude="node_modules" \
        --exclude="tmp" \
        --exclude="storage/videos" \
        --exclude=".env" \
        --exclude=".env.local" \
        --exclude=".env.production" \
        --exclude="dist" \
        --exclude="*.log" \
        . || error "Не удалось создать архив"
    
    info "Копирую архив на Synology..."
    $SCP_CMD "$TEMP_TAR" "$SYNO_USER@$SYNO_HOST:/tmp/shortsai_backend.tar.gz" || error "Не удалось скопировать архив"
    
    info "Распаковываю архив на Synology..."
    $SSH_CMD "$SYNO_USER@$SYNO_HOST" "cd $SYNO_BACKEND_DIR && tar -xzf /tmp/shortsai_backend.tar.gz && rm /tmp/shortsai_backend.tar.gz" || error "Не удалось распаковать архив"
    
    rm -f "$TEMP_TAR"
    success "Файлы скопированы через scp"
fi

section "Деплой завершён"

success "Код обновлён на Synology: $SYNO_BACKEND_DIR"
info "Следующие шаги:"
echo -e "  ${GREEN}1. Подключитесь к Synology:${NC} ssh $SYNO_USER@$SYNO_HOST"
echo -e "  ${GREEN}2. Перейдите в директорию:${NC} cd $SYNO_BACKEND_DIR"
echo -e "  ${GREEN}3. Установите зависимости:${NC} npm install"
echo -e "  ${GREEN}4. Соберите проект:${NC} npm run build"
echo -e "  ${GREEN}5. Настройте .env файл"
echo -e "  ${GREEN}6. Запустите через PM2:${NC} pm2 start dist/index.js --name shortsai-backend"
echo ""

