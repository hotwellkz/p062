# Исправление падения контейнера

## Проблема
Контейнер постоянно перезапускается (Restarting). Причина: использование async/await с динамическим импортом в функции getContainerId().

## Исправление
Заменено на синхронную версию с require("fs").

## Команды для обновления на Synology

В SSH сессии на Synology:

```bash
cd /volume1/docker/shortsai/backend

# 1. Остановить контейнер
sudo docker compose stop backend

# 2. Загрузить обновленный index.ts
# (скопировать содержимое backend/src/index.ts локально)

# 3. Пересобрать
sudo docker compose build --no-cache backend

# 4. Запустить
sudo docker compose up -d backend

# 5. Проверить логи (должен запуститься без ошибок)
sleep 5
sudo docker logs shorts-backend --tail 50

# 6. Проверить статус
sudo docker ps | grep shorts-backend
```

## Ожидаемый результат
- Контейнер должен запуститься и остаться в статусе "Up"
- В логах должно быть: "Backend listening on port 3000"
- Endpoint /health должен работать

