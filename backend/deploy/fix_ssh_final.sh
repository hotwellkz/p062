#!/bin/bash
# Скрипт для финального исправления SSH на Synology
# Выполните на Synology: bash fix_ssh_final.sh

set -e

echo "============================================"
echo "Исправление SSH-доступа по ключам"
echo "============================================"
echo ""

# 1. Проверка домашней директории
echo "Шаг 1: Проверка домашней директории..."
echo "HOME: $HOME"
ls -la "$HOME"
echo ""

# 2. Определение правильного пути
SSH_DIR="/var/services/homes/admin/.ssh"
AUTH_KEYS="$SSH_DIR/authorized_keys"

echo "Шаг 2: Правильный путь для authorized_keys:"
echo "  $AUTH_KEYS"
echo ""

# 3. Создание директории и перемещение authorized_keys
echo "Шаг 3: Создание директории и перемещение authorized_keys..."
mkdir -p "$SSH_DIR"

# Если authorized_keys есть в ~/.ssh, перемещаем его
if [ -f ~/.ssh/authorized_keys ] && [ ! -f "$AUTH_KEYS" ]; then
    echo "Перемещаю authorized_keys из ~/.ssh..."
    cp ~/.ssh/authorized_keys "$AUTH_KEYS"
    echo "✅ Файл скопирован"
elif [ -f ~/.ssh/authorized_keys ] && [ -f "$AUTH_KEYS" ]; then
    echo "⚠️  authorized_keys существует в обоих местах"
    echo "Объединяю ключи..."
    cat ~/.ssh/authorized_keys >> "$AUTH_KEYS"
    sort -u "$AUTH_KEYS" -o "$AUTH_KEYS"
    echo "✅ Ключи объединены"
elif [ ! -f "$AUTH_KEYS" ]; then
    echo "⚠️  authorized_keys не найден, создаю пустой файл"
    touch "$AUTH_KEYS"
fi

# 4. Установка правильных прав
echo ""
echo "Шаг 4: Установка правильных прав..."
chmod 700 "$SSH_DIR"
chmod 600 "$AUTH_KEYS"
chown admin:users "$SSH_DIR" -R

echo "Проверка прав:"
ls -la "$SSH_DIR"
echo ""

# 5. Проверка и исправление SSH конфига
echo "Шаг 5: Проверка SSH конфига..."
SSH_CONFIG="/etc/ssh/sshd_config"

if [ ! -f "$SSH_CONFIG" ]; then
    echo "❌ Файл $SSH_CONFIG не найден!"
    exit 1
fi

# Проверяем текущие настройки
echo "Текущие настройки:"
grep -E "PubkeyAuthentication|AuthorizedKeysFile" "$SSH_CONFIG" || echo "Настройки не найдены"
echo ""

# Если нет прав на запись, используем sudo
if [ -w "$SSH_CONFIG" ]; then
    SUDO_CMD=""
else
    SUDO_CMD="sudo"
    echo "Требуются права root для изменения конфига"
fi

# Создаём резервную копию
$SUDO_CMD cp "$SSH_CONFIG" "$SSH_CONFIG.backup.$(date +%Y%m%d_%H%M%S)"

# Удаляем старые настройки
$SUDO_CMD sed -i '/^PubkeyAuthentication/d' "$SSH_CONFIG"
$SUDO_CMD sed -i '/^#PubkeyAuthentication/d' "$SSH_CONFIG"
$SUDO_CMD sed -i '/^AuthorizedKeysFile/d' "$SSH_CONFIG"
$SUDO_CMD sed -i '/^#AuthorizedKeysFile/d' "$SSH_CONFIG"

# Добавляем правильные настройки
echo "PubkeyAuthentication yes" | $SUDO_CMD tee -a "$SSH_CONFIG" > /dev/null
echo "AuthorizedKeysFile .ssh/authorized_keys" | $SUDO_CMD tee -a "$SSH_CONFIG" > /dev/null

echo "Обновлённые настройки:"
grep -E "PubkeyAuthentication|AuthorizedKeysFile" "$SSH_CONFIG"
echo ""

# 6. Перезапуск SSH
echo "Шаг 6: Перезапуск SSH сервера..."
if command -v synoservice &> /dev/null; then
    $SUDO_CMD synoservice --restart sshd
    echo "✅ SSH перезапущен через synoservice"
elif command -v systemctl &> /dev/null; then
    $SUDO_CMD systemctl restart sshd
    echo "✅ SSH перезапущен через systemctl"
else
    echo "⚠️  Не удалось перезапустить автоматически"
    echo "Выполните вручную: sudo synoservice --restart sshd"
fi

echo ""
echo "============================================"
echo "Исправление завершено!"
echo "============================================"
echo ""
echo "Финальная проверка:"
echo "Содержимое authorized_keys:"
cat "$AUTH_KEYS"
echo ""
echo "Права:"
ls -la "$SSH_DIR"
echo ""
echo "Проверьте подключение с локального компьютера:"
echo "  ssh -i ~/.ssh/shortsai_synology admin@192.168.100.222 'echo OK'"
echo ""




