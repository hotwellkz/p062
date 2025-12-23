# 🔧 Выполните эти команды на Synology

## Вы уже подключены к Synology (admin@Hotwell:~$)

Скопируйте и выполните этот скрипт:

```bash
# Создайте скрипт
cat > /tmp/fix_ssh.sh << 'EOF'
#!/bin/bash
set -e

SSH_DIR="/var/services/homes/admin/.ssh"
AUTH_KEYS="$SSH_DIR/authorized_keys"
SSH_CONFIG="/etc/ssh/sshd_config"

echo "1. Проверка домашней директории..."
echo "HOME: $HOME"
ls -la "$HOME"
echo ""

echo "2. Создание директории .ssh..."
mkdir -p "$SSH_DIR"

if [ -f ~/.ssh/authorized_keys ]; then
    echo "3. Копирование authorized_keys..."
    cp ~/.ssh/authorized_keys "$AUTH_KEYS"
fi

echo "4. Установка прав..."
chmod 700 "$SSH_DIR"
chmod 600 "$AUTH_KEYS"
chown admin:users "$SSH_DIR" -R

echo "5. Исправление SSH конфига (требуется sudo)..."
sudo cp "$SSH_CONFIG" "$SSH_CONFIG.backup.$(date +%Y%m%d_%H%M%S)"
sudo sed -i '/^PubkeyAuthentication/d' "$SSH_CONFIG"
sudo sed -i '/^#PubkeyAuthentication/d' "$SSH_CONFIG"
sudo sed -i '/^AuthorizedKeysFile/d' "$SSH_CONFIG"
sudo sed -i '/^#AuthorizedKeysFile/d' "$SSH_CONFIG"
echo "PubkeyAuthentication yes" | sudo tee -a "$SSH_CONFIG" > /dev/null
echo "AuthorizedKeysFile .ssh/authorized_keys" | sudo tee -a "$SSH_CONFIG" > /dev/null

echo "6. Перезапуск SSH..."
sudo synoservice --restart sshd || sudo systemctl restart sshd

echo ""
echo "✅ Готово! Проверьте подключение с локального компьютера"
EOF

chmod +x /tmp/fix_ssh.sh
bash /tmp/fix_ssh.sh
```

Или выполните команды по отдельности:

```bash
# 1. Проверка
echo $HOME
ls -la $HOME

# 2. Создание директории
mkdir -p /var/services/homes/admin/.ssh

# 3. Копирование authorized_keys
if [ -f ~/.ssh/authorized_keys ]; then
    cp ~/.ssh/authorized_keys /var/services/homes/admin/.ssh/authorized_keys
fi

# 4. Права
chmod 700 /var/services/homes/admin/.ssh
chmod 600 /var/services/homes/admin/.ssh/authorized_keys
chown admin:users /var/services/homes/admin/.ssh -R

# 5. SSH конфиг (требуется sudo, введите пароль admin)
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
sudo sed -i '/^PubkeyAuthentication/d' /etc/ssh/sshd_config
sudo sed -i '/^#PubkeyAuthentication/d' /etc/ssh/sshd_config
sudo sed -i '/^AuthorizedKeysFile/d' /etc/ssh/sshd_config
sudo sed -i '/^#AuthorizedKeysFile/d' /etc/ssh/sshd_config
echo "PubkeyAuthentication yes" | sudo tee -a /etc/ssh/sshd_config > /dev/null
echo "AuthorizedKeysFile .ssh/authorized_keys" | sudo tee -a /etc/ssh/sshd_config > /dev/null

# 6. Перезапуск SSH
sudo synoservice --restart sshd

# 7. Проверка
cat /var/services/homes/admin/.ssh/authorized_keys
ls -la /var/services/homes/admin/.ssh
```

После выполнения выйдите из Synology и проверьте с локального компьютера:

```powershell
ssh -i C:\Users\studo\.ssh\shortsai_synology admin@192.168.100.222 "echo OK"
```

Если вход происходит БЕЗ пароля — готово! ✅




