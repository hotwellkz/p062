#!/bin/bash
# Скрипт для исправления SSH-ключей на Synology
# Выполняется на Synology

set -e

echo "============================================"
echo "Исправление SSH-ключей на Synology"
echo "============================================"
echo ""

# Шаг 1: Проверка прав (уже выполнено)
echo "✅ Шаг 1: Права установлены"

# Шаг 2: Проверка расположения authorized_keys
echo ""
echo "Шаг 2: Проверка расположения authorized_keys..."
SSH_DIR="/var/services/homes/admin/.ssh"
AUTH_KEYS="$SSH_DIR/authorized_keys"

# Проверяем, существует ли директория
if [ ! -d "$SSH_DIR" ]; then
    echo "Создаю директорию $SSH_DIR..."
    mkdir -p "$SSH_DIR"
    chmod 700 "$SSH_DIR"
    chown admin:users "$SSH_DIR"
fi

# Проверяем, есть ли authorized_keys в правильном месте
if [ ! -f "$AUTH_KEYS" ]; then
    echo "⚠️  authorized_keys не найден в $AUTH_KEYS"
    # Проверяем, есть ли он в ~/.ssh
    if [ -f ~/.ssh/authorized_keys ]; then
        echo "Найден ~/.ssh/authorized_keys, копирую в правильное место..."
        cp ~/.ssh/authorized_keys "$AUTH_KEYS"
        chmod 600 "$AUTH_KEYS"
        chown admin:users "$AUTH_KEYS"
    else
        echo "Создаю новый файл authorized_keys..."
        touch "$AUTH_KEYS"
        chmod 600 "$AUTH_KEYS"
        chown admin:users "$AUTH_KEYS"
    fi
fi

echo "Содержимое authorized_keys:"
cat "$AUTH_KEYS"
echo ""

# Шаг 3: Проверка SSH конфига
echo "Шаг 3: Проверка SSH конфига..."
SSH_CONFIG="/etc/ssh/sshd_config"

if [ ! -f "$SSH_CONFIG" ]; then
    echo "❌ Файл $SSH_CONFIG не найден!"
    exit 1
fi

# Проверяем настройки
echo "Текущие настройки PubkeyAuthentication и AuthorizedKeysFile:"
grep -E "PubkeyAuthentication|AuthorizedKeysFile" "$SSH_CONFIG" || echo "Настройки не найдены"

# Создаём резервную копию
cp "$SSH_CONFIG" "$SSH_CONFIG.backup.$(date +%Y%m%d_%H%M%S)"

# Проверяем и исправляем настройки
NEEDS_RESTART=false

# Проверяем PubkeyAuthentication
if ! grep -q "^PubkeyAuthentication yes" "$SSH_CONFIG"; then
    echo "Исправляю PubkeyAuthentication..."
    # Удаляем старые строки
    sed -i '/^PubkeyAuthentication/d' "$SSH_CONFIG"
    sed -i '/^#PubkeyAuthentication/d' "$SSH_CONFIG"
    # Добавляем правильную строку
    echo "PubkeyAuthentication yes" >> "$SSH_CONFIG"
    NEEDS_RESTART=true
fi

# Проверяем AuthorizedKeysFile
if ! grep -q "^AuthorizedKeysFile" "$SSH_CONFIG"; then
    echo "Добавляю AuthorizedKeysFile..."
    echo "AuthorizedKeysFile .ssh/authorized_keys" >> "$SSH_CONFIG"
    NEEDS_RESTART=true
fi

echo "Обновлённый SSH конфиг:"
grep -E "PubkeyAuthentication|AuthorizedKeysFile" "$SSH_CONFIG"
echo ""

# Шаг 4: Перезапуск SSH
if [ "$NEEDS_RESTART" = true ]; then
    echo "Шаг 4: Перезапуск SSH сервера..."
    if command -v synoservice &> /dev/null; then
        synoservice --restart sshd
        echo "✅ SSH сервер перезапущен через synoservice"
    elif command -v systemctl &> /dev/null; then
        systemctl restart sshd
        echo "✅ SSH сервер перезапущен через systemctl"
    else
        echo "⚠️  Не удалось перезапустить SSH сервер автоматически"
        echo "Выполните вручную: synoservice --restart sshd"
    fi
else
    echo "Шаг 4: Перезапуск SSH не требуется"
fi

echo ""
echo "============================================"
echo "Исправление завершено!"
echo "============================================"
echo ""
echo "Проверка прав:"
ls -la "$SSH_DIR"
echo ""
echo "Содержимое authorized_keys:"
cat "$AUTH_KEYS"
echo ""
echo "Проверьте подключение с локального компьютера:"
echo "  ssh -i ~/.ssh/shortsai_synology admin@192.168.100.222 'echo OK'"
echo ""




