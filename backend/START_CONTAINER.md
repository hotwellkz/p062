# Запуск контейнера после добавления volumes

## ✅ Volumes настроены правильно!

Файл `docker-compose.yml` содержит:
```yaml
volumes:
  - ./storage:/app/storage
  - ./tmp:/app/tmp
```

## Запуск контейнера

Выполните на сервере:

```bash
sudo /usr/local/bin/docker compose up -d --build
```

Эта команда:
- Соберёт образ заново (если нужно)
- Запустит контейнер в фоновом режиме
- Применит новые volumes

## Проверка запуска

```bash
# Проверить статус контейнера
sudo /usr/local/bin/docker compose ps

# Должно показать:
# NAME              STATUS
# shorts-backend    Up
```

## Проверка volumes

```bash
# Проверить монтирование storage
sudo /usr/local/bin/docker compose exec backend sh -c 'ls -la /app/storage'

# Проверить переменную STORAGE_ROOT
sudo /usr/local/bin/docker compose exec backend sh -c 'env | grep STORAGE_ROOT'

# Проверить логи при старте
sudo /usr/local/bin/docker compose logs backend --tail=50 | grep -i "storage\|STORAGE_ROOT"
```

Ищите в логах:
```
[Storage] Using STORAGE_ROOT: /app/storage/videos
```

## Проверка структуры папок на хосте

```bash
# Проверить существование папки storage
ls -la /volume1/docker/shortsai/backend/storage

# Создать папку videos, если её нет
mkdir -p /volume1/docker/shortsai/backend/storage/videos
chmod 777 /volume1/docker/shortsai/backend/storage/videos
```

## Тест сохранения видео

После запуска контейнера:

1. Сохраните тестовое видео через frontend
2. Проверьте логи:
   ```bash
   sudo /usr/local/bin/docker compose logs backend | grep -i "saved\|storage\|inputDir" | tail -20
   ```
3. Проверьте файлы на хосте:
   ```bash
   find /volume1/docker/shortsai/backend/storage -type f -name "*.mp4"
   find /volume1/docker/shortsai/backend/storage -type d | sort
   ```

## Ожидаемый результат

После сохранения видео файл должен быть доступен по пути:

```
/volume1/docker/shortsai/backend/storage/videos/{userSlug}/{channelSlug}/video.mp4
```

Где:
- `{userSlug}` = email преобразован в slug (например: `hotwell-kz-at-gmail-com`)
- `{channelSlug}` = название канала + ID (например: `shortsairu-2-6akaezfN`)





