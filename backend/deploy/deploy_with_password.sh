#!/bin/bash

# ============================================
# Деплой с интерактивным вводом пароля
# ============================================
# Использование: bash deploy/deploy_with_password.sh
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

# Если скрипт запущен на Synology, используем текущую директорию
if [ -f "/etc/synoinfo.conf" ] || [ -d "/volume1" ]; then
    # Определяем текущую директорию backend на Synology
    CURRENT_DIR="$(pwd)"
    if [[ "$CURRENT_DIR" == *"shortsai-backend"* ]] || [[ "$CURRENT_DIR" == *"backend"* ]]; then
        if [[ "$CURRENT_DIR" == *"deploy"* ]]; then
            SYNO_BACKEND_DIR="$(dirname "$CURRENT_DIR")"
        else
            SYNO_BACKEND_DIR="$CURRENT_DIR"
        fi
    fi
    info "⚠️  Скрипт запущен на Synology, используем текущую директорию: $SYNO_BACKEND_DIR"
    info "⚠️  Для копирования кода с локального компьютера запустите скрипт с локальной машины!"
    exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$BACKEND_DIR" || error "Не удалось перейти в директорию backend"

section "Деплой ShortsAI Backend на Synology (с паролем)"

info "Подключение к Synology: $SYNO_USER@$SYNO_HOST"
info "⚠️  Будет запрошен пароль для SSH"
echo ""

# Проверка/создание директории
info "Проверяю директорию на Synology..."
ssh "$SYNO_USER@$SYNO_HOST" "mkdir -p $SYNO_BACKEND_DIR && ls -la $SYNO_BACKEND_DIR" || error "Не удалось создать/проверить директорию"
success "Директория готова"

# Копирование файлов
section "Копирование файлов на Synology"

# Создаём архив
info "Создаю архив..."
TEMP_TAR="/tmp/shortsai_backend_$(date +%s).tar.gz"

if command -v tar &> /dev/null; then
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
    success "Файлы скопированы на Synology"
else
    error "tar не найден. Установите tar или используйте другой метод."
fi

section "Деплой завершён!"

success "Код успешно скопирован на Synology: $SYNO_BACKEND_DIR"
echo ""
info "Следующие шаги на Synology:"
echo "  1. Подключитесь: ssh $SYNO_USER@$SYNO_HOST"
echo "  2. Перейдите: cd $SYNO_BACKEND_DIR"
echo "  3. Установите зависимости: npm install"
echo "  4. Соберите проект: npm run build"
echo "  5. Запустите: bash deploy/setup_on_synology.sh"
echo ""

