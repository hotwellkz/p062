# Финальная пересборка и тестирование

## ✅ Файл обновлен на Synology

Debug логи видны в файле - файл успешно загружен.

## Команды для выполнения в SSH сессии на Synology

```bash
cd /volume1/docker/shortsai/backend

# 1. Пересобрать контейнер
sudo docker compose build --no-cache backend

# 2. Запустить с debug логами (должны появиться debug сообщения)
sudo docker compose run --rm backend sh -c "PORT=3000 node dist/index.js 2>&1"

# 3. Если видны debug логи и приложение запускается - запустить в фоне
sudo docker compose up -d backend

# 4. Проверить статус (должен быть "Up", не "Restarting")
sleep 5
sudo docker ps | grep shorts-backend

# 5. Проверить логи
sudo docker logs shorts-backend --tail 50

# 6. Проверить доступность локально
curl -i http://localhost:3000/health
```

## Ожидаемый результат

После пересборки должны появиться debug логи:
- `[DEBUG] Starting backend application...`
- `[DEBUG] dotenv loaded, PORT: 3000`
- `[DEBUG] Logger imported`
- `[DEBUG] Firebase Admin imported`
- `[DEBUG] About to start server on port: 3000`
- `Backend listening on port 3000 (0.0.0.0)`

Если все эти логи появляются - контейнер должен запуститься успешно.

## После успешного запуска

Проверить доступность:
- Локально на Synology: `curl -i http://localhost:3000/health`
- Через WireGuard с VPS: `curl -i http://10.9.0.2:3000/health`
- Через публичный домен: `curl -i https://api.shortsai.ru/health`

