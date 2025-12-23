# Исправление CORS OPTIONS preflight

## Проблема

OPTIONS preflight запрос возвращал 500 Internal Server Error, из-за чего браузер не отправлял POST запрос.

## Решение

### 1. Добавлена явная обработка OPTIONS в backend

**Файл:** `backend/src/index.ts`

Добавлен обработчик OPTIONS ДО CORS middleware:

```typescript
app.options("*", (req, res) => {
  // Проверка origin и возврат CORS заголовков
  res.setHeader("Access-Control-Allow-Origin", origin);
  res.setHeader("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS, PATCH, HEAD");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type, Authorization, X-Requested-With");
  res.setHeader("Access-Control-Allow-Credentials", "true");
  res.setHeader("Access-Control-Max-Age", "86400");
  res.status(204).end();
});
```

### 2. Добавлена обработка OPTIONS в Nginx

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

## Проверка

### Тест OPTIONS запроса:

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

## Деплой

1. Обновить Nginx на VPS:
```bash
# На VPS
sudo cp /tmp/nginx-api-shortsai-new.conf /etc/nginx/sites-available/api.shortsai.ru
sudo nginx -t
sudo systemctl reload nginx
```

2. Обновить backend на Synology:
```bash
# На Synology
cd /volume1/docker/shortsai/backend
sudo docker compose build --no-cache backend
sudo docker compose up -d backend
```

## Результат

После исправления:
- ✅ OPTIONS возвращает 204 (не 500)
- ✅ CORS заголовки присутствуют
- ✅ Браузер отправляет POST после успешного OPTIONS
- ✅ POST запрос доходит до backend

