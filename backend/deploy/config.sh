#!/bin/bash

# ============================================
# Конфигурация автодеплоя ShortsAI Studio
# ============================================
# Измените эти переменные под вашу инфраструктуру
# ============================================

# VPS настройки
export VPS_IP="159.255.37.158"
export VPS_HOST="vm3737624.firstbyte.club"  # Доменное имя VPS (опционально)
export VPS_USER="root"
export VPS_SSH_PORT="22"

# Synology настройки
# Подключение напрямую по локальному IP (если в одной сети) или через VPN
export SYNO_HOST="192.168.100.222"   # Локальный IP Synology (для прямого подключения)
export SYNO_HOST_VPN="10.8.0.2"      # IP Synology в VPN туннеле (если используется VPN)
export SYNO_USER="admin"
export SYNO_SSH_PORT="22"
export SYNO_LOCAL_IP="192.168.100.222"  # Локальный IP Synology в локальной сети

# Пути на Synology
export SYNO_APP_PATH="/volume1/shortsai/app"
export SYNO_BACKEND_PATH="/volume1/shortsai/app/backend"
export SYNO_STORAGE_PATH="/volume1/shortsai/videos"

# GitHub репозиторий (ЗАПОЛНИТЕ СВОЙ URL!)
export GITHUB_REPO_URL="https://github.com/hotwellkz/p041.git"
export GITHUB_BRANCH="main"

# Порты
export BACKEND_PORT="8080"           # Порт на Synology, на котором слушает backend
export VPS_PUBLIC_PORT="5000"        # Публичный порт на VPS для backend API (HTTP)
export VPS_PUBLIC_PORT_HTTPS="5001"  # Публичный порт на VPS для HTTPS/DSM (опционально)
export VPS_PUBLIC_IP="159.255.37.158"
export VPS_PUBLIC_DOMAIN="vm3737624.firstbyte.club"  # Доменное имя VPS

# VPN туннель (для проброса портов, если используется)
export SYNO_VPN_IP="10.8.0.2"       # IP Synology в VPN туннеле (если используется VPN)
export USE_VPN_TUNNEL="false"       # Использовать VPN туннель? (true/false)

# SSH ключи
# Автоматически определяется путь к ключу shortsai_synology
if [ -n "$USERPROFILE" ]; then
    # Windows Git Bash
    SSH_DIR="$USERPROFILE/.ssh"
else
    # Linux/Mac
    SSH_DIR="$HOME/.ssh"
fi

# Используем ключ shortsai_synology если он существует
if [ -f "$SSH_DIR/shortsai_synology" ]; then
    export SYNO_SSH_KEY_PATH="$SSH_DIR/shortsai_synology"
    export SYNO_SSH_HOST="synology-shortsai"  # Используем SSH config host
else
    # Fallback на старый способ
    # export SYNO_SSH_KEY_PATH="~/.ssh/id_synology"
    export SYNO_SSH_HOST="${SYNO_USER}@${SYNO_HOST}"
fi

# VPS SSH ключ (опционально)
# export VPS_SSH_KEY_PATH="~/.ssh/id_rsa"

# Backend настройки
# BACKEND_URL будет сформирован автоматически, можно переопределить
export BACKEND_URL="http://${VPS_PUBLIC_IP}:${VPS_PUBLIC_PORT}"
# Или используйте домен (если настроен):
# export BACKEND_URL="http://${VPS_PUBLIC_DOMAIN}:${VPS_PUBLIC_PORT}"
export PM2_APP_NAME="shortsai-backend"
export NODE_ENV="production"

# ============================================
# Проверка обязательных переменных
# ============================================
check_config() {
    local errors=0
    
    if [ -z "$VPS_IP" ]; then
        echo "❌ Ошибка: VPS_IP не установлен"
        errors=$((errors + 1))
    fi
    
    if [ -z "$SYNO_HOST" ]; then
        echo "❌ Ошибка: SYNO_HOST не установлен"
        errors=$((errors + 1))
    fi
    
    if [ -z "$GITHUB_REPO_URL" ]; then
        echo "❌ Ошибка: GITHUB_REPO_URL не установлен"
        errors=$((errors + 1))
    fi
    
    if [ $errors -gt 0 ]; then
        echo "Пожалуйста, исправьте ошибки в config.sh"
        exit 1
    fi
}

# Автоматически проверяем конфигурацию при загрузке
check_config

