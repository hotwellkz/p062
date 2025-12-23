# Диагностика и исправление 404 для /api/telegram/fetchAndSaveToServer

## Проблема
POST `https://api.shortsai.ru/api/telegram/fetchAndSaveToServer` возвращает 404 Not Found.

## Анализ
1. ✅ Nginx конфиг правильный: `proxy_pass http://10.9.0.2:3000;` (без слэша - путь сохраняется)
2. ✅ Код содержит маршрут: `router.post("/fetchAndSaveToServer", ...)` в `telegramRoutes.ts`
3. ✅ Маршрут подключен: `app.use("/api/telegram", telegramRoutes)` в `index.ts`
4. ⚠️ Возможная причина: старый код в контейнере или проблема с монтированием volume

## Шаги исправления

### 1. Проверка текущего состояния на Synology

Выполните на Synology (через SSH или DSM Terminal):

```bash
# Проверить логи контейнера
sudo docker logs shorts-backend --tail 100 | grep -E "INCOMING|fetchAndSaveToServer|routes registered|listening"

# Проверить, что контейнер запущен
sudo docker ps | grep shorts-backend

# Проверить, что файл index.ts обновлен
sudo cat /volume1/docker/shortsai/backend/src/index.ts | grep -A 5 "INCOMING REQUEST"
```

### 2. Пересборка контейнера

```bash
cd /volume1/docker/shortsai
sudo docker compose build --no-cache shorts-backend
sudo docker compose up -d shorts-backend
```

### 3. Проверка логов после перезапуска

```bash
# Дождаться запуска (5-10 секунд)
sleep 5

# Проверить логи запуска
sudo docker logs shorts-backend --tail 50 | grep -E "routes registered|listening|INCOMING"

# Сделать тестовый запрос
curl -i -X POST https://api.shortsai.ru/api/telegram/fetchAndSaveToServer \
  -H "Content-Type: application/json" \
  -d '{"channelId":"test"}'

# Проверить логи после запроса
sudo docker logs shorts-backend --tail 20 | grep -E "INCOMING|fetchAndSaveToServer"
```

### 4. Ожидаемый результат

После исправления в логах должно появиться:
```
INCOMING REQUEST { method: 'POST', originalUrl: '/api/telegram/fetchAndSaveToServer', ... }
fetchAndSaveToServer: REQUEST RECEIVED { ... }
```

И запрос должен вернуть **НЕ 404** (может быть 401 без токена или 400 с ошибкой валидации, но не 404).

## Альтернативная проверка: прямое подключение к контейнеру

Если проблема сохраняется, проверьте маршруты внутри контейнера:

```bash
# Войти в контейнер
sudo docker exec -it shorts-backend sh

# Проверить файл index.ts
cat /app/src/index.ts | grep -A 5 "INCOMING REQUEST"

# Проверить скомпилированный код
cat /app/dist/index.js | grep -A 3 "INCOMING"

# Выйти
exit
```

## Если проблема в Dockerfile

Проверьте, что Dockerfile копирует исходники правильно:

```bash
# На Synology проверьте Dockerfile
cat /volume1/docker/shortsai/backend/Dockerfile | grep -E "COPY|WORKDIR"
```

Если используется `COPY . .`, то код должен обновляться при пересборке.

## Финальная проверка

После всех исправлений:

```bash
# 1. Health check
curl -i https://api.shortsai.ru/health
# Ожидается: 200 {"ok":true}

# 2. Тест endpoint (без токена - должен быть 401, не 404)
curl -i -X POST https://api.shortsai.ru/api/telegram/fetchAndSaveToServer \
  -H "Content-Type: application/json" \
  -d '{"channelId":"test"}'
# Ожидается: 401 Unauthorized (НЕ 404)

# 3. С токеном (если есть)
curl -i -X POST https://api.shortsai.ru/api/telegram/fetchAndSaveToServer \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{"channelId":"test","url":"https://example.com/video.mp4"}'
# Ожидается: 200 или 400/500 с ошибкой валидации (НЕ 404)
```

## Измененные файлы

- `backend/src/index.ts` - добавлено логирование всех входящих запросов
- `backend/src/index.ts` - обновлено логирование зарегистрированных маршрутов

## Команды для повторной проверки

```bash
# Локально (PowerShell)
curl.exe -i -X POST https://api.shortsai.ru/api/telegram/fetchAndSaveToServer `
  -H "Content-Type: application/json" `
  -d '{\"channelId\":\"test\"}'

# На Synology
sudo docker logs shorts-backend --tail 100 | grep "INCOMING"
```

