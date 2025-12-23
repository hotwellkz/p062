# Исправление HTTP 500 на POST /api/telegram/fetchAndSaveToServer

## Изменения

### 1. Добавлен глобальный error handler (`backend/src/index.ts`)

```typescript
app.use((err: any, req: express.Request, res: express.Response, next: express.NextFunction) => {
  const requestId = (req as any).requestId || "unknown";
  const errorMessage = String(err?.message ?? err);
  const stackTrace = err?.stack || "No stack trace available";
  
  Logger.error("Global error handler", {
    requestId,
    method: req.method,
    path: req.path,
    originalUrl: req.originalUrl,
    error: errorMessage,
    errorName: err?.name,
    errorCode: err?.code,
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

### 2. Улучшена валидация body (`backend/src/routes/telegramRoutes.ts`)

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

```typescript
} catch (err: any) {
  const requestId = (req as any).requestId || "unknown";
  const stackTrace = err?.stack || "No stack trace available";
  
  Logger.error("Error in /api/telegram/fetchAndSaveToServer", {
    requestId,
    error: errorMessage,
    errorName: err?.name,
    errorCode: err?.code,
    stackTrace,
    body: req.body
  });
}
```

## Деплой

1. Загрузить файлы на Synology:
```powershell
$content = Get-Content backend\src\index.ts -Raw
$content | ssh admin@192.168.100.222 "cat > /volume1/docker/shortsai/backend/src/index.ts"

$content = Get-Content backend\src\routes\telegramRoutes.ts -Raw
$content | ssh admin@192.168.100.222 "cat > /volume1/docker/shortsai/backend/src/routes/telegramRoutes.ts"
```

2. Пересобрать контейнер:
```bash
cd /volume1/docker/shortsai/backend
sudo docker compose build --no-cache backend
sudo docker compose up -d backend
```

## Тестирование

### A) OPTIONS preflight
```bash
curl -i -X OPTIONS https://api.shortsai.ru/api/telegram/fetchAndSaveToServer \
  -H "Origin: https://shortsai.ru" \
  -H "Access-Control-Request-Method: POST"
```
**Ожидается:** 204 No Content с CORS заголовками

### B) POST без body / с пустым body
```bash
curl -i -X POST https://api.shortsai.ru/api/telegram/fetchAndSaveToServer \
  -H "Content-Type: application/json" \
  -d '{}'
```
**Ожидается:** 400 Bad Request с `{"error": "MISSING_REQUIRED_FIELDS", "missingFields": ["channelId"]}`

### C) POST с валидным body (без токена)
```bash
curl -i -X POST https://api.shortsai.ru/api/telegram/fetchAndSaveToServer \
  -H "Content-Type: application/json" \
  -d '{"channelId": "test"}'
```
**Ожидается:** 401 Unauthorized (не 500)

## Измененные файлы

1. `backend/src/index.ts` - добавлен глобальный error handler
2. `backend/src/routes/telegramRoutes.ts` - улучшена валидация и логирование

