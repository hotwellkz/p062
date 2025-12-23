# Проверка сохранения видео

## Проблема

Сообщение "Видео успешно сохранено на сервер" появляется, но папка `storage/videos` пустая.

## Решение

Видео сохраняются в структуру: `storage/videos/{userSlug}/{channelSlug}/video.mp4`

### Шаг 1: Проверка структуры папок

Выполните через SSH:

```bash
ssh -p 777 admin@hotwell.synology.me
cd /volume1/docker/shortsai/backend

# Проверка всей структуры storage (включая вложенные папки)
find storage -type d | sort

# Поиск всех файлов в storage
find storage -type f

# Поиск видео файлов
find storage -type f \( -name "*.mp4" -o -name "*.mov" -o -name "*.avi" \)
```

### Шаг 2: Проверка через контейнер

```bash
# Войдите в контейнер
sudo /usr/local/bin/docker compose exec backend sh

# Проверьте переменную STORAGE_ROOT
env | grep STORAGE_ROOT

# Проверьте папку
ls -la /app/storage/videos/

# Проверьте структуру папок пользователей
ls -la /app/storage/videos/*/

# Выйдите
exit
```

### Шаг 3: Проверка логов при сохранении

Сохраните видео через фронтенд и сразу проверьте логи:

```bash
sudo /usr/local/bin/docker compose logs backend | grep -i "saved\|storage\|inputDir\|Video saved" | tail -30
```

Ищите строки с:
- `Video saved to inputDir`
- `file saved to local storage`
- `inputPath`
- `filePath`

### Шаг 4: Проверка ответа API

В браузере откройте консоль (F12 → Network):
1. Сохраните видео
2. Найдите запрос к `/api/telegram/fetchAndSaveToServer`
3. Проверьте ответ - там должен быть `inputPath` и `storage.inputDir`
4. Скопируйте эти пути и проверьте их на сервере

### Шаг 5: Проверка прав доступа

```bash
cd /volume1/docker/shortsai/backend

# Проверка прав
ls -la storage/
ls -la storage/videos/

# Установка прав (если нужно)
chmod 777 storage/
chmod 777 storage/videos/
```

## Возможные причины

1. **Видео сохраняются в структуру userSlug/channelSlug** - проверьте вложенные папки
2. **Ошибка при сохранении** - проверьте логи контейнера
3. **Неправильный STORAGE_ROOT** - проверьте переменную в контейнере
4. **Нет прав на запись** - проверьте права доступа к папке

## Быстрая проверка

Выполните все команды из Шага 1 и пришлите результат - помогу найти, где сохраняются видео.





