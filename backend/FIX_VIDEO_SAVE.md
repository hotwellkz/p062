# 🔧 ИСПРАВЛЕНИЕ ПРОБЛЕМЫ СОХРАНЕНИЯ ВИДЕО

## ✅ ИСПРАВЛЕНИЕ ВЫПОЛНЕНО

### Изменения в `docker-compose.yml`:

Добавлена секция `volumes:` для монтирования storage на хост:

```yaml
volumes:
  - ./storage:/app/storage
  - ./tmp:/app/tmp
```

## 📋 КОМАНДЫ ДЛЯ ПРИМЕНЕНИЯ ИСПРАВЛЕНИЯ

### Шаг 1: Загрузить обновлённый docker-compose.yml на сервер

```bash
# Из локальной машины (Windows PowerShell)
scp -P 777 backend/docker-compose.yml admin@hotwell.synology.me:/volume1/docker/shortsai/backend/
```

### Шаг 2: Пересобрать и перезапустить контейнер

```bash
# Подключиться к серверу
ssh -p 777 admin@hotwell.synology.me

# Перейти в директорию проекта
cd /volume1/docker/shortsai/backend

# Остановить контейнер
sudo /usr/local/bin/docker compose down

# Пересобрать и запустить
sudo /usr/local/bin/docker compose up -d --build

# Проверить логи
sudo /usr/local/bin/docker compose logs backend --tail=50
```

### Шаг 3: Проверить монтирование volumes

```bash
# Проверить, что volumes примонтированы
sudo /usr/local/bin/docker compose exec backend sh -c "ls -la /app/storage"

# Проверить переменную STORAGE_ROOT
sudo /usr/local/bin/docker compose exec backend sh -c "env | grep STORAGE_ROOT"

# Проверить структуру папок на хосте
ls -la /volume1/docker/shortsai/backend/storage/
```

### Шаг 4: Проверить сохранение видео

1. Сохраните тестовое видео через frontend
2. Проверьте логи:
   ```bash
   sudo /usr/local/bin/docker compose logs backend | grep -i "saved\|storage\|inputDir" | tail -20
   ```
3. Проверьте файлы на хосте:
   ```bash
   find /volume1/docker/shortsai/backend/storage -type f -name "*.mp4"
   ```

## 🔍 ПРОВЕРКА РЕЗУЛЬТАТА

### Ожидаемый результат:

1. **В логах контейнера:**
   ```
   [Storage] Video saved to inputDir {
     filePath: '/app/storage/videos/hotwell-kz-at-gmail-com/shortsairu-2-6akaezfN/video.mp4'
   }
   ```

2. **На хосте (Synology NAS):**
   ```bash
   /volume1/docker/shortsai/backend/storage/videos/hotwell-kz-at-gmail-com/shortsairu-2-6akaezfN/video.mp4
   ```

3. **Файл должен быть доступен:**
   - После перезапуска контейнера
   - Через файловый менеджер Synology
   - Через SSH

## ⚠️ ВОЗМОЖНЫЕ ПРОБЛЕМЫ

### Проблема 1: Права доступа

Если файлы не видны на хосте, проверьте права:

```bash
# Установить права на папку storage
sudo chmod -R 777 /volume1/docker/shortsai/backend/storage
```

### Проблема 2: STORAGE_ROOT не совпадает

Убедитесь, что в `.env.production` установлен:

```bash
STORAGE_ROOT=/app/storage/videos
```

### Проблема 3: Папки не создаются

Проверьте логи создания папок:

```bash
sudo /usr/local/bin/docker compose logs backend | grep -i "mkdir\|directory\|storage"
```

## 📝 ДОПОЛНИТЕЛЬНЫЕ РЕКОМЕНДАЦИИ

1. **Использовать абсолютные пути в production:**
   ```yaml
   volumes:
     - /volume1/docker/shortsai/backend/storage:/app/storage:rw
   ```

2. **Добавить healthcheck:**
   ```yaml
   healthcheck:
     test: ["CMD", "sh", "-c", "test -d /app/storage && test -w /app/storage"]
     interval: 30s
     timeout: 10s
     retries: 3
   ```

3. **Логировать STORAGE_ROOT при старте** (уже реализовано в коде)





