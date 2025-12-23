# Быстрое исправление CORS через Reverse Proxy

## Проблема подтверждена

✅ CORS работает напрямую: `http://localhost:3000`  
❌ CORS НЕ работает через Reverse Proxy: `https://api.hotwell.synology.me`

## Быстрое решение

### Вариант 1: Настроить Custom Headers в Synology Reverse Proxy

1. **Control Panel** → **Login Portal** → **Advanced** → **Reverse Proxy**
2. Найдите правило для `api.hotwell.synology.me`
3. Нажмите **Edit**
4. В разделе **Custom Header** (или **Дополнительные заголовки**):
   - Нажмите **Create** → **Custom Header**
   - Добавьте Response Headers:

| Header Name | Header Value |
|------------|--------------|
| `Access-Control-Allow-Origin` | `https://shortsai.ru` |
| `Access-Control-Allow-Methods` | `GET, POST, PUT, DELETE, OPTIONS, PATCH, HEAD` |
| `Access-Control-Allow-Headers` | `Content-Type, Authorization, X-Requested-With` |
| `Access-Control-Allow-Credentials` | `true` |

5. **Save** и проверьте

### Вариант 2: Проверить полный ответ

Выполните на сервере для диагностики:

```bash
# Полный ответ через Reverse Proxy
curl -H "Origin: https://shortsai.ru" \
     -H "Access-Control-Request-Method: GET" \
     -H "Access-Control-Request-Headers: Content-Type,Authorization" \
     -X OPTIONS \
     https://api.hotwell.synology.me/api/user-settings \
     -v
```

**Ищите:**
- HTTP статус (должен быть 204 или 200)
- Заголовки ответа (должны быть `Access-Control-Allow-*`)

### Вариант 3: Временное решение - добавить в код

Если Reverse Proxy не поддерживает Custom Headers, можно добавить явную обработку в код.

Добавьте в `backend/src/index.ts` после CORS middleware:

```typescript
// Явная обработка OPTIONS для всех маршрутов
app.options('*', (req, res) => {
  const origin = req.headers.origin;
  const frontendOrigin = normalizeOrigin(process.env.FRONTEND_ORIGIN) ?? "http://localhost:5173";
  
  if (origin && origin.replace(/\/+$/, "") === frontendOrigin.replace(/\/+$/, "")) {
    res.header('Access-Control-Allow-Origin', origin);
    res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS, PATCH, HEAD');
    res.header('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Requested-With');
    res.header('Access-Control-Allow-Credentials', 'true');
    res.header('Access-Control-Max-Age', '86400');
  }
  res.sendStatus(204);
});
```

Затем пересоберите и перезапустите контейнер:

```bash
sudo /usr/local/bin/docker compose down
sudo /usr/local/bin/docker compose up -d --build
```

## Проверка после исправления

```bash
curl -H "Origin: https://shortsai.ru" \
     -H "Access-Control-Request-Method: GET" \
     -X OPTIONS \
     https://api.hotwell.synology.me/api/user-settings \
     -v 2>&1 | grep -i "access-control"
```

**Ожидаемый результат:**
```
< access-control-allow-origin: https://shortsai.ru
< access-control-allow-methods: GET, POST, PUT, DELETE, OPTIONS, PATCH, HEAD
< access-control-allow-credentials: true
```

## Важно

- Если используете Custom Headers в Reverse Proxy, они должны быть **Response Headers**, а не Request Headers
- OPTIONS запросы должны проходить без аутентификации
- Проверьте, что Reverse Proxy не блокирует OPTIONS метод





