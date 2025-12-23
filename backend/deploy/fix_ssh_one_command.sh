#!/bin/bash
# Все команды для исправления SSH в одном скрипте
# Выполните на Synology: bash fix_ssh_one_command.sh

set -e

echo "============================================"
echo "Исправление SSH-ключей на Synology"
echo "============================================"
echo ""

SSH_DIR="/var/services/homes/admin/.ssh"
AUTH_KEYS="$SSH_DIR/authorized_keys"
SSH_CONFIG="/etc/ssh/sshd_config"

# Шаг 1: Создание директории и установка прав
echo "Шаг 1: Создание директории и установка прав..."
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"
chown admin:users "$SSH_DIR"

# Копируем authorized_keys из ~/.ssh если нужно
if [ -f ~/.ssh/authorized_keys ] && [ ! -f "$AUTH_KEYS" ]; then
    echo "Копирую authorized_keys из ~/.ssh..."
    cp ~/.ssh/authorized_keys "$AUTH_KEYS"
fi

# Создаём authorized_keys если его нет
if [ ! -f "$AUTH_KEYS" ]; then
    echo "Создаю authorized_keys..."
    touch "$AUTH_KEYS"
    # Добавляем ключ если он есть в ~/.ssh
    if [ -f ~/.ssh/authorized_keys ]; then
        cat ~/.ssh/authorized_keys > "$AUTH_KEYS"
    fi
fi

chmod 600 "$AUTH_KEYS"
chown admin:users "$AUTH_KEYS"

echo "✅ Права установлены"
echo ""

# Шаг 2: Проверка содержимого
echo "Шаг 2: Проверка authorized_keys..."
if [ -f "$AUTH_KEYS" ]; then
    echo "Содержимое $AUTH_KEYS:"
    cat "$AUTH_KEYS"
    echo ""
else
    echo "⚠️  Файл $AUTH_KEYS не найден!"
fi

# Шаг 3: Исправление SSH конфига
echo "Шаг 3: Исправление SSH конфига..."
if [ ! -f "$SSH_CONFIG" ]; then
    echo "❌ Файл $SSH_CONFIG не найден!"
    exit 1
fi

# Резервная копия
cp "$SSH_CONFIG" "$SSH_CONFIG.backup.$(date +%Y%m%d_%H%M%S)"

# Удаляем старые настройки
sed -i '/^PubkeyAuthentication/d' "$SSH_CONFIG"
sed -i '/^#PubkeyAuthentication/d' "$SSH_CONFIG"
sed -i '/^AuthorizedKeysFile/d' "$SSH_CONFIG"
sed -i '/^#AuthorizedKeysFile/d' "$SSH_CONFIG"

# Добавляем правильные настройки
echo "PubkeyAuthentication yes" >> "$SSH_CONFIG"
echo "AuthorizedKeysFile .ssh/authorized_keys" >> "$SSH_CONFIG"

echo "Обновлённый конфиг:"
grep -E "PubkeyAuthentication|AuthorizedKeysFile" "$SSH_CONFIG"
echo ""

# Шаг 4: Перезапуск SSH
echo "Шаг 4: Перезапуск SSH сервера..."
if command -v synoservice &> /dev/null; then
    synoservice --restart sshd
    echo "✅ SSH перезапущен через synoservice"
elif command -v systemctl &> /dev/null; then
    systemctl restart sshd
    echo "✅ SSH перезапущен через systemctl"
else
    echo "⚠️  Не удалось перезапустить автоматически"
    echo "Выполните: synoservice --restart sshd"
fi

echo ""
echo "============================================"
echo "Исправление завершено!"
echo "============================================"
echo ""
echo "Финальная проверка прав:"
ls -la "$SSH_DIR"
echo ""
echo "Проверьте подключение с локального компьютера:"
echo "  ssh -i ~/.ssh/shortsai_synology admin@192.168.100.222 'echo OK'"
echo ""




