#!/bin/bash

# ============================================
# Копирование кода на Synology
# ============================================
# ЗАПУСКАЙТЕ С ЛОКАЛЬНОГО КОМПЬЮТЕРА!
# Использование: bash deploy/COPY_CODE_TO_SYNOLOGY.sh
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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$BACKEND_DIR" || error "Не удалось перейти в директорию backend"

# Проверка, что скрипт запущен не на Synology
if [ -f "/etc/synoinfo.conf" ] || ([ -d "/volume1" ] && [ "$(hostname)" != "$SYNO_HOST" ]); then
    error "Этот скрипт должен запускаться с ЛОКАЛЬНОГО компьютера, а не на Synology!"
    error "Для установки на Synology используйте: bash deploy/setup_on_synology.sh"
fi

section "Копирование кода на Synology"

info "Подключение к Synology: $SYNO_USER@$SYNO_HOST"
info "Директория на Synology: $SYNO_BACKEND_DIR"
info "⚠️  Будет запрошен пароль для SSH"
echo ""

# Проверка/создание директории
info "Проверяю директорию на Synology..."
ssh "$SYNO_USER@$SYNO_HOST" "mkdir -p $SYNO_BACKEND_DIR && ls -la $SYNO_BACKEND_DIR" || error "Не удалось создать/проверить директорию"
success "Директория готова"

# Копирование файлов
section "Копирование файлов на Synology"

# Используем rsync если доступен
if command -v rsync &> /dev/null; then
    info "Использую rsync для копирования файлов..."
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
        ./ "$SYNO_USER@$SYNO_HOST:$SYNO_BACKEND_DIR/" || error "Не удалось скопировать файлы через rsync"
    success "Файлы скопированы через rsync"
else
    # Используем tar + scp
    info "Использую tar + scp для копирования файлов..."
    TEMP_TAR="/tmp/shortsai_backend_$(date +%s).tar.gz"
    
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
        --exclude=".DS_Store" \
        . || error "Не удалось создать архив"
    
    info "Копирую архив на Synology..."
    scp "$TEMP_TAR" "$SYNO_USER@$SYNO_HOST:/tmp/shortsai_backend.tar.gz" || error "Не удалось скопировать архив"
    
    info "Распаковываю архив на Synology..."
    ssh "$SYNO_USER@$SYNO_HOST" "cd $SYNO_BACKEND_DIR && tar -xzf /tmp/shortsai_backend.tar.gz && rm /tmp/shortsai_backend.tar.gz" || error "Не удалось распаковать архив"
    
    rm -f "$TEMP_TAR"
    success "Файлы скопированы через tar + scp"
fi

section "Деплой завершён!"

success "Код успешно скопирован на Synology: $SYNO_BACKEND_DIR"
echo ""
info "Следующие шаги на Synology:"
echo "  1. Подключитесь: ssh $SYNO_USER@$SYNO_HOST"
echo "  2. Перейдите: cd $SYNO_BACKEND_DIR"
echo "  3. Запустите установку: bash deploy/setup_on_synology.sh"
echo ""




