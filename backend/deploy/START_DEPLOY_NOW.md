# 🚀 Запуск деплоя СЕЙЧАС

## Шаг 1: Исправьте SSH на Synology (если ещё не исправлено)

Вы уже на Synology (admin@Hotwell:~$). Выполните:

```bash
# Быстрое исправление SSH
mkdir -p /var/services/homes/admin/.ssh
if [ -f ~/.ssh/authorized_keys ]; then
    cp ~/.ssh/authorized_keys /var/services/homes/admin/.ssh/authorized_keys
fi
chmod 700 /var/services/homes/admin/.ssh
chmod 600 /var/services/homes/admin/.ssh/authorized_keys
chown admin:users /var/services/homes/admin/.ssh -R

# Исправление SSH конфига (потребуется пароль admin)
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
sudo sed -i '/^PubkeyAuthentication/d' /etc/ssh/sshd_config
sudo sed -i '/^#PubkeyAuthentication/d' /etc/ssh/sshd_config
sudo sed -i '/^AuthorizedKeysFile/d' /etc/ssh/sshd_config
sudo sed -i '/^#AuthorizedKeysFile/d' /etc/ssh/sshd_config
echo "PubkeyAuthentication yes" | sudo tee -a /etc/ssh/sshd_config > /dev/null
echo "AuthorizedKeysFile .ssh/authorized_keys" | sudo tee -a /etc/ssh/sshd_config > /dev/null
sudo synoservice --restart sshd

echo "✅ SSH исправлен!"
```

Выйдите из Synology и проверьте:
```powershell
ssh -i C:\Users\studo\.ssh\shortsai_synology admin@192.168.100.222 "echo OK"
```

## Шаг 2: Запустите деплой

### На Windows через Git Bash:

```bash
cd /c/Users/studo/Downloads/p039-master/p039-master/backend
bash deploy/full_synology_deploy.sh
```

### Или только обновление кода:

```bash
cd /c/Users/studo/Downloads/p039-master/p039-master/backend
bash deploy/deploy_to_synology.sh
```

## Что делает full_synology_deploy.sh:

1. ✅ Копирует код на Synology
2. ✅ Проверяет Node.js и PM2
3. ✅ Устанавливает зависимости (npm install)
4. ✅ Собирает проект (npm run build)
5. ✅ Создаёт .env из env.example (если нет)
6. ✅ Запускает через PM2
7. ✅ Проверяет работу

## После деплоя:

Настройте .env на Synology:
```bash
ssh admin@192.168.100.222 'nano /volume1/Hotwell/Backends/shortsai-backend/.env'
```

Заполните все необходимые переменные (Firebase, Telegram, BACKEND_URL и т.д.)

Перезапустите backend:
```bash
ssh admin@192.168.100.222 'pm2 restart shortsai-backend'
```

---

**Готово!** 🎉




