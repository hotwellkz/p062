#!/bin/bash

# ============================================
# Настройка sudo без пароля для Synology
# ============================================
# ВНИМАНИЕ: Делайте это осторожно!
# Разрешаем только конкретные команды, не полный NOPASSWD: ALL
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

# Определяем SSH host
if [ -n "${SYNO_SSH_HOST:-}" ] && [ "$SYNO_SSH_HOST" != "${SYNO_USER}@${SYNO_HOST}" ]; then
    SSH_TARGET="$SYNO_SSH_HOST"
else
    SSH_TARGET="${SYNO_USER}@${SYNO_HOST}"
fi

section "Настройка sudo без пароля на Synology"

info "⚠️  ВНИМАНИЕ: Этот скрипт настроит sudo без пароля для конкретных команд"
info "Разрешаются только: npm, node, pm2"
echo ""
read -p "Продолжить? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    info "Отменено"
    exit 0
fi

# Команды, которые разрешаем без пароля
SUDO_COMMANDS=(
    "/usr/bin/npm"
    "/usr/bin/node"
    "/usr/bin/pm2"
    "/volume1/@appstore/Node.js_v20/usr/local/bin/npm"
    "/volume1/@appstore/Node.js_v20/usr/local/bin/node"
    "/volume1/@appstore/Node.js_v20/usr/local/bin/pm2"
    "/usr/local/bin/npm"
    "/usr/local/bin/node"
    "/usr/local/bin/pm2"
)

# Формируем строку для sudoers
SUDOERS_LINE="$SYNO_USER ALL=(ALL) NOPASSWD:"
for cmd in "${SUDO_COMMANDS[@]}"; do
    SUDOERS_LINE="$SUDOERS_LINE $cmd,"
done
# Убираем последнюю запятую
SUDOERS_LINE="${SUDOERS_LINE%,}"

info "Создаю файл /etc/sudoers.d/shortsai на Synology..."
info "Содержимое: $SUDOERS_LINE"

# Создаём файл на Synology
ssh "$SSH_TARGET" "echo '$SUDOERS_LINE' | sudo tee /etc/sudoers.d/shortsai > /dev/null" || error "Не удалось создать sudoers файл"

# Проверяем синтаксис
info "Проверяю синтаксис sudoers..."
if ssh "$SSH_TARGET" "sudo visudo -c" 2>&1 | grep -q "syntax OK"; then
    success "Синтаксис sudoers корректен"
else
    error "Ошибка синтаксиса sudoers! Файл будет удалён."
    ssh "$SSH_TARGET" "sudo rm -f /etc/sudoers.d/shortsai"
    exit 1
fi

# Устанавливаем правильные права
ssh "$SSH_TARGET" "sudo chmod 440 /etc/sudoers.d/shortsai" || error "Не удалось установить права"

success "sudo настроен без пароля для команд npm, node, pm2"

# Проверка
section "Проверка"

info "Проверяю работу sudo без пароля..."
if ssh "$SSH_TARGET" "sudo -n npm --version" > /dev/null 2>&1; then
    success "sudo работает без пароля для npm!"
else
    info "⚠️  sudo для npm может требовать пароль (возможно, путь к npm отличается)"
fi

section "Готово!"

success "Настройка завершена"
info "Теперь в deploy-скриптах можно использовать:"
echo -e "  ${GREEN}ssh $SSH_TARGET 'cd /volume1/shortsai/app/backend && sudo pm2 restart shortsai-backend'${NC}"
echo ""

