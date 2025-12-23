# Полный план диагностики проблемы 404 из браузера

## Текущая ситуация

- ✅ Backend работает локально (401 без токена)
- ✅ Backend работает через публичный домен из curl (401 без токена)
- ❌ Браузер получает 404 Not Found

## Шаг 1: Проверка DNS/IPv6

**Результат проверки:**
- ✅ DNS A запись: `api.shortsai.ru` → `159.255.37.158` (правильный IP)
- ✅ IPv6 (AAAA): нет записи (нет проблемы с IPv6)

## Шаг 2: Добавление диагностических заголовков

### Nginx (nginx-api-shortsai-fixed.conf)
Добавлены заголовки:
- `X-Edge-Server` - hostname VPS
- `X-Upstream` - адрес upstream
- `X-URI` - полный URI
- `X-Method` - HTTP метод

### Backend (backend/src/index.ts)
Добавлены заголовки:
- `X-App-Instance` - hostname/container ID
- `X-App-Version` - git SHA
- `X-Request-ID` - уникальный ID запроса

## Шаг 3: Команды для применения изменений

### 1. Обновить Nginx на VPS

```bash
# На VPS (159.255.37.158)
ssh root@159.255.37.158

# Создать backup
sudo cp /etc/nginx/sites-available/api.shortsai.ru /etc/nginx/sites-available/api.shortsai.ru.backup

# Загрузить новый конфиг (скопировать содержимое nginx-api-shortsai-fixed.conf)
sudo nano /etc/nginx/sites-available/api.shortsai.ru

# Проверить
sudo nginx -t

# Перезагрузить
sudo systemctl reload nginx
```

### 2. Обновить backend на Synology

```bash
# Загрузить обновленные файлы:
# - backend/src/index.ts
# - backend/src/routes/telegramRoutes.ts

# Пересобрать
cd /volume1/docker/shortsai/backend
sudo docker compose build --no-cache backend
sudo docker compose up -d backend
```

## Шаг 4: Проверка после применения

### Из PowerShell:
```powershell
# Проверить заголовки
curl.exe -i https://api.shortsai.ru/health
curl.exe -i -X POST https://api.shortsai.ru/api/telegram/fetchAndSaveToServer `
  -H "Content-Type: application/json" `
  -d '{}'
```

### Из браузера:
1. Откройте DevTools (F12)
2. Network → найдите запрос fetchAndSaveToServer
3. Headers → Response Headers
4. Проверьте наличие диагностических заголовков

## Шаг 5: Проверка фронтенда

### Проверить, какой URL использует фронтенд

В браузере DevTools → Console выполните:
```javascript
console.log('Backend URL:', import.meta.env.VITE_BACKEND_URL);
```

Или проверьте в Network → запрос → Headers → Request URL

### Проверить Service Worker

1. DevTools → Application → Service Workers
2. Если есть зарегистрированные SW → Unregister
3. Clear site data
4. Hard reload (Ctrl+Shift+R)

## Шаг 6: Проверка Nginx конфигурации

На VPS выполните:
```bash
# Проверить все server blocks для api.shortsai.ru
sudo nginx -T | grep -B 5 -A 30 "server_name.*api.shortsai.ru"

# Проверить location blocks
sudo nginx -T | grep -B 5 -A 10 "location.*/api"

# Проверить, нет ли default_server
sudo nginx -T | grep -B 5 -A 15 "default_server"
```

## Ожидаемый результат

После применения изменений:
- В Response Headers браузера должны быть видны диагностические заголовки
- Если заголовков нет → запрос обрабатывается другим сервером/прокси
- Если заголовки есть → можно сравнить X-Upstream и X-App-Instance

