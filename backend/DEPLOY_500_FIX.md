# Деплой исправления HTTP 500

## ✅ Файлы загружены на Synology

1. ✅ `backend/src/index.ts` - добавлен глобальный error handler
2. ✅ `backend/src/routes/telegramRoutes.ts` - улучшена валидация и логирование

## Шаг 1: Пересобрать контейнер на Synology

Выполните на Synology (SSH):

```bash
cd /volume1/docker/shortsai/backend

# Пересобрать с новым кодом
sudo docker compose build --no-cache backend

# Запустить
sudo docker compose up -d backend

# Проверить статус
sleep 5
sudo docker ps | grep shorts-backend

# Проверить логи запуска
sudo docker logs shorts-backend --tail 50
```

## Шаг 2: Тестирование

### A) OPTIONS preflight

```bash
curl -i -X OPTIONS https://api.shortsai.ru/api/telegram/fetchAndSaveToServer \
  -H "Origin: https://shortsai.ru" \
  -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: Content-Type,Authorization"
```

**Ожидаемый результат:**
- HTTP/2 204 No Content
- `Access-Control-Allow-Origin: https://shortsai.ru`
- `Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS, PATCH, HEAD`
- `Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With`

### B) POST без body / с пустым body

```bash
curl -i -X POST https://api.shortsai.ru/api/telegram/fetchAndSaveToServer \
  -H "Content-Type: application/json" \
  -d '{}'
```

**Ожидаемый результат:**
- HTTP/1.1 400 Bad Request
- Body: `{"status":"error","error":"MISSING_REQUIRED_FIELDS","message":"Missing required fields: channelId","missingFields":["channelId"],"requestId":"..."}`

### C) POST с валидным body (без токена)

```bash
curl -i -X POST https://api.shortsai.ru/api/telegram/fetchAndSaveToServer \
  -H "Content-Type: application/json" \
  -d '{"channelId": "test"}'
```

**Ожидаемый результат:**
- HTTP/1.1 401 Unauthorized (не 500!)
- Body: `{"error":"Unauthorized","message":"Missing or invalid Authorization header"}`

### D) Проверка логов при ошибке

Если все еще получаете 500, проверьте логи:

```bash
sudo docker logs shorts-backend --tail 100 | grep -i "error\|stack\|fetchAndSaveToServer"
```

Ищите:
- Stack trace ошибки
- Request ID
- Точное сообщение об ошибке

## Что было исправлено

1. **Глобальный error handler** - перехватывает все необработанные ошибки
2. **Валидация body** - возвращает 400 вместо 500 при невалидных данных
3. **Stack trace в логах** - полная информация об ошибке для диагностики
4. **Request ID** - отслеживание запросов через логи

## Ожидаемое поведение

- ✅ Пустой body → 400 с `missingFields`
- ✅ Нет channelId → 400 с `missingFields`
- ✅ Нет токена → 401 (не 500)
- ✅ Валидный запрос → обрабатывается или возвращает бизнес-ошибку (не 500)
- ✅ Любая ошибка → логируется с stack trace и requestId

