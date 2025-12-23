# Финальный отчет: Исправление CORS и OPTIONS preflight

## РЕАЛЬНАЯ ПРИЧИНА

OPTIONS preflight запрос возвращал **500 Internal Server Error**, из-за чего браузер блокировал POST запрос. CORS middleware в Express не обрабатывал OPTIONS правильно, что приводило к ошибке.

## ЧТО БЫЛО НЕ ТАК

1. ❌ OPTIONS preflight возвращал 500 вместо 204
2. ❌ CORS middleware не обрабатывал OPTIONS явно
3. ❌ Nginx не обрабатывал OPTIONS на уровне прокси
4. ❌ Браузер блокировал POST после неудачного OPTIONS

## ЧТО ИСПРАВЛЕНО

### 1. Backend: Явная обработка OPTIONS

**Файл:** `backend/src/index.ts`

Добавлен обработчик OPTIONS ДО CORS middleware:

```typescript
app.options("*", (req, res) => {
  // Проверка origin и возврат CORS заголовков
  const origin = req.headers.origin;
  // ... проверка разрешенных origins ...
  res.setHeader("Access-Control-Allow-Origin", origin || frontendOrigin);
  res.setHeader("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS, PATCH, HEAD");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type, Authorization, X-Requested-With");
  res.setHeader("Access-Control-Allow-Credentials", "true");
  res.setHeader("Access-Control-Max-Age", "86400");
  res.status(204).end();
});
```

### 2. Nginx: Обработка OPTIONS на уровне прокси

**Файл:** `nginx-api-shortsai-fixed.conf`

Добавлена обработка OPTIONS в location блоке:

```nginx
if ($request_method = 'OPTIONS') {
    add_header 'Access-Control-Allow-Origin' '$http_origin' always;
    add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS, PATCH, HEAD' always;
    add_header 'Access-Control-Allow-Headers' 'Content-Type, Authorization, X-Requested-With' always;
    add_header 'Access-Control-Allow-Credentials' 'true' always;
    add_header 'Access-Control-Max-Age' '86400' always;
    add_header 'Content-Length' '0' always;
    add_header 'Content-Type' 'text/plain' always;
    return 204;
}
```

### 3. Frontend: Проверка URL

**Файл:** `app/src/api/telegram.ts`

Использует `VITE_BACKEND_URL` из переменных окружения:
- Fallback: `http://localhost:8080` (для разработки)
- Продакшн: должен быть `https://api.shortsai.ru` (настроено в Netlify)

**Service Worker:** Не найден (проблема не в SW)

## КОНКРЕТНЫЕ ИЗМЕНЕНИЯ В КОДЕ

### backend/src/index.ts

**Добавлено:**
- Обработчик `app.options("*", ...)` перед CORS middleware
- Проверка origin и возврат правильных CORS заголовков
- Статус 204 для успешного OPTIONS

### nginx-api-shortsai-fixed.conf

**Добавлено:**
- Условие `if ($request_method = 'OPTIONS')` в location блоке
- CORS заголовки для OPTIONS запросов
- Возврат 204 для OPTIONS

## ДЕПЛОЙ

### 1. Обновить Nginx на VPS

```bash
# На VPS (root@159.255.37.158)
Get-Content nginx-api-shortsai-fixed.conf | ssh root@159.255.37.158 "cat > /tmp/nginx-api-shortsai-new.conf && sudo cp /etc/nginx/sites-available/api.shortsai.ru /etc/nginx/sites-available/api.shortsai.ru.backup && sudo cp /tmp/nginx-api-shortsai-new.conf /etc/nginx/sites-available/api.shortsai.ru && sudo nginx -t && sudo systemctl reload nginx && echo 'Nginx updated successfully'"
```

### 2. Обновить backend на Synology

```bash
# На Synology (admin@192.168.100.222)
cd /volume1/docker/shortsai/backend
sudo docker compose build --no-cache backend
sudo docker compose up -d backend
```

## ПРОВЕРКА

### Тест OPTIONS:

```bash
curl -i -X OPTIONS https://api.shortsai.ru/api/telegram/fetchAndSaveToServer \
  -H "Origin: https://shortsai.ru" \
  -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: Content-Type,Authorization"
```

**Ожидаемый результат:**
- HTTP/1.1 204 No Content
- Access-Control-Allow-Origin: https://shortsai.ru
- Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS, PATCH, HEAD
- Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With
- Access-Control-Allow-Credentials: true

### Тест POST (после успешного OPTIONS):

```bash
curl -i -X POST https://api.shortsai.ru/api/telegram/fetchAndSaveToServer \
  -H "Origin: https://shortsai.ru" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -d '{"channelId":"test"}'
```

**Ожидаемый результат:**
- HTTP/1.1 401 Unauthorized (без токена) или 200 OK (с валидным токеном)
- НЕ 404 Not Found
- НЕ 500 Internal Server Error

### Проверка в браузере:

1. Откройте Chrome Incognito (Ctrl+Shift+N)
2. DevTools (F12) → Network → включите "Disable cache"
3. Выполните действие "Забрать видео из SynTx на сервер"
4. Проверьте:
   - OPTIONS запрос → 204 No Content
   - POST запрос → 401 или 200 (НЕ 404)
   - Response Headers содержат CORS заголовки

## ФИНАЛЬНЫЙ СТАТУС

После деплоя:
- ✅ OPTIONS возвращает 204 (не 500)
- ✅ CORS заголовки присутствуют
- ✅ Браузер отправляет POST после успешного OPTIONS
- ✅ POST запрос доходит до backend (401 или 200, не 404)

## ВАЖНО

Если в браузере все еще 404:
1. Проверьте, что `VITE_BACKEND_URL` в Netlify = `https://api.shortsai.ru`
2. Пересоберите фронтенд на Netlify
3. Очистите кеш браузера (Ctrl+Shift+Del)
4. Проверьте в Incognito режиме

---

**Дата:** 2025-12-21
**Проблема:** OPTIONS preflight → 500 → браузер блокирует POST
**Решение:** Явная обработка OPTIONS в backend и Nginx

