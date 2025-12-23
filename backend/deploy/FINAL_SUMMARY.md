# 📋 ФИНАЛЬНАЯ СВОДКА: Деплой ShortsAI Backend на Synology

## ✅ Что готово

1. ✅ **Скрипт деплоя кода**: `backend/deploy/deploy_to_synology.sh`
2. ✅ **Полный автоматический деплой**: `backend/deploy/full_synology_deploy.sh`
3. ✅ **Документация**: Полные инструкции созданы

## 🚀 Как запустить деплой

### Вариант 1: Полный автоматический деплой (рекомендуется)

**В Git Bash:**
```bash
cd /c/Users/studo/Downloads/p039-master/p039-master/backend
bash deploy/full_synology_deploy.sh
```

Этот скрипт выполнит ВСЁ автоматически.

### Вариант 2: Только обновление кода

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

---

## 📝 Полезные команды

### 1. Обновление кода на Synology

**С локального компьютера (Git Bash):**
```bash
cd /c/Users/studo/Downloads/p039-master/p039-master/backend
bash deploy/deploy_to_synology.sh
```

**Что делает:**
- Копирует все файлы проекта (кроме node_modules, .git, tmp, storage/videos)
- Использует rsync (если доступен) или scp
- Сохраняет существующие .env и node_modules

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
# Все логи
ssh admin@192.168.100.222 'pm2 logs shortsai-backend'

# Последние 50 строк
ssh admin@192.168.100.222 'pm2 logs shortsai-backend --lines 50'

# Логи в реальном времени
ssh admin@192.168.100.222 'pm2 logs shortsai-backend --lines 0'
```

### 4. Проверка статуса

```bash
ssh admin@192.168.100.222 'pm2 status'
```

Покажет:
- Статус процесса (online/stopped)
- Использование CPU и памяти
- Время работы

### 5. Проверка работы backend

```bash
# Health endpoint
ssh admin@192.168.100.222 'curl http://localhost:8080/health'

# Или через браузер (если доступен)
http://192.168.100.222:8080/health
```

### 6. Редактирование .env

```bash
ssh admin@192.168.100.222 'nano /volume1/Hotwell/Backends/shortsai-backend/.env'
```

Или через scp:
```bash
# Скачать .env
scp admin@192.168.100.222:/volume1/Hotwell/Backends/shortsai-backend/.env .env.local

# Отредактировать локально, затем загрузить обратно
scp .env.local admin@192.168.100.222:/volume1/Hotwell/Backends/shortsai-backend/.env
```

---

## 🔧 Устранение проблем

### Backend не запускается

```bash
# Проверьте логи
ssh admin@192.168.100.222 'pm2 logs shortsai-backend --lines 100'

# Проверьте .env
ssh admin@192.168.100.222 'cat /volume1/Hotwell/Backends/shortsai-backend/.env | grep -v "^#" | grep -v "^$"'

# Проверьте, что dist/index.js существует
ssh admin@192.168.100.222 'ls -la /volume1/Hotwell/Backends/shortsai-backend/dist/index.js'
```

### Ошибки при сборке

```bash
ssh admin@192.168.100.222 'cd /volume1/Hotwell/Backends/shortsai-backend && npm run build'
```

### Проблемы с зависимостями

```bash
ssh admin@192.168.100.222 'cd /volume1/Hotwell/Backends/shortsai-backend && rm -rf node_modules && npm install'
```

### PM2 не сохраняет процессы после перезагрузки

```bash
ssh admin@192.168.100.222 'cd /volume1/Hotwell/Backends/shortsai-backend && pm2 save && pm2 startup'
# Выполните команду, которую выдаст pm2 startup (обычно с sudo)
```

### Backend не отвечает на health endpoint

```bash
# Проверьте, что процесс запущен
ssh admin@192.168.100.222 'pm2 status'

# Проверьте порт
ssh admin@192.168.100.222 'netstat -tlnp | grep 8080'

# Проверьте логи на ошибки
ssh admin@192.168.100.222 'pm2 logs shortsai-backend --err --lines 50'
```

---

## 📍 Расположение файлов

- **Код на Synology**: `/volume1/Hotwell/Backends/shortsai-backend`
- **Логи PM2**: `~/.pm2/logs/shortsai-backend-*.log`
- **Конфигурация PM2**: `~/.pm2/dump.pm2`
- **Хранилище видео**: `/volume1/Hotwell/Backends/shortsai-backend/storage/videos`

---

## 🎯 Типичный workflow

### После изменения кода:

1. **Обновите код на Synology:**
   ```bash
   cd /c/Users/studo/Downloads/p039-master/p039-master/backend
   bash deploy/deploy_to_synology.sh
   ```

2. **Перезапустите backend:**
   ```bash
   ssh admin@192.168.100.222 'pm2 restart shortsai-backend'
   ```

3. **Проверьте работу:**
   ```bash
   ssh admin@192.168.100.222 'curl http://localhost:8080/health'
   ```

### После изменения .env:

1. **Отредактируйте .env на Synology:**
   ```bash
   ssh admin@192.168.100.222 'nano /volume1/Hotwell/Backends/shortsai-backend/.env'
   ```

2. **Перезапустите backend:**
   ```bash
   ssh admin@192.168.100.222 'pm2 restart shortsai-backend'
   ```

---

## 📚 Документация

- **Быстрый старт**: `backend/deploy/QUICK_DEPLOY_GUIDE.md`
- **Полная инструкция**: `backend/deploy/DEPLOY_SYNOLOGY_FINAL.md`
- **Запуск сейчас**: `backend/deploy/RUN_DEPLOY_NOW.md`

---

## ✅ Готово к использованию!

Запустите деплой командой:
```bash
cd /c/Users/studo/Downloads/p039-master/p039-master/backend
bash deploy/full_synology_deploy.sh
```

После деплоя настройте `.env` и перезапустите backend. 🚀




