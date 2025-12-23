# 📋 Инструкция по деплою на Synology

## ✅ Что готово

1. ✅ Создан скрипт деплоя: `backend/deploy/deploy_to_synology.sh`
2. ✅ Создан полный скрипт деплоя: `backend/deploy/full_synology_deploy.sh`
3. ✅ Настроены пути: `/volume1/Hotwell/Backends/shortsai-backend`

## 🚀 Как запустить деплой

### На Windows (PowerShell)

**Вариант 1: Использовать Git Bash**
1. Откройте **Git Bash**
2. Выполните:
```bash
cd /c/Users/studo/Downloads/p039-master/p039-master/backend
bash deploy/full_synology_deploy.sh
```

**Вариант 2: Только обновление кода**
```bash
cd /c/Users/studo/Downloads/p039-master/p039-master/backend
bash deploy/deploy_to_synology.sh
```

### Ручной деплой (если скрипты не работают)

#### Шаг 1: Копирование кода

На вашем компьютере (PowerShell):
```powershell
# Создайте архив
cd C:\Users\studo\Downloads\p039-master\p039-master\backend
tar -czf C:\temp\backend.tar.gz --exclude=".git" --exclude="node_modules" --exclude="tmp" --exclude="storage\videos" --exclude=".env" --exclude="dist" --exclude="*.log" .

# Скопируйте на Synology
scp C:\temp\backend.tar.gz admin@192.168.100.222:/tmp/
```

#### Шаг 2: На Synology

```bash
ssh admin@192.168.100.222
cd /volume1/Hotwell/Backends/shortsai-backend
tar -xzf /tmp/backend.tar.gz
rm /tmp/backend.tar.gz
```

#### Шаг 3: Установка зависимостей и сборка

```bash
cd /volume1/Hotwell/Backends/shortsai-backend
rm -rf node_modules
npm install
npm run build
```

#### Шаг 4: Настройка .env

```bash
# Если .env нет, создайте из примера
cp env.example .env
nano .env
```

#### Шаг 5: Запуск через PM2

```bash
# Остановите старый процесс
pm2 stop shortsai-backend 2>/dev/null || true
pm2 delete shortsai-backend 2>/dev/null || true

# Запустите новый
pm2 start dist/index.js --name shortsai-backend

# Сохраните конфигурацию
pm2 save
pm2 startup
```

#### Шаг 6: Проверка

```bash
pm2 status
curl http://localhost:8080/health
```

## 📝 Полезные команды

### Обновление кода
```bash
# С локального компьютера (Git Bash)
cd /c/Users/studo/Downloads/p039-master/p039-master/backend
bash deploy/deploy_to_synology.sh
```

### Перезапуск backend
```bash
ssh admin@192.168.100.222 'pm2 restart shortsai-backend'
```

### Просмотр логов
```bash
ssh admin@192.168.100.222 'pm2 logs shortsai-backend'
```

### Статус
```bash
ssh admin@192.168.100.222 'pm2 status'
```

### Проверка health
```bash
ssh admin@192.168.100.222 'curl http://localhost:8080/health'
```

## ⚠️ Важные замечания

1. **SSH-ключи**: Если SSH всё ещё требует пароль, настройте через веб-интерфейс Synology или используйте пароль временно.

2. **.env файл**: Обязательно настройте `.env` на Synology с правильными значениями:
   - `BACKEND_URL=http://159.255.37.158:5000` (публичный URL через VPS)
   - `STORAGE_ROOT=/volume1/Hotwell/Backends/shortsai-backend/storage/videos`
   - Все секреты (Firebase, Telegram и т.д.)

3. **PM2 автозапуск**: После `pm2 startup` выполните команду, которую выдаст PM2 (обычно с sudo).

## 📚 Дополнительная документация

- `backend/deploy/DEPLOY_SYNOLOGY_FINAL.md` - полная инструкция
- `backend/deploy/deploy_to_synology.sh` - скрипт деплоя кода
- `backend/deploy/full_synology_deploy.sh` - полный автоматический деплой




