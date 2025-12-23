# Тест сохранения видео

## ✅ Контейнер запущен успешно!

**Статус:**
- Контейнер: `shorts-backend` - **Up**
- STORAGE_ROOT: `/app/storage/videos` ✅
- Volume примонтирован: `/app/storage` → `./storage` ✅
- Права доступа: `drwxrwxrwx` (777) на папке videos ✅

## Проверка структуры на хосте

Выполните на сервере:

```bash
# Проверить существование папки storage на хосте
ls -la /volume1/docker/shortsai/backend/storage

# Проверить структуру папок
find /volume1/docker/shortsai/backend/storage -type d | sort

# Проверить размер папки
du -sh /volume1/docker/shortsai/backend/storage
```

## Тест сохранения видео

### Шаг 1: Сохраните видео через frontend

1. Откройте frontend в браузере
2. Выберите канал
3. Нажмите "Забрать видео из SyntX на сервер"
4. Дождитесь сообщения "🟢 Видео успешно сохранено на сервер"

### Шаг 2: Проверьте логи контейнера

```bash
sudo /usr/local/bin/docker compose logs backend | grep -i "saved\|storage\|inputDir" | tail -30
```

Ищите строки:
- `[Storage] Video saved to inputDir`
- `downloadAndSaveToLocal: file saved to local storage`
- `inputPath: /app/storage/videos/...`

### Шаг 3: Проверьте файлы на хосте

```bash
# Найти все видео файлы
find /volume1/docker/shortsai/backend/storage -type f -name "*.mp4"

# Проверить структуру папок пользователей
find /volume1/docker/shortsai/backend/storage -type d | sort

# Проверить размер файлов
du -sh /volume1/docker/shortsai/backend/storage/videos/*/*/*.mp4 2>/dev/null

# Список всех файлов
find /volume1/docker/shortsai/backend/storage -type f
```

## Ожидаемый результат

После сохранения видео файл должен появиться по пути:

```
/volume1/docker/shortsai/backend/storage/videos/{userSlug}/{channelSlug}/video.mp4
```

Где:
- `{userSlug}` = email преобразован в slug (например: `hotwell-kz-at-gmail-com`)
- `{channelSlug}` = название канала + ID (например: `shortsairu-2-6akaezfN`)

## Проверка изнутри контейнера

```bash
# Войти в контейнер
sudo /usr/local/bin/docker compose exec backend sh

# Проверить файлы
ls -la /app/storage/videos/
find /app/storage/videos -type f -name "*.mp4"

# Выйти
exit
```

## Если файлы не появляются

### Проверка 1: Права доступа

```bash
# Установить права на папку storage
sudo chmod -R 777 /volume1/docker/shortsai/backend/storage
```

### Проверка 2: Логи ошибок

```bash
sudo /usr/local/bin/docker compose logs backend | grep -i "error\|failed\|permission" | tail -20
```

### Проверка 3: Переменная STORAGE_ROOT

```bash
sudo /usr/local/bin/docker compose exec backend sh -c 'env | grep STORAGE_ROOT'
```

Должно быть: `STORAGE_ROOT=/app/storage/videos`

## Успешный результат

Если всё работает правильно:
- ✅ Видео сохраняется через frontend
- ✅ Файл появляется в `/volume1/docker/shortsai/backend/storage/videos/...`
- ✅ Файл доступен через файловый менеджер Synology
- ✅ Файл сохраняется после перезапуска контейнера





