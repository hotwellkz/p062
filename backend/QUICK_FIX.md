# ⚡ БЫСТРОЕ ИСПРАВЛЕНИЕ

## Проблема найдена и исправлена

**Причина:** В `docker-compose.yml` отсутствовали volumes для монтирования storage на хост.

## Что сделано

✅ Добавлены volumes в `docker-compose.yml`:
```yaml
volumes:
  - ./storage:/app/storage
  - ./tmp:/app/tmp
```

## Команды для применения (выполните на сервере)

```bash
# 1. Загрузить исправленный docker-compose.yml
scp -P 777 backend/docker-compose.yml admin@hotwell.synology.me:/volume1/docker/shortsai/backend/

# 2. Подключиться к серверу
ssh -p 777 admin@hotwell.synology.me

# 3. Перейти в директорию
cd /volume1/docker/shortsai/backend

# 4. Пересобрать и перезапустить
sudo /usr/local/bin/docker compose down
sudo /usr/local/bin/docker compose up -d --build

# 5. Проверить логи
sudo /usr/local/bin/docker compose logs backend --tail=50 | grep -i "storage\|saved"
```

## Проверка результата

После сохранения видео через frontend:

```bash
# Найти все видео файлы
find /volume1/docker/shortsai/backend/storage -type f -name "*.mp4"

# Проверить структуру папок
find /volume1/docker/shortsai/backend/storage -type d | sort
```

Файлы должны быть в:
```
/volume1/docker/shortsai/backend/storage/videos/{userSlug}/{channelSlug}/video.mp4
```





