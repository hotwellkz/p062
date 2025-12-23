# Пересборка Docker контейнера на Synology NAS

## Выполните эти команды на сервере

Подключитесь к серверу и выполните команды:

```bash
ssh -p 777 admin@hotwell.synology.me
cd /volume1/docker/shortsai/backend

# 1. Остановить текущий контейнер
sudo /usr/local/bin/docker compose down

# 2. Пересобрать контейнер с новыми изменениями
sudo /usr/local/bin/docker compose build --no-cache

# 3. Запустить контейнер
sudo /usr/local/bin/docker compose up -d

# 4. Проверить статус
sudo /usr/local/bin/docker compose ps

# 5. Проверить логи (последние 100 строк)
sudo /usr/local/bin/docker compose logs --tail=100
```

## Или одной командой:

```bash
ssh -p 777 admin@hotwell.synology.me "cd /volume1/docker/shortsai/backend && sudo /usr/local/bin/docker compose down && sudo /usr/local/bin/docker compose build --no-cache && sudo /usr/local/bin/docker compose up -d && sudo /usr/local/bin/docker compose ps"
```

## Проверка после пересборки

```bash
# Проверить что контейнер запущен
sudo /usr/local/bin/docker compose ps

# Проверить логи на наличие ошибок
sudo /usr/local/bin/docker compose logs --tail=50 | grep -i error

# Проверить что сервер отвечает
curl http://localhost:7777/health
```

## Что изменилось

После пересборки автоматизация будет:
- ✅ Сохранять видео в локальное хранилище `storage/videos`
- ✅ Логировать все этапы скачивания
- ✅ Использовать правильный `STORAGE_ROOT` из env переменных





