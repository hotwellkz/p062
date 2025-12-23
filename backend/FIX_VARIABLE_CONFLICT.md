# Исправление конфликта переменных в OPTIONS обработчике

## Проблема

В обработчике OPTIONS была ошибка - конфликт имен переменных:
```typescript
allowed = allowedOrigins.some(allowed => {  // ❌ 'allowed' используется дважды
```

Переменная `allowed` использовалась и как внешняя переменная, и как параметр функции `some()`, что вызывало ошибку при выполнении.

## Исправление

Переименован параметр функции:
```typescript
allowed = allowedOrigins.some(allowedOrigin => {  // ✅ исправлено
```

## Деплой

Файл `backend/src/index.ts` уже загружен на Synology.

Теперь нужно пересобрать контейнер:

```bash
cd /volume1/docker/shortsai/backend
sudo docker compose build --no-cache backend
sudo docker compose up -d backend
sudo docker logs shorts-backend --tail 30
```

## Проверка

После пересборки проверьте POST запрос:

```bash
curl -i -X POST https://api.shortsai.ru/api/telegram/fetchAndSaveToServer \
  -H "Origin: https://shortsai.ru" \
  -H "Content-Type: application/json" \
  -d '{}'
```

**Ожидаемый результат:**
- HTTP/1.1 401 Unauthorized (без токена)
- НЕ 500 Internal Server Error

