#!/bin/bash

# ============================================
# Полный деплой backend на Synology
# ============================================
# Выполняет все шаги: деплой кода, установку зависимостей, сборку, запуск PM2
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
        SYNO_BACKEND_DIR="$(dirname "$CURRENT_DIR" 2>/dev/null || echo "$CURRENT_DIR")"
        if [[ "$SYNO_BACKEND_DIR" == *"deploy"* ]]; then
            SYNO_BACKEND_DIR="$(dirname "$SYNO_BACKEND_DIR")"
        fi
    fi
fi
SYNO_SSH_KEY="${SYNO_SSH_KEY:-$HOME/.ssh/shortsai_synology}"

# Определяем SSH команду
SSH_CMD="ssh"
if [ -f "$SYNO_SSH_KEY" ]; then
    SSH_CMD="ssh -i $SYNO_SSH_KEY"
    info "Использую SSH-ключ: $SYNO_SSH_KEY"
    # Проверяем, работает ли ключ
    if $SSH_CMD -o ConnectTimeout=5 -o BatchMode=yes "$SYNO_USER@$SYNO_HOST" "echo 'SSH key works'" > /dev/null 2>&1; then
        success "SSH-ключ работает без пароля"
    else
        info "⚠️  SSH-ключ не работает, будет запрошен пароль"
        SSH_CMD="ssh"  # Используем обычный SSH с паролем
    fi
else
    info "SSH-ключ не найден, будет использован пароль"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$BACKEND_DIR" || error "Не удалось перейти в директорию backend"

section "🚀 Полный деплой ShortsAI Backend на Synology"

# Шаг 1: Деплой кода (только если запущено с локального компьютера)
# Проверяем, запущен ли скрипт на Synology
if [ -f "/etc/synoinfo.conf" ] || [ -d "/volume1" ] && [ "$(hostname)" != "$SYNO_HOST" ]; then
    section "Шаг 1: Пропуск деплоя кода (скрипт запущен на Synology)"
    info "Код должен быть уже на Synology в $SYNO_BACKEND_DIR"
    info "Если нужно обновить код, запустите деплой с локального компьютера"
    info "Или используйте: bash deploy/setup_on_synology.sh"
else
    section "Шаг 1: Деплой кода на Synology"
    if [ -f "$SCRIPT_DIR/deploy_to_synology.sh" ]; then
        bash "$SCRIPT_DIR/deploy_to_synology.sh" || error "Деплой кода не удался"
    else
        error "Скрипт deploy_to_synology.sh не найден. Запустите деплой с локального компьютера."
    fi
fi

# Шаг 2: Проверка Node.js и PM2
section "Шаг 2: Проверка Node.js и PM2 на Synology"
info "Проверяю Node.js..."
NODE_VERSION=$($SSH_CMD "$SYNO_USER@$SYNO_HOST" "node -v 2>/dev/null || echo 'NO_NODE'")
if [ "$NODE_VERSION" = "NO_NODE" ]; then
    error "Node.js не установлен на Synology. Установите через Package Center."
else
    success "Node.js: $NODE_VERSION"
fi

info "Проверяю npm..."
NPM_VERSION=$($SSH_CMD "$SYNO_USER@$SYNO_HOST" "npm -v 2>/dev/null || echo 'NO_NPM'")
if [ "$NPM_VERSION" = "NO_NPM" ]; then
    error "npm не установлен на Synology."
else
    success "npm: $NPM_VERSION"
fi

info "Проверяю pm2..."
PM2_VERSION=$($SSH_CMD "$SYNO_USER@$SYNO_HOST" "pm2 -v 2>/dev/null || echo 'NO_PM2'")
if [ "$PM2_VERSION" = "NO_PM2" ]; then
    info "pm2 не установлен, устанавливаю..."
    $SSH_CMD "$SYNO_USER@$SYNO_HOST" "cd $SYNO_BACKEND_DIR && npm install -g pm2 || npm install pm2" || error "Не удалось установить pm2"
    success "pm2 установлен"
else
    success "pm2: $PM2_VERSION"
fi

# Шаг 3: Настройка .env
section "Шаг 3: Настройка .env"
info "Проверяю .env на Synology..."
ENV_EXISTS=$($SSH_CMD "$SYNO_USER@$SYNO_HOST" "test -f $SYNO_BACKEND_DIR/.env && echo 'YES' || echo 'NO'")

if [ "$ENV_EXISTS" = "NO" ]; then
    info ".env не найден, создаю из env.example..."
    $SSH_CMD "$SYNO_USER@$SYNO_HOST" "cd $SYNO_BACKEND_DIR && cp env.example .env" || error "Не удалось создать .env"
    info "⚠️  ВАЖНО: Настройте .env на Synology вручную!"
    info "   Выполните: ssh $SYNO_USER@$SYNO_HOST"
    info "   Затем: nano $SYNO_BACKEND_DIR/.env"
else
    success ".env уже существует"
fi

# Шаг 4: Установка зависимостей и сборка
section "Шаг 4: Установка зависимостей и сборка"
info "Устанавливаю зависимости..."
$SSH_CMD "$SYNO_USER@$SYNO_HOST" "cd $SYNO_BACKEND_DIR && rm -rf node_modules && npm install" || error "Не удалось установить зависимости"
success "Зависимости установлены"

info "Собираю проект..."
$SSH_CMD "$SYNO_USER@$SYNO_HOST" "cd $SYNO_BACKEND_DIR && npm run build" || error "Не удалось собрать проект"
success "Проект собран"

# Шаг 5: Запуск через PM2
section "Шаг 5: Запуск через PM2"
info "Останавливаю старый процесс (если есть)..."
$SSH_CMD "$SYNO_USER@$SYNO_HOST" "cd $SYNO_BACKEND_DIR && pm2 stop shortsai-backend 2>/dev/null || true"
$SSH_CMD "$SYNO_USER@$SYNO_HOST" "cd $SYNO_BACKEND_DIR && pm2 delete shortsai-backend 2>/dev/null || true"

info "Запускаю backend через PM2..."
$SSH_CMD "$SYNO_USER@$SYNO_HOST" "cd $SYNO_BACKEND_DIR && pm2 start dist/index.js --name shortsai-backend" || error "Не удалось запустить backend"

info "Настраиваю автозапуск..."
$SSH_CMD "$SYNO_USER@$SYNO_HOST" "cd $SYNO_BACKEND_DIR && pm2 save" || error "Не удалось сохранить конфигурацию PM2"

info "Проверяю статус..."
$SSH_CMD "$SYNO_USER@$SYNO_HOST" "pm2 status"
success "Backend запущен через PM2"

# Шаг 6: Проверка работы
section "Шаг 6: Проверка работы backend"
info "Определяю порт из .env..."
PORT=$($SSH_CMD "$SYNO_USER@$SYNO_HOST" "grep -E '^PORT=' $SYNO_BACKEND_DIR/.env | cut -d'=' -f2 | tr -d '\"'" || echo "8080")
if [ -z "$PORT" ]; then
    PORT="8080"
fi
info "Порт backend: $PORT"

info "Проверяю health endpoint..."
HEALTH_RESPONSE=$($SSH_CMD "$SYNO_USER@$SYNO_HOST" "curl -s http://localhost:$PORT/health || curl -s http://localhost:$PORT/ || echo 'ERROR'")
if [ "$HEALTH_RESPONSE" != "ERROR" ] && [ -n "$HEALTH_RESPONSE" ]; then
    success "Backend отвечает!"
    echo "Ответ: $HEALTH_RESPONSE"
else
    info "⚠️  Backend не отвечает на health endpoint"
    info "Проверьте логи: pm2 logs shortsai-backend"
fi

section "🎉 Деплой завершён!"

success "Backend успешно задеплоен на Synology!"
echo ""
info "Полезные команды:"
echo -e "  ${GREEN}Обновить код:${NC} bash deploy/deploy_to_synology.sh"
echo -e "  ${GREEN}Перезапустить backend:${NC} ssh $SYNO_USER@$SYNO_HOST 'pm2 restart shortsai-backend'"
echo -e "  ${GREEN}Просмотр логов:${NC} ssh $SYNO_USER@$SYNO_HOST 'pm2 logs shortsai-backend'"
echo -e "  ${GREEN}Статус:${NC} ssh $SYNO_USER@$SYNO_HOST 'pm2 status'"
echo -e "  ${GREEN}Проверка health:${NC} ssh $SYNO_USER@$SYNO_HOST 'curl http://localhost:$PORT/health'"
echo ""

