# Где хранятся видео на сервере

## Текущая ситуация

- ✅ Backend работает на Synology: `https://api.hotwell.synology.me`
- ✅ Сообщение "Видео успешно сохранено на сервер" появляется
- ❌ Папка `storage/videos` не существует или пустая

## Где должны храниться видео

### Структура хранения

По умолчанию видео сохраняются в:
```
/volume1/docker/shortsai/backend/storage/videos/
```

**Структура папок:**
```
storage/videos/
  └── {userSlug}/              # Email пользователя (например: hotwell-kz3-at-gmail-com)
      └── {channelSlug}/       # Название канала + ID (например: shortsairu-2-6akaezfN)
          ├── video.mp4        # Входящие видео для автопубликации
          └── Загруженные - {channelName}/  # Архив опубликованных видео
              └── video.mp4
```

### Путь в контейнере

Внутри Docker контейнера:
```
/app/storage/videos/
```

Это маппится на хост через volume в `docker-compose.yml`:
```yaml
volumes:
  - ./storage:/app/storage
```

## Проверка

### 1. Проверьте логи контейнера

```bash
ssh -p 777 admin@hotwell.synology.me
cd /volume1/docker/shortsai/backend
sudo /usr/local/bin/docker compose logs backend | grep -i "STORAGE_ROOT\|storage\|saved"
```

Должна быть строка при старте:
```
[Storage] Using STORAGE_ROOT: /app/storage/videos
```

### 2. Проверьте папку storage

```bash
ssh -p 777 admin@hotwell.synology.me
cd /volume1/docker/shortsai/backend

# Проверка существования
ls -la storage/

# Создание папки videos, если её нет
mkdir -p storage/videos
chmod 777 storage/videos

# Проверка структуры после сохранения видео
find storage -type f -name "*.mp4" -o -name "*.mov" -o -name "*.avi"
```

### 3. Проверьте переменную STORAGE_ROOT

```bash
ssh -p 777 admin@hotwell.synology.me
cd /volume1/docker/shortsai/backend

# Проверка в .env.production
grep STORAGE_ROOT .env.production

# Если не установлена, добавьте:
echo "STORAGE_ROOT=/app/storage/videos" >> .env.production

# Перезапустите контейнер
sudo /usr/local/bin/docker compose restart
```

## Возможные проблемы

### Проблема 1: Папка не создается автоматически

**Решение:** Создайте папку вручную:
```bash
ssh -p 777 admin@hotwell.synology.me
cd /volume1/docker/shortsai/backend
mkdir -p storage/videos
chmod 777 storage/videos
```

### Проблема 2: Нет прав на запись

**Решение:** Проверьте права:
```bash
ssh -p 777 admin@hotwell.synology.me
cd /volume1/docker/shortsai/backend
ls -la storage/
chmod 777 storage/
chmod 777 storage/videos/
```

### Проблема 3: Видео сохраняются в другую папку

**Решение:** Проверьте логи при сохранении видео:
```bash
ssh -p 777 admin@hotwell.synology.me
cd /volume1/docker/shortsai/backend
sudo /usr/local/bin/docker compose logs -f backend
```

Затем попробуйте сохранить видео через фронтенд и посмотрите, какой путь выводится в логах.

## Поиск видео на сервере

### Вариант 1: Через SSH

```bash
ssh -p 777 admin@hotwell.synology.me

# Поиск всех видео файлов
find /volume1/docker/shortsai/backend -type f \( -name "*.mp4" -o -name "*.mov" -o -name "*.avi" \)

# Поиск в storage
find /volume1/docker/shortsai/backend/storage -type f -name "*.mp4"
```

### Вариант 2: Через File Station (Synology)

1. Откройте **File Station** в DSM
2. Перейдите в `/volume1/docker/shortsai/backend/storage/`
3. Проверьте папку `videos/`
4. Ищите папки с email пользователей (например: `hotwell-kz3-at-gmail-com`)

### Вариант 3: Через контейнер

```bash
ssh -p 777 admin@hotwell.synology.me
sudo /usr/local/bin/docker compose exec backend ls -la /app/storage/videos/
```

## Структура папок по пользователям

Видео сохраняются в структуре:
```
storage/videos/
  └── {userSlug}/              # Email преобразован в slug
      └── {channelSlug}/       # Название канала + ID канала
          └── video.mp4
```

**Пример:**
- Email: `hotwell.kz3@gmail.com` → slug: `hotwell-kz3-at-gmail-com`
- Канал: `ShortsAI RU` (ID: `6akaezfN`) → slug: `shortsairu-2-6akaezfN`
- Путь: `storage/videos/hotwell-kz3-at-gmail-com/shortsairu-2-6akaezfN/video.mp4`

## Настройка STORAGE_ROOT

Если хотите изменить путь хранения:

1. Отредактируйте `.env.production`:
```bash
ssh -p 777 admin@hotwell.synology.me
cd /volume1/docker/shortsai/backend
nano .env.production
```

2. Добавьте:
```
STORAGE_ROOT=/app/storage/videos
```

3. Обновите `docker-compose.yml` для нового пути (если нужно):
```yaml
volumes:
  - /volume1/videos:/app/storage/videos  # Пример: внешняя папка
```

4. Перезапустите контейнер:
```bash
sudo /usr/local/bin/docker compose restart
```

## Проверка после сохранения видео

После сохранения видео через фронтенд:

1. Проверьте логи:
```bash
sudo /usr/local/bin/docker compose logs backend | tail -50
```

2. Найдите строки с:
   - `downloadAndSaveToLocal`
   - `saving file to local storage`
   - `file saved successfully`

3. В логах должен быть указан полный путь к сохраненному файлу

## Полезные команды

```bash
# Размер папки storage
du -sh /volume1/docker/shortsai/backend/storage/

# Количество видео файлов
find /volume1/docker/shortsai/backend/storage -type f -name "*.mp4" | wc -l

# Список всех видео с размерами
find /volume1/docker/shortsai/backend/storage -type f -name "*.mp4" -exec ls -lh {} \;
```





