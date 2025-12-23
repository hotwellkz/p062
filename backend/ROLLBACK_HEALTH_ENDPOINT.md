# Откат /health endpoint к простой версии

## Проблема
Контейнер падает при запуске. Возможно, проблема в диагностическом коде.

## Решение
Временно откатил /health endpoint к простой версии, которая точно работает.

## Что нужно сделать на Synology

В SSH сессии:

```bash
cd /volume1/docker/shortsai/backend

# 1. Загрузить обновленный index.ts (простая версия /health)
# Скопировать содержимое backend/src/index.ts из локального проекта

# 2. Пересобрать
sudo docker compose build --no-cache backend

# 3. Запустить
sudo docker compose up -d backend

# 4. Проверить
sleep 5
sudo docker ps | grep shorts-backend
sudo docker logs shorts-backend --tail 30
```

## После успешного запуска

Когда контейнер запустится, можно будет:
1. Проверить доступность backend
2. Протестировать endpoint /api/telegram/fetchAndSaveToServer
3. Позже добавить диагностику в /health более безопасным способом

