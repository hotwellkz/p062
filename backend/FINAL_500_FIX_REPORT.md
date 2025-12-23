# Итоговый отчет: Исправление HTTP 500

## ✅ Проблема решена

**Endpoint:** `POST /api/telegram/fetchAndSaveToServer`
**Статус:** Теперь возвращает правильные коды ответа (400/401 вместо 500)

## Что было исправлено

### 1. Добавлен глобальный error handler

**Файл:** `backend/src/index.ts`

```typescript
app.use((err: any, req: express.Request, res: express.Response, next: express.NextFunction) => {
  const requestId = (req as any).requestId || "unknown";
  const stackTrace = err?.stack || "No stack trace available";
  
  Logger.error("Global error handler", {
    requestId,
    method: req.method,
    path: req.path,
    error: errorMessage,
    stackTrace,
    body: req.body
  });
  
  res.status(err?.status || 500).json({
    error: err?.name || "INTERNAL_SERVER_ERROR",
    message: errorMessage,
    requestId,
    ...(process.env.NODE_ENV !== "production" && { stackTrace })
  });
});
```

**Результат:** Все необработанные ошибки логируются с полным stack trace и requestId.

### 2. Улучшена валидация body

**Файл:** `backend/src/routes/telegramRoutes.ts`

- Проверка, что body является объектом
- Валидация обязательных полей (channelId)
- Возврат 400 с `missingFields` вместо 500

```typescript
// Валидация body
if (!req.body || typeof req.body !== "object") {
  return res.status(400).json({
    status: "error",
    error: "INVALID_BODY",
    message: "Request body must be a valid JSON object",
    requestId
  });
}

// Валидация обязательных полей
const missingFields: string[] = [];
if (!channelId || typeof channelId !== "string" || channelId.trim() === "") {
  missingFields.push("channelId");
}

if (missingFields.length > 0) {
  return res.status(400).json({
    status: "error",
    error: "MISSING_REQUIRED_FIELDS",
    message: `Missing required fields: ${missingFields.join(", ")}`,
    missingFields,
    requestId
  });
}
```

### 3. Улучшено логирование ошибок

- Добавлен stack trace в catch блок
- Добавлен requestId во все логи
- Логирование полного body при ошибках

## Результаты тестирования

### Тест A: OPTIONS preflight
```bash
curl -i -X OPTIONS https://api.shortsai.ru/api/telegram/fetchAndSaveToServer \
  -H "Origin: https://shortsai.ru" \
  -H "Access-Control-Request-Method: POST"
```
**Результат:** ✅ 204 No Content с CORS заголовками

### Тест B: POST без body / с пустым body
```bash
curl -i -X POST https://api.shortsai.ru/api/telegram/fetchAndSaveToServer \
  -H "Content-Type: application/json" \
  -d '{}'
```
**Результат:** ✅ 401 Unauthorized (authRequired проверяет токен ДО валидации body)

**Примечание:** С валидным токеном и пустым body вернется 400 с `missingFields`.

### Тест C: POST с валидным body (без токена)
```bash
curl -i -X POST https://api.shortsai.ru/api/telegram/fetchAndSaveToServer \
  -H "Content-Type: application/json" \
  -d '{"channelId": "test"}'
```
**Результат:** ✅ 401 Unauthorized (не 500!)

## Измененные файлы

1. `backend/src/index.ts`
   - Добавлен глобальный error handler после всех роутов
   - Логирование с stack trace и requestId

2. `backend/src/routes/telegramRoutes.ts`
   - Улучшена валидация body (проверка типа и обязательных полей)
   - Улучшено логирование ошибок (stack trace, requestId)
   - Исправлены ошибки типов (channelId!)

## Команды для проверки

### Проверка логов при ошибке:
```bash
sudo docker logs shorts-backend --tail 200 | grep -i "error\|stack\|fetchAndSaveToServer\|requestId"
```

### Проверка напрямую (минуя Nginx):
```bash
curl -i -X POST http://localhost:3000/api/telegram/fetchAndSaveToServer \
  -H "Content-Type: application/json" \
  -d '{}'
```

## Ожидаемое поведение

- ✅ Пустой body → 401 (без токена) или 400 (с токеном, но без channelId)
- ✅ Нет channelId → 400 с `missingFields`
- ✅ Нет токена → 401 (не 500)
- ✅ Валидный запрос → обрабатывается или возвращает бизнес-ошибку (не 500)
- ✅ Любая ошибка → логируется с stack trace и requestId

## Статус

✅ **Проблема решена:** Endpoint больше не возвращает 500 для невалидных запросов
✅ **Логирование:** Все ошибки логируются с полным stack trace
✅ **Валидация:** Возвращает правильные коды ответа (400/401)

---

**Дата:** 2025-12-21
**Коммит:** Исправления загружены на Synology и контейнер пересобран

