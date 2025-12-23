# Настройка Synology Reverse Proxy для CORS

## ✅ Проблема подтверждена

CORS работает напрямую к контейнеру (`localhost:3000`), но не работает через Reverse Proxy (`api.hotwell.synology.me`).

**Причина:** Reverse Proxy не передает CORS заголовки из backend.

## Решение: Настройка Reverse Proxy

### Шаг 1: Открыть настройки Reverse Proxy

1. Войдите в **Synology DSM**
2. Откройте **Control Panel** → **Login Portal**
3. Перейдите на вкладку **Advanced**
4. Найдите раздел **Reverse Proxy**
5. Найдите правило для `api.hotwell.synology.me`
6. Нажмите **Edit** (редактировать)

### Шаг 2: Добавить Custom Headers

В окне редактирования найдите раздел **Custom Header** (или **Дополнительные заголовки**).

**Добавьте Response Headers:**

Нажмите **Create** → **WebSocket** или **Custom Header** и добавьте:

| Header Name | Header Value |
|------------|--------------|
| `Access-Control-Allow-Origin` | `https://shortsai.ru` |
| `Access-Control-Allow-Methods` | `GET, POST, PUT, DELETE, OPTIONS, PATCH, HEAD` |
| `Access-Control-Allow-Headers` | `Content-Type, Authorization, X-Requested-With` |
| `Access-Control-Allow-Credentials` | `true` |
| `Access-Control-Max-Age` | `86400` |

### Шаг 3: Настроить обработку OPTIONS

Убедитесь, что правило Reverse Proxy настроено так:

**Source:**
- Protocol: **HTTPS**
- Hostname: `api.hotwell.synology.me`
- Port: **443**

**Destination:**
- Protocol: **HTTP**
- Hostname: `localhost` (или IP сервера)
- Port: **3000** (или порт, на котором работает backend)

### Шаг 4: Сохранить и применить

1. Нажмите **Save** (Сохранить)
2. Дождитесь применения настроек

## Альтернативное решение: Nginx конфигурация

Если используется Nginx (через Docker или напрямую), добавьте в конфигурацию:

```nginx
location /api {
    proxy_pass http://localhost:3000;
    
    # Передавать оригинальные заголовки
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    
    # CORS headers (если backend не передает)
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

## Проверка после настройки

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
2. Откройте консоль разработчика (F12 → Console)
3. Проверьте, что ошибки CORS исчезли
4. Проверьте Network tab - запросы должны проходить успешно

## Важно

- CORS заголовки должны добавляться **после** получения ответа от backend
- Reverse Proxy не должен удалять заголовки из ответа backend
- OPTIONS запросы должны проходить без аутентификации

## Если проблема сохраняется

### Вариант 1: Проверить логи Reverse Proxy

Проверьте логи Synology на наличие ошибок или блокировок.

### Вариант 2: Временно отключить Reverse Proxy

Для тестирования можно временно открыть порт 3000 напрямую и проверить работу.

### Вариант 3: Использовать другой порт

Настроить Reverse Proxy на другой порт backend, если текущий конфликтует.





