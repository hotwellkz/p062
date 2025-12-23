# Проверка работы CORS

## ✅ Переменная загружена в контейнер

```
FRONTEND_ORIGIN=https://shortsai.ru
```

## Проверка полного ответа CORS

Выполните на сервере:

```bash
# Полный тест preflight запроса
curl -H "Origin: https://shortsai.ru" \
     -H "Access-Control-Request-Method: GET" \
     -H "Access-Control-Request-Headers: Content-Type,Authorization" \
     -X OPTIONS \
     https://api.hotwell.synology.me/api/user-settings \
     -v
```

**Ищите в выводе:**
```
< HTTP/1.1 204 No Content
< Access-Control-Allow-Origin: https://shortsai.ru
< Access-Control-Allow-Methods: GET,HEAD,PUT,PATCH,POST,DELETE
< Access-Control-Allow-Credentials: true
```

## Если заголовки не возвращаются

### Проверка 1: Убедиться, что CORS middleware применяется

Проверьте, что в `backend/src/index.ts` CORS настроен ДО всех роутов:

```typescript
app.use(cors({ ... }));
// Затем все остальные middleware и роуты
```

### Проверка 2: Проверить логи ошибок

```bash
sudo /usr/local/bin/docker compose logs backend | grep -i "error\|cors\|not allowed" | tail -20
```

### Проверка 3: Тест обычного GET запроса

```bash
curl -H "Origin: https://shortsai.ru" \
     https://api.hotwell.synology.me/api/health \
     -v 2>&1 | grep -i "access-control"
```

## Альтернативный тест: через браузер

1. Откройте https://shortsai.ru
2. Откройте консоль разработчика (F12)
3. Выполните в консоли:
```javascript
fetch('https://api.hotwell.synology.me/api/health', {
  method: 'GET',
  headers: {
    'Origin': 'https://shortsai.ru'
  }
})
.then(r => {
  console.log('Status:', r.status);
  console.log('CORS Headers:', {
    'Access-Control-Allow-Origin': r.headers.get('Access-Control-Allow-Origin'),
    'Access-Control-Allow-Credentials': r.headers.get('Access-Control-Allow-Credentials')
  });
  return r.json();
})
.then(data => console.log('Data:', data))
.catch(err => console.error('Error:', err));
```

## Если CORS всё ещё не работает

### Решение 1: Добавить явную обработку OPTIONS

Убедитесь, что в коде есть обработка preflight запросов. CORS middleware должен автоматически обрабатывать OPTIONS, но можно добавить явно:

```typescript
app.options('*', cors()); // Обработка всех OPTIONS запросов
```

### Решение 2: Проверить reverse proxy

Если используется reverse proxy (nginx, Synology Reverse Proxy), убедитесь, что он не блокирует CORS заголовки.

### Решение 3: Добавить FRONTEND_ORIGIN в docker-compose.yml

Добавьте напрямую в `docker-compose.yml`:

```yaml
environment:
  - PORT=${BACKEND_PORT:-3000}
  - NODE_ENV=production
  - FRONTEND_ORIGIN=https://shortsai.ru
```

Затем перезапустите:
```bash
sudo /usr/local/bin/docker compose down
sudo /usr/local/bin/docker compose up -d
```

## Проверка работы после исправления

1. Откройте frontend: https://shortsai.ru
2. Откройте консоль разработчика (F12 → Console)
3. Проверьте, что ошибки CORS исчезли
4. Проверьте Network tab - запросы должны проходить успешно





