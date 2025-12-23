#!/bin/bash

# ============================================
# Настройка SSH-ключей для доступа к Synology
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
LOCAL_KEY_NAME="shortsai_synology"
LOCAL_KEY_PATH="$HOME/.ssh/$LOCAL_KEY_NAME"

# Определяем домашнюю директорию (для Windows Git Bash)
if [ -n "$USERPROFILE" ]; then
    # Windows Git Bash
    HOME_DIR="$USERPROFILE"
    SSH_DIR="$HOME_DIR/.ssh"
else
    # Linux/Mac
    HOME_DIR="$HOME"
    SSH_DIR="$HOME/.ssh"
fi

LOCAL_KEY_PATH="$SSH_DIR/$LOCAL_KEY_NAME"

section "Настройка SSH-ключей для Synology"

# 1. Создание директории .ssh
info "Проверяю директорию .ssh..."
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR" 2>/dev/null || true
success "Директория .ssh готова"

# 2. Проверка существующего ключа
info "Проверяю существующие ключи..."
if [ -f "$LOCAL_KEY_PATH" ]; then
    info "Ключ $LOCAL_KEY_NAME уже существует"
    read -p "Пересоздать ключ? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -f "$LOCAL_KEY_PATH" "$LOCAL_KEY_PATH.pub"
        info "Старый ключ удалён"
    else
        success "Используем существующий ключ"
        KEY_EXISTS=true
    fi
else
    KEY_EXISTS=false
fi

# 3. Создание нового ключа
if [ "$KEY_EXISTS" != "true" ]; then
    info "Создаю новый SSH-ключ: $LOCAL_KEY_NAME"
    ssh-keygen -t ed25519 -f "$LOCAL_KEY_PATH" -C "synology-access" -N "" || error "Не удалось создать ключ"
    success "SSH-ключ создан: $LOCAL_KEY_PATH"
fi

# 4. Проверка наличия файлов
if [ ! -f "$LOCAL_KEY_PATH" ] || [ ! -f "$LOCAL_KEY_PATH.pub" ]; then
    error "Файлы ключа не найдены"
fi

info "Публичный ключ: $LOCAL_KEY_PATH.pub"
success "Ключи готовы"

# 5. Копирование публичного ключа на Synology
section "Копирование ключа на Synology"

info "Скопирую публичный ключ на Synology ($SYNO_USER@$SYNO_HOST)"
info "Вам нужно будет ввести пароль один раз"

# Попытка использовать ssh-copy-id
if command -v ssh-copy-id &> /dev/null; then
    info "Использую ssh-copy-id..."
    ssh-copy-id -i "$LOCAL_KEY_PATH.pub" "$SYNO_USER@$SYNO_HOST" || {
        info "ssh-copy-id не сработал, копирую вручную..."
        PUBKEY_CONTENT=$(cat "$LOCAL_KEY_PATH.pub")
        ssh "$SYNO_USER@$SYNO_HOST" "mkdir -p ~/.ssh && chmod 700 ~/.ssh && echo '$PUBKEY_CONTENT' >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys" || error "Не удалось скопировать ключ"
    }
else
    # Ручное копирование
    info "Копирую ключ вручную..."
    PUBKEY_CONTENT=$(cat "$LOCAL_KEY_PATH.pub")
    ssh "$SYNO_USER@$SYNO_HOST" "mkdir -p ~/.ssh && chmod 700 ~/.ssh && echo '$PUBKEY_CONTENT' >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys" || error "Не удалось скопировать ключ"
fi

success "Публичный ключ скопирован на Synology"

# 6. Проверка подключения
section "Проверка подключения"

info "Проверяю подключение без пароля..."
if ssh -i "$LOCAL_KEY_PATH" -o ConnectTimeout=5 -o BatchMode=yes "$SYNO_USER@$SYNO_HOST" 'echo "SSH key login OK"; whoami; pwd' 2>/dev/null; then
    success "Подключение по SSH-ключу работает!"
else
    error "Подключение по SSH-ключу не работает. Проверьте настройки на Synology."
fi

# 7. Настройка ~/.ssh/config
section "Настройка SSH config"

SSH_CONFIG="$SSH_DIR/config"
info "Обновляю $SSH_CONFIG..."

# Создаём конфиг если его нет
if [ ! -f "$SSH_CONFIG" ]; then
    touch "$SSH_CONFIG"
    chmod 600 "$SSH_CONFIG"
fi

# Проверяем, есть ли уже запись для synology-shortsai
if grep -q "^Host synology-shortsai" "$SSH_CONFIG" 2>/dev/null; then
    info "Запись для synology-shortsai уже существует в config"
    read -p "Обновить? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Удаляем старую запись
        sed -i.bak '/^Host synology-shortsai/,/^$/d' "$SSH_CONFIG" 2>/dev/null || \
        sed -i '/^Host synology-shortsai/,/^$/d' "$SSH_CONFIG" 2>/dev/null || true
    else
        info "Пропускаю обновление SSH config"
        SSH_CONFIG_UPDATED=false
    fi
fi

if [ "${SSH_CONFIG_UPDATED:-true}" != "false" ]; then
    # Добавляем новую запись
    {
        echo ""
        echo "Host synology-shortsai"
        echo "    HostName $SYNO_HOST"
        echo "    User $SYNO_USER"
        echo "    IdentityFile $LOCAL_KEY_PATH"
        echo "    IdentitiesOnly yes"
        echo "    StrictHostKeyChecking accept-new"
    } >> "$SSH_CONFIG"
    
    chmod 600 "$SSH_CONFIG"
    success "SSH config обновлён"
    
    # Проверка через config
    info "Проверяю подключение через SSH config..."
    if ssh -o ConnectTimeout=5 -o BatchMode=yes synology-shortsai 'echo "config OK"; pwd' 2>/dev/null; then
        success "Подключение через SSH config работает!"
    else
        info "⚠️  Подключение через config требует первого ручного подключения"
    fi
fi

section "Готово!"

success "SSH-ключи настроены успешно!"
echo ""
info "Теперь вы можете подключаться к Synology без пароля:"
echo -e "  ${GREEN}ssh synology-shortsai${NC}"
echo -e "  ${GREEN}ssh -i $LOCAL_KEY_PATH $SYNO_USER@$SYNO_HOST${NC}"
echo ""
info "Следующий шаг: обновите deploy-скрипты для использования ключа"




