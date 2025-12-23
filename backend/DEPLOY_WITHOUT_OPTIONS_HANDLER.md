# Деплой без обработчика OPTIONS в backend

## Изменение

Удален обработчик OPTIONS из backend, так как:
1. Nginx уже обрабатывает OPTIONS и возвращает 204
2. Обработчик OPTIONS в backend мог вызывать ошибку 500 для POST запросов

## Деплой

Файл `backend/src/index.ts` уже загружен на Synology.

Теперь пересоберите контейнер:

```bash
cd /volume1/docker/shortsai/backend
sudo docker compose build --no-cache backend
sudo docker compose up -d backend
sudo docker logs shorts-backend --tail 30
```

## Проверка

### 1. OPTIONS (должен работать через Nginx):

```bash
curl -i -X OPTIONS https://api.shortsai.ru/api/telegram/fetchAndSaveToServer \
  -H "Origin: https://shortsai.ru" \
  -H "Access-Control-Request-Method: POST"
```

**Ожидаемый результат:**
- HTTP/2 204 No Content
- CORS заголовки от Nginx

### 2. POST (должен работать без 500):

```bash
curl -i -X POST https://api.shortsai.ru/api/telegram/fetchAndSaveToServer \
  -H "Origin: https://shortsai.ru" \
  -H "Content-Type: application/json" \
  -d '{}'
```

**Ожидаемый результат:**
- HTTP/1.1 401 Unauthorized (без токена)
- НЕ 500 Internal Server Error

## Если POST все еще 500

Проверьте логи backend:

```bash
sudo docker logs shorts-backend --tail 100 | grep -i "error\|exception"
```

Возможные причины:
1. Ошибка в CORS middleware
2. Ошибка в authRequired middleware
3. Ошибка в самом роуте fetchAndSaveToServer

