# Следующие шаги после создания docker-compose.yml

## ✅ Файл создан успешно!

Теперь выполните на сервере следующие команды:

## 1. Проверка файла

```bash
cat docker-compose.yml | grep -A 2 volumes
```

Должно показать:
```yaml
    volumes:
      - ./storage:/app/storage
      - ./tmp:/app/tmp
```

## 2. Перезапуск контейнера

```bash
sudo /usr/local/bin/docker compose down
sudo /usr/local/bin/docker compose up -d --build
```

## 3. Проверка volumes

```bash
# Проверка монтирования storage
sudo /usr/local/bin/docker compose exec backend sh -c 'ls -la /app/storage'

# Проверка переменной STORAGE_ROOT
sudo /usr/local/bin/docker compose exec backend sh -c 'env | grep STORAGE_ROOT'
```

## 4. Проверка логов

```bash
sudo /usr/local/bin/docker compose logs backend --tail=50 | grep -i "storage\|saved"
```

Ищите строки:
- `[Storage] Using STORAGE_ROOT: /app/storage/videos`
- `[Storage] Video saved to inputDir`

## 5. Тест сохранения видео

1. Сохраните тестовое видео через frontend
2. Проверьте файлы на хосте:

```bash
# Найти все видео файлы
find /volume1/docker/shortsai/backend/storage -type f -name "*.mp4"

# Проверить структуру папок
find /volume1/docker/shortsai/backend/storage -type d | sort

# Проверить размер папки
du -sh /volume1/docker/shortsai/backend/storage
```

## 6. Проверка прав доступа (если нужно)

Если файлы не видны на хосте:

```bash
sudo chmod -R 777 /volume1/docker/shortsai/backend/storage
```

## Ожидаемый результат

После сохранения видео файл должен быть доступен по пути:

```
/volume1/docker/shortsai/backend/storage/videos/{userSlug}/{channelSlug}/video.mp4
```

Где:
- `{userSlug}` = email преобразован в slug (например: `hotwell-kz-at-gmail-com`)
- `{channelSlug}` = название канала + ID (например: `shortsairu-2-6akaezfN`)





