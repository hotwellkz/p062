#!/bin/bash

# ============================================
# Полный автодеплой ShortsAI Studio
# ============================================
# Одна команда для деплоя на VPS + Synology
# ============================================

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Определяем директорию скрипта
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

# Загрузка конфигурации
if [ ! -f "config.sh" ]; then
    echo -e "${RED}❌ Ошибка: config.sh не найден${NC}"
    echo "Создайте config.sh на основе config.sh.example"
    exit 1
fi

source "config.sh"

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

# Проверка SSH доступа
check_ssh() {
    local host=$1
    local user=$2
    local port=${3:-22}
    
    info "Проверяю SSH доступ к $user@$host:$port..."
    
    if timeout 5 bash -c "echo > /dev/tcp/$host/$port" 2>/dev/null; then
        success "SSH доступен: $user@$host:$port"
        return 0
    else
        error "SSH недоступен: $user@$host:$port"
        return 1
    fi
}

# Копирование файлов на удалённый хост
copy_to_remote() {
    local host=$1
    local user=$2
    local local_path=$3
    local remote_path=$4
    
    info "Копирую $local_path на $user@$host:$remote_path..."
    
    if [ -n "${SYNO_SSH_KEY_PATH:-}" ]; then
        scp -i "$SYNO_SSH_KEY_PATH" -P "${SYNO_SSH_PORT:-22}" "$local_path" "$user@$host:$remote_path" || error "Не удалось скопировать файл"
    else
        scp -P "${SYNO_SSH_PORT:-22}" "$local_path" "$user@$host:$remote_path" || error "Не удалось скопировать файл"
    fi
    
    success "Файл скопирован"
}

# Выполнение команды на удалённом хосте
run_remote() {
    local host=$1
    local user=$2
    local command=$3
    local port=${4:-22}
    
    if [ -n "${SYNO_SSH_KEY_PATH:-}" ]; then
        ssh -i "$SYNO_SSH_KEY_PATH" -p "$port" "$user@$host" "$command"
    else
        ssh -p "$port" "$user@$host" "$command"
    fi
}

# Выполнение команды на Synology (напрямую или через VPS)
run_synology() {
    local command=$1
    
    # Проверяем, доступен ли Synology напрямую
    if timeout 3 bash -c "echo > /dev/tcp/$SYNO_HOST/$SYNO_SSH_PORT" 2>/dev/null; then
        # Прямое подключение
        info "Подключаюсь к Synology напрямую..."
        # Используем SSH config host если настроен, иначе ключ или обычное подключение
        if [ -n "${SYNO_SSH_HOST:-}" ] && [ "$SYNO_SSH_HOST" != "${SYNO_USER}@${SYNO_HOST}" ]; then
            # Используем SSH config host (synology-shortsai)
            ssh -o ConnectTimeout=10 "$SYNO_SSH_HOST" "$command"
        elif [ -n "${SYNO_SSH_KEY_PATH:-}" ]; then
            ssh -i "$SYNO_SSH_KEY_PATH" -p "${SYNO_SSH_PORT:-22}" "$SYNO_USER@$SYNO_HOST" "$command"
        else
            ssh -p "${SYNO_SSH_PORT:-22}" "$SYNO_USER@$SYNO_HOST" "$command"
        fi
    else
        # Через VPS (если используется VPN)
        info "Подключаюсь к Synology через VPS..."
        if [ -n "${VPS_SSH_KEY_PATH:-}" ]; then
            ssh -i "$VPS_SSH_KEY_PATH" -p "${VPS_SSH_PORT:-22}" "$VPS_USER@$VPS_IP" "ssh -o StrictHostKeyChecking=no -p ${SYNO_SSH_PORT:-22} $SYNO_USER@${SYNO_HOST_VPN:-$SYNO_HOST} '$command'"
        else
            ssh -p "${VPS_SSH_PORT:-22}" "$VPS_USER@$VPS_IP" "ssh -o StrictHostKeyChecking=no -p ${SYNO_SSH_PORT:-22} $SYNO_USER@${SYNO_HOST_VPN:-$SYNO_HOST} '$command'"
        fi
    fi
}

# Копирование файла на Synology (напрямую или через VPS)
copy_to_synology() {
    local local_path=$1
    local remote_path=$2
    
    # Проверяем, доступен ли Synology напрямую
    if timeout 3 bash -c "echo > /dev/tcp/$SYNO_HOST/$SYNO_SSH_PORT" 2>/dev/null; then
        # Прямое копирование
        info "Копирую файл на Synology напрямую..."
        # Используем SSH config host если настроен, иначе ключ или обычное копирование
        if [ -n "${SYNO_SSH_HOST:-}" ] && [ "$SYNO_SSH_HOST" != "${SYNO_USER}@${SYNO_HOST}" ]; then
            # Используем SSH config host (synology-shortsai)
            scp -o ConnectTimeout=10 "$local_path" "$SYNO_SSH_HOST:$remote_path"
        elif [ -n "${SYNO_SSH_KEY_PATH:-}" ]; then
            scp -i "$SYNO_SSH_KEY_PATH" -P "${SYNO_SSH_PORT:-22}" "$local_path" "$SYNO_USER@$SYNO_HOST:$remote_path"
        else
            scp -P "${SYNO_SSH_PORT:-22}" "$local_path" "$SYNO_USER@$SYNO_HOST:$remote_path"
        fi
    else
        # Через VPS
        info "Копирую файл на Synology через VPS..."
        TEMP_VPS="/tmp/shortsai_$(basename "$local_path")_$$"
        
        if [ -n "${VPS_SSH_KEY_PATH:-}" ]; then
            scp -i "$VPS_SSH_KEY_PATH" -P "${VPS_SSH_PORT:-22}" "$local_path" "$VPS_USER@$VPS_IP:$TEMP_VPS"
            ssh -i "$VPS_SSH_KEY_PATH" -p "${VPS_SSH_PORT:-22}" "$VPS_USER@$VPS_IP" "scp -o StrictHostKeyChecking=no -P ${SYNO_SSH_PORT:-22} $TEMP_VPS $SYNO_USER@${SYNO_HOST_VPN:-$SYNO_HOST}:$remote_path && rm $TEMP_VPS"
        else
            scp -P "${VPS_SSH_PORT:-22}" "$local_path" "$VPS_USER@$VPS_IP:$TEMP_VPS"
            ssh -p "${VPS_SSH_PORT:-22}" "$VPS_USER@$VPS_IP" "scp -o StrictHostKeyChecking=no -P ${SYNO_SSH_PORT:-22} $TEMP_VPS $SYNO_USER@${SYNO_HOST_VPN:-$SYNO_HOST}:$remote_path && rm $TEMP_VPS"
        fi
    fi
    
    success "Файл скопирован на Synology"
}

section "🚀 Полный автодеплой ShortsAI Studio"

# 1. Проверка конфигурации
section "Проверка конфигурации"

info "VPS: $VPS_USER@$VPS_IP"
info "Synology: $SYNO_USER@$SYNO_HOST"
info "Репозиторий: $GITHUB_REPO_URL"
info "Backend URL: $BACKEND_URL"
echo ""

read -p "Продолжить деплой? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    info "Деплой отменён"
    exit 0
fi

# 2. Настройка VPS (если нужно)
section "Настройка VPS"

info "Подключаюсь к VPS..."

# Копируем скрипты на VPS
TEMP_DIR="/tmp/shortsai_deploy_$$"
run_remote "$VPS_IP" "$VPS_USER" "mkdir -p $TEMP_DIR" "${VPS_SSH_PORT:-22}"

copy_to_remote "$VPS_IP" "$VPS_USER" "config.sh" "$TEMP_DIR/config.sh"
copy_to_remote "$VPS_IP" "$VPS_USER" "vps_setup.sh" "$TEMP_DIR/vps_setup.sh"
# Также копируем скрипт проброса портов из vps/ (если существует)
if [ -f "$SCRIPT_DIR/../vps/synology-port-forward.sh" ]; then
    copy_to_remote "$VPS_IP" "$VPS_USER" "$SCRIPT_DIR/../vps/synology-port-forward.sh" "$TEMP_DIR/synology-port-forward.sh"
fi

# Запускаем настройку VPS (только если это первый раз)
info "Запускаю настройку VPS..."
run_remote "$VPS_IP" "$VPS_USER" "bash $TEMP_DIR/vps_setup.sh" "${VPS_SSH_PORT:-22}" || info "VPS уже настроен или произошла ошибка"

success "VPS настроен"

# 3. Деплой на Synology
section "Деплой на Synology"

info "Проверяю доступность Synology..."

# Проверяем доступность Synology напрямую
if timeout 3 bash -c "echo > /dev/tcp/$SYNO_HOST/$SYNO_SSH_PORT" 2>/dev/null; then
    success "Synology доступен напрямую: $SYNO_USER@$SYNO_HOST:$SYNO_SSH_PORT"
    CONNECTION_TYPE="direct"
else
    info "Synology недоступен напрямую, пробую через VPS..."
    if [ -n "${SYNO_HOST_VPN:-}" ]; then
        if run_remote "$VPS_IP" "$VPS_USER" "ping -c 1 -W 2 ${SYNO_HOST_VPN} > /dev/null 2>&1" "${VPS_SSH_PORT:-22}"; then
            success "Synology доступен через VPN: $SYNO_HOST_VPN"
            CONNECTION_TYPE="vpn"
        else
            error "Synology недоступен ни напрямую, ни через VPN. Проверьте подключение."
        fi
    else
        error "Synology недоступен напрямую и SYNO_HOST_VPN не настроен. Проверьте config.sh"
    fi
fi

# Копируем скрипты на Synology
run_synology "mkdir -p $TEMP_DIR"

copy_to_synology "config.sh" "$TEMP_DIR/config.sh"
copy_to_synology "synology_deploy.sh" "$TEMP_DIR/synology_deploy.sh"

# Делаем скрипты исполняемыми
run_synology "chmod +x $TEMP_DIR/*.sh"

# Запускаем деплой на Synology
info "Запускаю деплой на Synology..."
run_synology "bash $TEMP_DIR/synology_deploy.sh" || error "Деплой на Synology завершился с ошибкой"

success "Деплой на Synology завершён"

# 4. Очистка временных файлов
section "Очистка"

info "Удаляю временные файлы..."
run_remote "$VPS_IP" "$VPS_USER" "rm -rf $TEMP_DIR" "${VPS_SSH_PORT:-22}" || true
run_synology "rm -rf $TEMP_DIR" || true

success "Временные файлы удалены"

# 5. Финальная проверка
section "Финальная проверка"

info "Проверяю доступность backend..."
HEALTH_URL="$BACKEND_URL/health"

if curl -f -s "$HEALTH_URL" > /dev/null 2>&1; then
    success "✅ Backend доступен по адресу: $BACKEND_URL"
    echo ""
    info "Ответ health endpoint:"
    curl -s "$HEALTH_URL" | head -5
else
    info "⚠️  Backend не отвечает на $HEALTH_URL"
    info "Проверьте логи на Synology:"
    if [ "$CONNECTION_TYPE" = "direct" ]; then
        if [ -n "${SYNO_SSH_HOST:-}" ] && [ "$SYNO_SSH_HOST" != "${SYNO_USER}@${SYNO_HOST}" ]; then
            echo -e "${GREEN}  ssh $SYNO_SSH_HOST 'pm2 logs $PM2_APP_NAME'${NC}"
        else
            echo -e "${GREEN}  ssh $SYNO_USER@$SYNO_HOST 'pm2 logs $PM2_APP_NAME'${NC}"
        fi
    else
        echo -e "${GREEN}  ssh $VPS_USER@$VPS_IP \"ssh $SYNO_USER@${SYNO_HOST_VPN:-$SYNO_HOST} 'pm2 logs $PM2_APP_NAME'\"${NC}"
    fi
fi

section "🎉 Деплой завершён!"

info "Информация о деплое:"
echo -e "${GREEN}  Backend URL:${NC} $BACKEND_URL"
echo -e "${GREEN}  Health check:${NC} $HEALTH_URL"
if [ "$CONNECTION_TYPE" = "direct" ]; then
    if [ -n "${SYNO_SSH_HOST:-}" ] && [ "$SYNO_SSH_HOST" != "${SYNO_USER}@${SYNO_HOST}" ]; then
        echo -e "${GREEN}  Synology SSH:${NC} ssh $SYNO_SSH_HOST"
    else
        echo -e "${GREEN}  Synology SSH:${NC} ssh $SYNO_USER@$SYNO_HOST"
    fi
    echo -e "${GREEN}  VPS SSH:${NC} ssh $VPS_USER@$VPS_IP"
    echo ""
    info "Полезные команды:"
    if [ -n "${SYNO_SSH_HOST:-}" ] && [ "$SYNO_SSH_HOST" != "${SYNO_USER}@${SYNO_HOST}" ]; then
        echo -e "${GREEN}  Просмотр логов:${NC} ssh $SYNO_SSH_HOST 'pm2 logs $PM2_APP_NAME'"
        echo -e "${GREEN}  Статус:${NC} ssh $SYNO_SSH_HOST 'pm2 status'"
        echo -e "${GREEN}  Перезапуск:${NC} ssh $SYNO_SSH_HOST 'pm2 restart $PM2_APP_NAME'"
    else
        echo -e "${GREEN}  Просмотр логов:${NC} ssh $SYNO_USER@$SYNO_HOST 'pm2 logs $PM2_APP_NAME'"
        echo -e "${GREEN}  Статус:${NC} ssh $SYNO_USER@$SYNO_HOST 'pm2 status'"
        echo -e "${GREEN}  Перезапуск:${NC} ssh $SYNO_USER@$SYNO_HOST 'pm2 restart $PM2_APP_NAME'"
    fi
else
    echo -e "${GREEN}  Synology SSH (через VPS):${NC} ssh $VPS_USER@$VPS_IP \"ssh $SYNO_USER@${SYNO_HOST_VPN:-$SYNO_HOST}\""
    echo -e "${GREEN}  VPS SSH:${NC} ssh $VPS_USER@$VPS_IP"
    echo ""
    info "Полезные команды:"
    echo -e "${GREEN}  Просмотр логов:${NC} ssh $VPS_USER@$VPS_IP \"ssh $SYNO_USER@${SYNO_HOST_VPN:-$SYNO_HOST} 'pm2 logs $PM2_APP_NAME'\""
    echo -e "${GREEN}  Статус:${NC} ssh $VPS_USER@$VPS_IP \"ssh $SYNO_USER@${SYNO_HOST_VPN:-$SYNO_HOST} 'pm2 status'\""
    echo -e "${GREEN}  Перезапуск:${NC} ssh $VPS_USER@$VPS_IP \"ssh $SYNO_USER@${SYNO_HOST_VPN:-$SYNO_HOST} 'pm2 restart $PM2_APP_NAME'\""
fi
echo ""

success "Готово! 🚀"

