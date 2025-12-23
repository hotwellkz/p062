# Файлы загружены на Synology

## Загруженные файлы:
✅ `backend/src/index.ts` → `/volume1/docker/shortsai/backend/src/index.ts`
✅ `backend/src/routes/telegramRoutes.ts` → `/volume1/docker/shortsai/backend/src/routes/telegramRoutes.ts`

## Следующие шаги на Synology:

```bash
# 1. Подключитесь к Synology по SSH
ssh admin@192.168.100.222

# 2. Перейдите в директорию проекта
cd /volume1/docker/shortsai/backend

# 3. Пересоберите контейнер
sudo docker compose build --no-cache backend

# 4. Перезапустите контейнер
sudo docker compose up -d backend

# 5. Проверьте логи
sudo docker logs shorts-backend --tail 50
```

## Проверка после пересборки:

### 1. OPTIONS запрос (preflight):
```bash
curl -i -X OPTIONS https://api.shortsai.ru/api/telegram/fetchAndSaveToServer \
  -H "Origin: https://shortsai.ru" \
  -H "Access-Control-Request-Method: POST"
```
**Ожидается:** 204 No Content с CORS заголовками

### 2. POST запрос без токена:
```bash
curl -i -X POST https://api.shortsai.ru/api/telegram/fetchAndSaveToServer \
  -H "Content-Type: application/json" \
  -H "Origin: https://shortsai.ru" \
  -d '{"channelId": "test"}'
```
**Ожидается:** 401 Unauthorized (НЕ 500, НЕ CORS ошибка)

### 3. POST запрос с пустым body:
```bash
curl -i -X POST https://api.shortsai.ru/api/telegram/fetchAndSaveToServer \
  -H "Content-Type: application/json" \
  -H "Origin: https://shortsai.ru" \
  -d '{}'
```
**Ожидается:** 400 Bad Request с `missingFields: ["channelId"]`

## Изменения в коде:

### `backend/src/index.ts`:
- Добавлен middleware перед CORS, который проверяет наличие `X-Forwarded-For` или `X-Real-IP`
- Для запросов через nginx разрешаются все origin (nginx уже обрабатывает CORS)
- Для прямых запросов используется стандартный CORS

### `backend/src/routes/telegramRoutes.ts`:
- Улучшена валидация body (возвращает 400 для невалидных данных)
- Улучшено логирование ошибок с `requestId` и `stackTrace`
- Исправлены type assertions для `channelId`

