# 🚀 Быстрый гайд по деплою на Synology

## ✅ Готово к использованию

Все скрипты созданы и готовы. Выполните деплой одним из способов ниже.

## Способ 1: Полный автоматический деплой (рекомендуется)

### На Windows через Git Bash:

1. Откройте **Git Bash** (не PowerShell!)

2. Выполните:
```bash
cd /c/Users/studo/Downloads/p039-master/p039-master/backend
bash deploy/full_synology_deploy.sh
```

Скрипт автоматически:
- ✅ Скопирует код на Synology
- ✅ Проверит Node.js и PM2
- ✅ Установит зависимости
- ✅ Соберёт проект
- ✅ Создаст .env из env.example (если нет)
- ✅ Запустит через PM2
- ✅ Проверит работу

## Способ 2: Только обновление кода

```bash
cd /c/Users/studo/Downloads/p039-master/p039-master/backend
bash deploy/deploy_to_synology.sh
```

Затем на Synology вручную:
```bash
ssh admin@192.168.100.222
cd /volume1/Hotwell/Backends/shortsai-backend
npm install
npm run build
pm2 restart shortsai-backend
```

## 📋 Финальная сводка команд

### 1. Обновление кода на Synology

**С локального компьютера (Git Bash):**
```bash
cd /c/Users/studo/Downloads/p039-master/p039-master/backend
bash deploy/deploy_to_synology.sh
```

Или вручную через PowerShell (если нет Git Bash):
```powershell
# Создайте архив
cd C:\Users\studo\Downloads\p039-master\p039-master\backend
tar -czf C:\temp\backend.tar.gz --exclude=".git" --exclude="node_modules" --exclude="tmp" --exclude="storage\videos" --exclude=".env" --exclude="dist" .

# Скопируйте
scp C:\temp\backend.tar.gz admin@192.168.100.222:/tmp/

# На Synology распакуйте
ssh admin@192.168.100.222 "cd /volume1/Hotwell/Backends/shortsai-backend && tar -xzf /tmp/backend.tar.gz && rm /tmp/backend.tar.gz"
```

### 2. Перезапуск backend на Synology

```bash
ssh admin@192.168.100.222 'pm2 restart shortsai-backend'
```

Или подключитесь и выполните:
```bash
ssh admin@192.168.100.222
cd /volume1/Hotwell/Backends/shortsai-backend
pm2 restart shortsai-backend
```

### 3. Просмотр логов

```bash
ssh admin@192.168.100.222 'pm2 logs shortsai-backend'
```

Или последние 50 строк:
```bash
ssh admin@192.168.100.222 'pm2 logs shortsai-backend --lines 50'
```

### 4. Проверка статуса

```bash
ssh admin@192.168.100.222 'pm2 status'
```

### 5. Проверка работы backend

```bash
ssh admin@192.168.100.222 'curl http://localhost:8080/health'
```

Или проверьте через браузер (если доступен):
```
http://192.168.100.222:8080/health
```

### 6. Редактирование .env

```bash
ssh admin@192.168.100.222 'nano /volume1/Hotwell/Backends/shortsai-backend/.env'
```

## ⚙️ Первоначальная настройка (один раз)

Если это первый деплой, выполните на Synology:

```bash
ssh admin@192.168.100.222
cd /volume1/Hotwell/Backends/shortsai-backend

# 1. Установите зависимости
npm install

# 2. Соберите проект
npm run build

# 3. Настройте .env
cp env.example .env
nano .env
# Заполните все необходимые переменные

# 4. Запустите через PM2
pm2 start dist/index.js --name shortsai-backend

# 5. Настройте автозапуск
pm2 save
pm2 startup
# Выполните команду, которую выдаст pm2 startup (обычно с sudo)
```

## 🔧 Устранение проблем

### Backend не запускается
```bash
ssh admin@192.168.100.222 'pm2 logs shortsai-backend --lines 100'
```

### Ошибки при сборке
```bash
ssh admin@192.168.100.222 'cd /volume1/Hotwell/Backends/shortsai-backend && npm run build'
```

### Проблемы с зависимостями
```bash
ssh admin@192.168.100.222 'cd /volume1/Hotwell/Backends/shortsai-backend && rm -rf node_modules && npm install'
```

### PM2 не сохраняет процессы
```bash
ssh admin@192.168.100.222 'cd /volume1/Hotwell/Backends/shortsai-backend && pm2 save && pm2 startup'
```

## 📍 Расположение файлов

- **Код на Synology**: `/volume1/Hotwell/Backends/shortsai-backend`
- **Логи PM2**: `~/.pm2/logs/shortsai-backend-*.log`
- **Конфигурация PM2**: `~/.pm2/dump.pm2`

## 🎯 Типичный workflow

1. **Внесли изменения в код локально**
2. **Обновили код на Synology:**
   ```bash
   cd /c/Users/studo/Downloads/p039-master/p039-master/backend
   bash deploy/deploy_to_synology.sh
   ```
3. **Перезапустили backend:**
   ```bash
   ssh admin@192.168.100.222 'pm2 restart shortsai-backend'
   ```
4. **Проверили работу:**
   ```bash
   ssh admin@192.168.100.222 'curl http://localhost:8080/health'
   ```

---

**Готово!** Backend должен работать на Synology. 🎉




