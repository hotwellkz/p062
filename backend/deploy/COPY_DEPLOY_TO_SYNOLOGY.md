# 📋 Копирование папки deploy на Synology

## Проблема

Папка `deploy` отсутствует в клонированном репозитории на Synology.

## ✅ Решение: Скопируйте папку deploy

### Вариант 1: Через VPS (VPN туннель)

**С вашего компьютера:**

```powershell
# 1. Создайте архив папки deploy
cd C:\Users\studo\Downloads\p039-master\p039-master
tar -czf deploy.tar.gz backend/deploy

# 2. Скопируйте на VPS
scp deploy.tar.gz root@159.255.37.158:/tmp/

# 3. Подключитесь к VPS
ssh root@159.255.37.158

# 4. На VPS скопируйте на Synology
scp /tmp/deploy.tar.gz admin@10.8.0.2:/tmp/

# 5. На Synology распакуйте
ssh admin@10.8.0.2
cd /volume1/shortsai/app/backend
tar -xzf /tmp/deploy.tar.gz
rm /tmp/deploy.tar.gz
```

### Вариант 2: Используйте существующий скрипт

**На Synology выполните:**

```bash
cd /volume1/shortsai/app/backend
export PATH="/volume1/@appstore/Node.js_v20/usr/local/bin:$PATH"
bash deploy_to_synology_production.sh
```

Этот скрипт уже есть в репозитории и должен работать!

### Вариант 3: Обновите репозиторий

**На Synology:**

```bash
cd /volume1/shortsai/app
git fetch origin main
git reset --hard origin/main
cd backend
ls -la deploy/  # Проверьте, появилась ли папка
```

---

**Рекомендация: Используйте Вариант 2 - запустите существующий скрипт! 🚀**





