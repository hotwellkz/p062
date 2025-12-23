# Как найти сохраненные видео на сервере

## Где хранятся видео

### Основной путь

**На Synology сервере:**
```
/volume1/docker/shortsai/backend/storage/videos/
```

**В Docker контейнере:**
```
/app/storage/videos/
```

### Структура папок

Видео сохраняются в следующей структуре:

```
storage/videos/
  └── {userSlug}/                    # Email пользователя преобразован в slug
      └── {channelSlug}/             # Название канала + ID канала
          ├── video.mp4              # Входящие видео для автопубликации
          └── Загруженные - {channelName}/  # Архив опубликованных видео
              └── video.mp4
```

**Пример:**
- Email: `hotwell.kz3@gmail.com` → slug: `hotwell-kz3-at-gmail-com`
- Канал: `ShortsAI RU` (ID: `6akaezfN`) → slug: `shortsairu-2-6akaezfN`
- **Полный путь:** `storage/videos/hotwell-kz3-at-gmail-com/shortsairu-2-6akaezfN/video.mp4`

## Как найти видео

### Способ 1: Через SSH (командная строка)

```bash
ssh -p 777 admin@hotwell.synology.me

# Перейти в папку backend
cd /volume1/docker/shortsai/backend

# Найти все видео файлы
find storage/videos -type f -name "*.mp4" -o -name "*.mov" -o -name "*.avi"

# Показать структуру папок
find storage/videos -type d | sort

# Показать все файлы с размерами
find storage/videos -type f -exec ls -lh {} \;
```

### Способ 2: Через File Station (Synology DSM)

1. Откройте **File Station** в DSM
2. Перейдите в `/volume1/docker/shortsai/backend/storage/videos/`
3. Найдите папку с вашим email (например: `hotwell-kz3-at-gmail-com`)
4. Войдите в папку канала (например: `shortsairu-2-6akaezfN`)
5. Там должны быть видео файлы

### Способ 3: Через Docker контейнер

```bash
ssh -p 777 admin@hotwell.synology.me
cd /volume1/docker/shortsai/backend

# Войти в контейнер
sudo /usr/local/bin/docker compose exec backend sh

# Внутри контейнера
ls -la /app/storage/videos/
find /app/storage/videos -type f -name "*.mp4"
```

## Проверка после сохранения видео

После того, как вы сохранили видео через фронтенд:

1. **Подождите несколько секунд** (файл должен загрузиться)

2. **Проверьте через SSH:**
```bash
ssh -p 777 admin@hotwell.synology.me
cd /volume1/docker/shortsai/backend

# Найти все видео файлы
find storage/videos -type f \( -name "*.mp4" -o -name "*.mov" -o -name "*.avi" \)

# Показать структуру
tree storage/videos/  # если установлен tree
# или
find storage/videos -type d | sort
```

3. **Проверьте логи контейнера:**
```bash
sudo /usr/local/bin/docker compose logs backend | grep -i "saved\|saving\|storage"
```

В логах должен быть указан полный путь к сохраненному файлу.

## Если видео не находятся

### Проверка 1: Папка существует?

```bash
ls -la /volume1/docker/shortsai/backend/storage/videos/
```

Если папки нет, создайте:
```bash
mkdir -p /volume1/docker/shortsai/backend/storage/videos
chmod 777 /volume1/docker/shortsai/backend/storage/videos
```

### Проверка 2: Права доступа

```bash
ls -la /volume1/docker/shortsai/backend/storage/
chmod 777 /volume1/docker/shortsai/backend/storage/
chmod 777 /volume1/docker/shortsai/backend/storage/videos/
```

### Проверка 3: Логи контейнера

```bash
sudo /usr/local/bin/docker compose logs backend | tail -100
```

Ищите строки с:
- `downloadAndSaveToLocal`
- `saving file to local storage`
- `file saved successfully`
- `STORAGE_ROOT`

### Проверка 4: Поиск по всему серверу

Если видео не в ожидаемой папке, поищите по всему серверу:

```bash
# Поиск всех видео файлов
find /volume1 -type f \( -name "*.mp4" -o -name "*.mov" -o -name "*.avi" \) 2>/dev/null

# Поиск в папке docker
find /volume1/docker -type f \( -name "*.mp4" -o -name "*.mov" -o -name "*.avi" \) 2>/dev/null
```

## Структура по пользователям

Каждый пользователь имеет свою папку, основанную на email:

- `user@example.com` → `user-at-example-com`
- `hotwell.kz3@gmail.com` → `hotwell-kz3-at-gmail-com`

Внутри папки пользователя находятся папки каналов:

- Канал `ShortsAI RU` (ID: `6akaezfN`) → `shortsairu-2-6akaezfN`

## Полезные команды

```bash
# Размер папки storage
du -sh /volume1/docker/shortsai/backend/storage/

# Количество видео файлов
find /volume1/docker/shortsai/backend/storage -type f -name "*.mp4" | wc -l

# Список всех видео с размерами и датами
find /volume1/docker/shortsai/backend/storage -type f -name "*.mp4" -exec ls -lh {} \; | sort -k6,7

# Последние сохраненные видео
find /volume1/docker/shortsai/backend/storage -type f -name "*.mp4" -exec ls -lt {} \; | head -10
```

## Доступ через веб-интерфейс

Видео доступны через API endpoint:

```
https://api.hotwell.synology.me/api/media/{userSlug}/{channelSlug}/{fileName}
```

Пример:
```
https://api.hotwell.synology.me/api/media/hotwell-kz3-at-gmail-com/shortsairu-2-6akaezfN/video.mp4
```





