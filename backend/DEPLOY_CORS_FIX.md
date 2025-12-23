# Инструкция по деплою исправления CORS

## Проблема
Backend блокирует запросы через nginx из-за проверки CORS, хотя nginx уже обрабатывает CORS.

## Решение
Добавлен middleware, который проверяет наличие заголовков `X-Forwarded-For` или `X-Real-IP` (запросы через nginx) и разрешает все origin для таких запросов.

## Файлы изменены
- `backend/src/index.ts` - добавлен middleware перед CORS для обработки запросов через nginx

## Деплой на Synology

### Вариант 1: Через SSH на Synology (рекомендуется)
```bash
# 1. Подключитесь к Synology по SSH
ssh admin@<SYNOLOGY_IP>

# 2. Скопируйте файл index.ts в контейнер
# Сначала сохраните содержимое файла локально, затем:
cat > /volume1/docker/shortsai/backend/src/index.ts << 'EOF'
# Вставьте содержимое backend/src/index.ts сюда
EOF

# Или используйте scp с вашего ПК:
# scp backend/src/index.ts admin@<SYNOLOGY_IP>:/volume1/docker/shortsai/backend/src/index.ts
```

### Вариант 2: Через Docker exec
```bash
# На Synology через SSH:
docker exec -i shorts-backend sh -c 'cat > /app/src/index.ts' < /path/to/index.ts

# Или скопируйте файл в контейнер:
docker cp backend/src/index.ts shorts-backend:/app/src/index.ts
```

### Вариант 3: Через VPS (если есть доступ)
```bash
# На VPS:
# 1. Файл уже сохранен в /tmp/index.ts на VPS
# 2. Скопируйте его на Synology вручную через SSH или используйте другой метод
```

## После копирования файла

```bash
# На Synology:
cd /volume1/docker/shortsai/backend

# Пересоберите контейнер
sudo docker compose build --no-cache backend

# Перезапустите контейнер
sudo docker compose up -d backend

# Проверьте логи
sudo docker logs shorts-backend --tail 50
```

## Проверка

После пересборки проверьте:

1. **OPTIONS запрос:**
```bash
curl -i -X OPTIONS https://api.shortsai.ru/api/telegram/fetchAndSaveToServer \
  -H "Origin: https://shortsai.ru" \
  -H "Access-Control-Request-Method: POST"
```
Ожидается: 204 с CORS заголовками

2. **POST запрос (без токена):**
```bash
curl -i -X POST https://api.shortsai.ru/api/telegram/fetchAndSaveToServer \
  -H "Content-Type: application/json" \
  -H "Origin: https://shortsai.ru" \
  -d '{"channelId": "test"}'
```
Ожидается: 401 (не 500, не CORS ошибка)

3. **POST запрос (с пустым body):**
```bash
curl -i -X POST https://api.shortsai.ru/api/telegram/fetchAndSaveToServer \
  -H "Content-Type: application/json" \
  -H "Origin: https://shortsai.ru" \
  -d '{}'
```
Ожидается: 400 с `missingFields: ["channelId"]`

## Изменения в коде

В `backend/src/index.ts` добавлен middleware перед CORS:

```typescript
// CORS middleware - настраиваем так, чтобы разрешать запросы через nginx
// Nginx уже обрабатывает CORS, поэтому здесь разрешаем все запросы, которые идут через nginx
app.use((req, res, next) => {
  // Если запрос идет через nginx (есть X-Forwarded-For), разрешаем его
  // так как nginx уже обрабатывает CORS
  if (req.headers["x-forwarded-for"] || req.headers["x-real-ip"]) {
    // Разрешаем все origin для запросов через nginx
    res.setHeader("Access-Control-Allow-Origin", req.headers.origin || "*");
    res.setHeader("Access-Control-Allow-Credentials", "true");
    res.setHeader("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS, PATCH, HEAD");
    res.setHeader("Access-Control-Allow-Headers", "Authorization, Content-Type, X-Requested-With");
    if (req.method === "OPTIONS") {
      return res.status(204).end();
    }
    return next();
  }
  // Для прямых запросов (не через nginx) используем стандартный CORS
  next();
});
```

Этот middleware проверяет наличие заголовков прокси (X-Forwarded-For или X-Real-IP) и для таких запросов разрешает все origin, так как nginx уже обрабатывает CORS.
