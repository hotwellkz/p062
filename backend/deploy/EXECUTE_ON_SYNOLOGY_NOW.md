# 🔧 Выполните эти команды на Synology (вы уже подключены)

## Вы уже на Synology (admin@Hotwell:~$)

### Шаг 2: Проверка расположения authorized_keys

```bash
# Проверяем правильный путь
ls -la /var/services/homes/admin/.ssh
cat /var/services/homes/admin/.ssh/authorized_keys

# Если файл есть в ~/.ssh, но не в /var/services/homes/admin/.ssh
if [ -f ~/.ssh/authorized_keys ] && [ ! -f /var/services/homes/admin/.ssh/authorized_keys ]; then
    mkdir -p /var/services/homes/admin/.ssh
    cp ~/.ssh/authorized_keys /var/services/homes/admin/.ssh/authorized_keys
    chmod 700 /var/services/homes/admin/.ssh
    chmod 600 /var/services/homes/admin/.ssh/authorized_keys
    chown admin:users /var/services/homes/admin/.ssh
    chown admin:users /var/services/homes/admin/.ssh/authorized_keys
fi
```

### Шаг 3: Проверка и исправление SSH конфига

```bash
# Проверяем текущие настройки
grep -E "PubkeyAuthentication|AuthorizedKeysFile" /etc/ssh/sshd_config

# Создаём резервную копию
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup.$(date +%Y%m%d_%H%M%S)

# Исправляем PubkeyAuthentication
sed -i '/^PubkeyAuthentication/d' /etc/ssh/sshd_config
sed -i '/^#PubkeyAuthentication/d' /etc/ssh/sshd_config
echo "PubkeyAuthentication yes" >> /etc/ssh/sshd_config

# Исправляем AuthorizedKeysFile
sed -i '/^AuthorizedKeysFile/d' /etc/ssh/sshd_config
sed -i '/^#AuthorizedKeysFile/d' /etc/ssh/sshd_config
echo "AuthorizedKeysFile .ssh/authorized_keys" >> /etc/ssh/sshd_config

# Проверяем результат
echo "Обновлённый конфиг:"
grep -E "PubkeyAuthentication|AuthorizedKeysFile" /etc/ssh/sshd_config
```

### Шаг 4: Перезапуск SSH сервера

```bash
# Пробуем через synoservice
if command -v synoservice &> /dev/null; then
    synoservice --restart sshd
    echo "SSH перезапущен через synoservice"
elif command -v systemctl &> /dev/null; then
    systemctl restart sshd
    echo "SSH перезапущен через systemctl"
else
    echo "Выполните вручную: synoservice --restart sshd"
fi
```

### Шаг 5: Финальная проверка прав

```bash
# Убеждаемся, что все права правильные
chmod 700 /var/services/homes/admin/.ssh
chmod 600 /var/services/homes/admin/.ssh/authorized_keys
chown admin:users /var/services/homes/admin/.ssh
chown admin:users /var/services/homes/admin/.ssh/authorized_keys

# Проверяем
ls -la /var/services/homes/admin/.ssh
cat /var/services/homes/admin/.ssh/authorized_keys
```

### Шаг 6: Проверка логов (если всё ещё не работает)

```bash
tail -n 50 /var/log/auth.log | grep ssh
```

---

## После выполнения всех шагов

Выйдите из Synology и проверьте с локального компьютера:

```powershell
ssh -i C:\Users\studo\.ssh\shortsai_synology admin@192.168.100.222 "echo 'SSH key works!'"
```

Если вход происходит БЕЗ пароля — проблема решена! ✅




