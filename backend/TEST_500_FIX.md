# Тестирование исправления HTTP 500

## Контейнер пересобран и запущен

**Image:** `sha256:c4cb737c03da0690b6d14f320d1579c5d13e2facd9b902598a8fae9534c67b25`
**Container:** `shorts-backend` - Started

## Тестирование

### 1. Проверка логов запуска

```bash
sudo docker logs shorts-backend --tail 50
```

Проверьте, что:
- Backend запустился без ошибок
- Routes зарегистрированы
- Firebase Admin инициализирован

### 2. Тест A: OPTIONS preflight

```bash
curl -i -X OPTIONS https://api.shortsai.ru/api/telegram/fetchAndSaveToServer \
  -H "Origin: https://shortsai.ru" \
  -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: Content-Type,Authorization"
```

**Ожидаемый результат:**
- Status: 204 No Content
- Headers: `Access-Control-Allow-Origin: https://shortsai.ru`
- Headers: `Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS, PATCH, HEAD`

### 3. Тест B: POST без body / с пустым body

```bash
curl -i -X POST https://api.shortsai.ru/api/telegram/fetchAndSaveToServer \
  -H "Content-Type: application/json" \
  -d '{}'
```

**Ожидаемый результат:**
- Status: 400 Bad Request
- Body: `{"status":"error","error":"MISSING_REQUIRED_FIELDS","message":"Missing required fields: channelId","missingFields":["channelId"],"requestId":"..."}`
- НЕ 500!

### 4. Тест C: POST с валидным body (без токена)

```bash
curl -i -X POST https://api.shortsai.ru/api/telegram/fetchAndSaveToServer \
  -H "Content-Type: application/json" \
  -d '{"channelId": "test"}'
```

**Ожидаемый результат:**
- Status: 401 Unauthorized
- Body: `{"error":"Unauthorized","message":"Missing or invalid Authorization header"}`
- НЕ 500!

### 5. Проверка логов при ошибке

Если все еще получаете 500, проверьте логи:

```bash
sudo docker logs shorts-backend --tail 200 | grep -i "error\|stack\|fetchAndSaveToServer\|requestId"
```

Ищите:
- Stack trace ошибки
- Request ID
- Точное сообщение об ошибке
- Файл и строка, где произошла ошибка

## Критерии успеха

✅ OPTIONS → 204 с CORS заголовками
✅ POST без body → 400 с `missingFields`
✅ POST с channelId без токена → 401 (не 500)
✅ Любая ошибка → логируется с stack trace и requestId

