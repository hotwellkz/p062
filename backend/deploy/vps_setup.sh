#!/bin/bash

# ============================================
# Скрипт настройки VPS (один раз)
# ============================================
# Устанавливает необходимые пакеты и настраивает проброс портов
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

# Проверка прав root
if [ "$EUID" -ne 0 ]; then
    error "Этот скрипт должен быть запущен с правами root (sudo)"
fi

section "Настройка VPS для ShortsAI Studio"

# 1. Обновление пакетов
info "Обновляю список пакетов..."
apt-get update -qq || error "Не удалось обновить список пакетов"
success "Список пакетов обновлён"

info "Обновляю установленные пакеты..."
apt-get upgrade -y -qq || error "Не удалось обновить пакеты"
success "Пакеты обновлены"

# 2. Установка необходимых утилит
section "Установка необходимых утилит"

PACKAGES=(
    "git"
    "curl"
    "bash"
    "openssh-client"
    "openssh-server"
    "rsync"
    "nano"
    "iptables"
    "netfilter-persistent"
    "iptables-persistent"
    "openvpn"
    "iptables-persistent"
)

for package in "${PACKAGES[@]}"; do
    if dpkg -l | grep -q "^ii  $package "; then
        info "  $package уже установлен"
    else
        info "  Устанавливаю $package..."
        apt-get install -y -qq "$package" || error "Не удалось установить $package"
        success "  $package установлен"
    fi
done

# 3. Копирование скрипта проброса портов
section "Настройка проброса портов"

VPS_SCRIPT_DIR="/usr/local/bin"
PORT_FORWARD_SCRIPT="$VPS_SCRIPT_DIR/synology-port-forward.sh"

# Проверяем, есть ли скрипт в репозитории
REPO_SCRIPT="$SCRIPT_DIR/../vps/synology-port-forward.sh"
if [ -f "$REPO_SCRIPT" ]; then
    info "Копирую скрипт проброса портов..."
    cp "$REPO_SCRIPT" "$PORT_FORWARD_SCRIPT"
    # Исправляем окончания строк (CRLF -> LF) на случай, если файл был скопирован из Windows
    sed -i 's/\r$//' "$PORT_FORWARD_SCRIPT"
    chmod +x "$PORT_FORWARD_SCRIPT"
    success "Скрипт скопирован в $PORT_FORWARD_SCRIPT (окончания строк исправлены)"
else
    info "Скрипт synology-port-forward.sh не найден в репозитории"
    info "Создаю базовый скрипт..."
    
    cat > "$PORT_FORWARD_SCRIPT" << 'EOFSCRIPT'
#!/bin/bash
# Базовый скрипт проброса портов
# Замените на актуальный скрипт из репозитория
echo "Скрипт проброса портов должен быть настроен вручную"
EOFSCRIPT
    chmod +x "$PORT_FORWARD_SCRIPT"
    info "Создан базовый скрипт. Замените его на актуальный из репозитория"
fi

# 4. Настройка автозапуска проброса портов
info "Настраиваю автозапуск проброса портов..."

cat > /etc/systemd/system/synology-port-forward.service << EOF
[Unit]
Description=Synology Port Forwarding
After=network.target

[Service]
Type=oneshot
ExecStart=$PORT_FORWARD_SCRIPT
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable synology-port-forward.service || info "Сервис уже включен"
success "Автозапуск настроен"

# 5. Запуск скрипта проброса портов (если он существует и исполняемый)
if [ -f "$PORT_FORWARD_SCRIPT" ] && [ -x "$PORT_FORWARD_SCRIPT" ]; then
    info "Запускаю скрипт проброса портов..."
    "$PORT_FORWARD_SCRIPT" || info "Скрипт проброса портов завершился с ошибкой (возможно, требует настройки)"
fi

# 6. Проверка SSH доступа к Synology
section "Проверка SSH доступа к Synology"

info "Проверяю доступность Synology..."
if timeout 5 bash -c "echo > /dev/tcp/$SYNO_HOST/$SYNO_SSH_PORT" 2>/dev/null; then
    success "Synology доступен по адресу $SYNO_HOST:$SYNO_SSH_PORT"
elif [ -n "${SYNO_HOST_VPN:-}" ]; then
    info "Проверяю доступность Synology через VPN..."
    if timeout 5 bash -c "echo > /dev/tcp/$SYNO_HOST_VPN/$SYNO_SSH_PORT" 2>/dev/null; then
        success "Synology доступен через VPN: $SYNO_HOST_VPN:$SYNO_SSH_PORT"
    else
        info "⚠️  Synology недоступен ни напрямую, ни через VPN"
        info "   Убедитесь, что VPN туннель активен или используйте локальный IP: $SYNO_LOCAL_IP"
    fi
else
    info "⚠️  Synology недоступен по адресу $SYNO_HOST:$SYNO_SSH_PORT"
    info "   Убедитесь, что вы в той же сети или используйте VPN туннель"
fi

section "Настройка VPS завершена!"

info "Следующие шаги:"
echo -e "${GREEN}  1. Проверьте проброс портов:${NC}"
echo -e "     curl -I http://$VPS_PUBLIC_IP:$VPS_PUBLIC_PORT/health"
echo ""
echo -e "${GREEN}  2. Запустите полный деплой:${NC}"
echo -e "     ./deploy/full_deploy.sh"
echo ""

success "VPS готов к работе!"

