# Диагностика проблемы сохранения видео

## Проблема

Сообщение "Видео успешно сохранено на сервер" появляется, но папка `storage/videos` пустая.

## Возможные причины

1. **Файл сохраняется, но в другую структуру папок** (userSlug/channelSlug)
2. **Ошибка при сохранении**, но она не отображается в ответе
3. **Неправильный STORAGE_ROOT** или путь не маппится на хост

## Диагностика

### Шаг 1: Проверка структуры папок

```bash
ssh -p 777 admin@hotwell.synology.me
cd /volume1/docker/shortsai/backend

# Проверка всей структуры storage
find storage -type d -o -type f | sort

# Поиск всех файлов
find storage -type f

# Проверка размера
du -sh storage/
```

### Шаг 2: Проверка логов контейнера

```bash
# Войдите в контейнер и проверьте логи
sudo /usr/local/bin/docker compose exec backend sh

# Внутри контейнера проверьте STORAGE_ROOT
echo $STORAGE_ROOT

# Проверьте существование папки
ls -la /app/storage/videos/

# Проверьте права доступа
ls -la /app/storage/
```

### Шаг 3: Проверка логов при сохранении

Сохраните видео через фронтенд и сразу проверьте логи:

```bash
sudo /usr/local/bin/docker compose logs backend -f
```

Ищите строки:
- `Video saved to inputDir`
- `file saved to local storage`
- `inputPath`
- `filePath`
- `error` или `Error`

### Шаг 4: Проверка переменной STORAGE_ROOT

```bash
cd /volume1/docker/shortsai/backend
grep STORAGE_ROOT .env.production

# Должно быть: STORAGE_ROOT=/app/storage/videos
```

### Шаг 5: Проверка volume маппинга

```bash
cat docker-compose.yml | grep -A 3 volumes

# Должно быть:
# volumes:
#   - ./storage:/app/storage
#   - ./tmp:/app/tmp
```

## Решение

### Вариант 1: Проверка структуры папок пользователя

Видео могут сохраняться в структуру:
```
storage/videos/{userSlug}/{channelSlug}/video.mp4
```

Проверьте:
```bash
find storage/videos -type f -name "*.mp4"
```

### Вариант 2: Проверка прав доступа

Убедитесь, что контейнер может писать в папку:
```bash
chmod 777 storage/
chmod 777 storage/videos/
```

### Вариант 3: Проверка через контейнер

Войдите в контейнер и проверьте:
```bash
sudo /usr/local/bin/docker compose exec backend sh

# Проверьте переменную
env | grep STORAGE_ROOT

# Проверьте папку
ls -la /app/storage/videos/

# Попробуйте создать тестовый файл
echo "test" > /app/storage/videos/test.txt
ls -la /app/storage/videos/test.txt

# Выйдите из контейнера
exit

# Проверьте на хосте
ls -la storage/videos/test.txt
```

Если тестовый файл создается, значит проблема в коде сохранения видео.

## Проверка ответа API

Когда вы сохраняете видео, проверьте ответ API в консоли браузера (F12 → Network). Должен быть ответ с полями:
- `inputPath` - путь к сохраненному файлу
- `storage.inputDir` - папка для входящих файлов
- `storage.filePath` - полный путь к файлу

Скопируйте эти пути и проверьте их на сервере.

## Полезные команды

```bash
# Поиск всех видео файлов на сервере
find /volume1/docker/shortsai/backend -type f \( -name "*.mp4" -o -name "*.mov" -o -name "*.avi" \)

# Проверка последних изменений в storage
find /volume1/docker/shortsai/backend/storage -type f -mtime -1

# Мониторинг логов в реальном времени
sudo /usr/local/bin/docker compose logs -f backend
```





