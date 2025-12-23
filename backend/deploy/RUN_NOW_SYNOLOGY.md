# 🚀 Выполните это ПРЯМО СЕЙЧАС на Synology

## Вы уже на Synology (admin@Hotwell:/volume1/shortsai/app/backend$)

### Вариант 1: Обновите репозиторий (чтобы получить папку deploy)

```bash
cd /volume1/shortsai/app
git fetch origin main
git reset --hard origin/main
cd backend
ls -la deploy/  # Проверьте, появилась ли папка
```

### Вариант 2: Используйте существующий скрипт (быстрее!)

**На Synology выполните:**

```bash
cd /volume1/shortsai/app/backend
export PATH="/volume1/@appstore/Node.js_v20/usr/local/bin:$PATH"

# Исправьте окончания строк
sed -i 's/\r$//' deploy_to_synology_production.sh
chmod +x deploy_to_synology_production.sh

# Запустите деплой
bash deploy_to_synology_production.sh
```

### Вариант 3: Скопируйте папку deploy отдельно

**С вашего компьютера:**

```powershell
# Создайте архив
cd C:\Users\studo\Downloads\p039-master\p039-master
tar -czf deploy.tar.gz backend\deploy

# Скопируйте на VPS
scp deploy.tar.gz root@159.255.37.158:/tmp/

# На VPS скопируйте на Synology
ssh root@159.255.37.158
scp /tmp/deploy.tar.gz admin@10.8.0.2:/tmp/
```

**На Synology:**

```bash
cd /volume1/shortsai/app/backend
tar -xzf /tmp/deploy.tar.gz
rm /tmp/deploy.tar.gz
export PATH="/volume1/@appstore/Node.js_v20/usr/local/bin:$PATH"
bash deploy/synology_deploy.sh
```

## ✅ Рекомендация: Используйте Вариант 2

Скрипт `deploy_to_synology_production.sh` уже есть и должен работать!

---

**Выполните команды выше на Synology! 🚀**





