# Настройка диагностических заголовков

## Что добавлено

### 1. Nginx (nginx-api-shortsai-fixed.conf)
Добавлены диагностические заголовки в location /:
- `X-Edge-Server` - hostname VPS
- `X-Edge-Time` - время запроса
- `X-Upstream` - адрес upstream (10.9.0.2:3000)
- `X-Upstream-Status` - статус ответа от upstream
- `X-URI` - полный URI запроса
- `X-Method` - HTTP метод
- `X-Host` - Host заголовок

### 2. Backend (backend/src/index.ts)
Добавлены диагностические заголовки в ответ:
- `X-App-Instance` - hostname/container ID
- `X-App-Version` - git SHA / build date
- `X-App-Port` - порт приложения
- `X-Request-ID` - уникальный ID запроса

### 3. Backend логирование (backend/src/routes/telegramRoutes.ts)
Добавлено логирование requestId и заголовков в fetchAndSaveToServer.

## Команды для применения

### 1. Обновить Nginx конфиг на VPS

```bash
# На VPS (159.255.37.158)
ssh root@159.255.37.158

# Создать backup
sudo cp /etc/nginx/sites-available/api.shortsai.ru /etc/nginx/sites-available/api.shortsai.ru.backup

# Загрузить новый конфиг (скопировать содержимое nginx-api-shortsai-fixed.conf)
sudo nano /etc/nginx/sites-available/api.shortsai.ru

# Проверить конфиг
sudo nginx -t

# Перезагрузить
sudo systemctl reload nginx
```

### 2. Обновить backend на Synology

```bash
# Загрузить обновленные файлы
# backend/src/index.ts
# backend/src/routes/telegramRoutes.ts

# Пересобрать
cd /volume1/docker/shortsai/backend
sudo docker compose build --no-cache backend
sudo docker compose up -d backend
```

## Проверка диагностических заголовков

### Из PowerShell:
```powershell
curl.exe -i https://api.shortsai.ru/health
curl.exe -i -X POST https://api.shortsai.ru/api/telegram/fetchAndSaveToServer `
  -H "Content-Type: application/json" `
  -d '{}'
```

### Из браузера:
1. Откройте DevTools (F12)
2. Network → найдите запрос fetchAndSaveToServer
3. Headers → Response Headers
4. Проверьте наличие:
   - `X-Edge-Server`
   - `X-Upstream`
   - `X-App-Instance`
   - `X-Request-ID`

## Ожидаемый результат

Если заголовки видны в браузере - значит запрос идет через правильный Nginx и backend.
Если заголовков нет - значит запрос обрабатывается другим сервером/прокси.

