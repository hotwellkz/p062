# 🔧 Полное исправление SSH и деплой

## Вы уже на Synology (admin@Hotwell:~$)

### Шаг 1: Проверка и исправление прав (уже выполнено)

Права должны быть установлены. Проверьте:

```bash
ls -la /var/services/homes/admin/.ssh
cat /var/services/homes/admin/.ssh/authorized_keys
```

### Шаг 2: Исправление SSH конфига

Выполните (потребуется пароль admin для sudo):

```bash
# Создайте резервную копию
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup.$(date +%Y%m%d_%H%M%S)

# Удалите старые настройки
sudo sed -i '/^PubkeyAuthentication/d' /etc/ssh/sshd_config
sudo sed -i '/^#PubkeyAuthentication/d' /etc/ssh/sshd_config
sudo sed -i '/^AuthorizedKeysFile/d' /etc/ssh/sshd_config
sudo sed -i '/^#AuthorizedKeysFile/d' /etc/ssh/sshd_config

# Добавьте правильные настройки
echo "PubkeyAuthentication yes" | sudo tee -a /etc/ssh/sshd_config > /dev/null
echo "AuthorizedKeysFile .ssh/authorized_keys" | sudo tee -a /etc/ssh/sshd_config > /dev/null

# Проверьте результат
grep -E "PubkeyAuthentication|AuthorizedKeysFile" /etc/ssh/sshd_config
```

### Шаг 3: Перезапуск SSH

```bash
sudo synoservice --restart sshd
```

Или если не работает:
```bash
sudo systemctl restart sshd
```

### Шаг 4: Проверка

Выйдите из Synology и проверьте с локального компьютера:

```powershell
ssh -i C:\Users\studo\.ssh\shortsai_synology admin@192.168.100.222 "echo 'SSH key works!'"
```

Если вход БЕЗ пароля — SSH исправлен! ✅

---

## После исправления SSH: Запуск деплоя

### На локальном компьютере (Git Bash):

```bash
cd /c/Users/studo/Downloads/p039-master/p039-master/backend
bash deploy/full_synology_deploy.sh
```

Этот скрипт автоматически:
1. Скопирует код на Synology
2. Проверит Node.js и PM2
3. Установит зависимости
4. Соберёт проект
5. Создаст .env (если нет)
6. Запустит через PM2
7. Проверит работу

---

## Если SSH всё ещё требует пароль

Проверьте логи:
```bash
tail -n 50 /var/log/auth.log | grep ssh
```

Ищите ошибки типа:
- "Authentication refused: bad ownership"
- "Authentication refused: file permissions too open"

Исправьте права:
```bash
chmod 700 /var/services/homes/admin/.ssh
chmod 600 /var/services/homes/admin/.ssh/authorized_keys
chown admin:users /var/services/homes/admin/.ssh -R
```




