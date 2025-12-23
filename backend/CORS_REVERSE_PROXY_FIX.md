# Исправление CORS через Reverse Proxy

## Проблема

CORS настроен правильно в коде, но заголовки могут блокироваться или не передаваться через Synology Reverse Proxy.

## Проверка 1: Прямой доступ к контейнеру

Проверьте, работает ли CORS при прямом доступе к контейнеру (минуя reverse proxy):

```bash
# Узнать IP контейнера
sudo /usr/local/bin/docker compose exec backend sh -c 'hostname -i'

# Или проверить порт напрямую (если проброшен)
curl -H "Origin: https://shortsai.ru" \
     -H "Access-Control-Request-Method: GET" \
     -X OPTIONS \
     http://localhost:3000/api/user-settings \
     -v 2>&1 | grep -i "access-control"
```

Если CORS работает напрямую, проблема в reverse proxy.

## Решение: Настройка Reverse Proxy в Synology

### Шаг 1: Открыть Reverse Proxy

1. Откройте **Control Panel** → **Login Portal** → **Advanced** → **Reverse Proxy**
2. Найдите правило для `api.hotwell.synology.me`
3. Нажмите **Edit**

### Шаг 2: Добавить Custom Headers

В разделе **Custom Header** добавьте:

**Response Headers:**
```
Access-Control-Allow-Origin: https://shortsai.ru
Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS, PATCH, HEAD
Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With
Access-Control-Allow-Credentials: true
Access-Control-Max-Age: 86400
```

### Шаг 3: Настроить обработку OPTIONS

Убедитесь, что OPTIONS запросы проходят через reverse proxy.

**Или добавьте правило для OPTIONS:**
- **Source Protocol:** HTTPS
- **Hostname:** api.hotwell.synology.me
- **Port:** 443
- **Destination Protocol:** HTTP
- **Hostname:** localhost (или IP контейнера)
- **Port:** 3000 (или порт backend)

### Шаг 4: Сохранить и применить

Нажмите **Save** и проверьте работу.

## Альтернативное решение: Nginx конфигурация

Если используется Nginx, добавьте в конфигурацию:

```nginx
location /api {
    proxy_pass http://localhost:3000;
    
    # CORS headers
    add_header 'Access-Control-Allow-Origin' 'https://shortsai.ru' always;
    add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS, PATCH, HEAD' always;
    add_header 'Access-Control-Allow-Headers' 'Content-Type, Authorization, X-Requested-With' always;
    add_header 'Access-Control-Allow-Credentials' 'true' always;
    add_header 'Access-Control-Max-Age' '86400' always;
    
    # Handle preflight
    if ($request_method = 'OPTIONS') {
        add_header 'Access-Control-Allow-Origin' 'https://shortsai.ru' always;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS, PATCH, HEAD' always;
        add_header 'Access-Control-Allow-Headers' 'Content-Type, Authorization, X-Requested-With' always;
        add_header 'Access-Control-Allow-Credentials' 'true' always;
        add_header 'Access-Control-Max-Age' '86400' always;
        add_header 'Content-Length' '0';
        add_header 'Content-Type' 'text/plain';
        return 204;
    }
}
```

## Проверка после исправления

### Тест 1: Через curl

```bash
curl -H "Origin: https://shortsai.ru" \
     -H "Access-Control-Request-Method: GET" \
     -H "Access-Control-Request-Headers: Content-Type,Authorization" \
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

### Тест 2: Через браузер

1. Откройте https://shortsai.ru
2. Откройте консоль разработчика (F12)
3. Проверьте, что ошибки CORS исчезли
4. Проверьте Network tab - запросы должны проходить успешно

## Если проблема сохраняется

### Вариант 1: Добавить явную обработку OPTIONS в код

Добавьте в `backend/src/index.ts` после CORS middleware:

```typescript
// Явная обработка OPTIONS запросов
app.options('*', (req, res) => {
  res.header('Access-Control-Allow-Origin', frontendOrigin);
  res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS, PATCH, HEAD');
  res.header('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Requested-With');
  res.header('Access-Control-Allow-Credentials', 'true');
  res.header('Access-Control-Max-Age', '86400');
  res.sendStatus(204);
});
```

### Вариант 2: Проверить логи reverse proxy

Проверьте логи Synology Reverse Proxy на наличие ошибок или блокировок.

## Важно

- CORS заголовки должны добавляться **до** аутентификации
- Reverse proxy не должен удалять CORS заголовки из ответа backend
- OPTIONS запросы должны проходить без аутентификации





