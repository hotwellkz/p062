# Диагностика проблемы 404 из браузера vs 401 из curl

## Шаг 1: Проверка Nginx конфигурации на VPS

Выполните на VPS (159.255.37.158):

```bash
# Проверить все server blocks для api.shortsai.ru
sudo nginx -T | grep -A 20 "server_name.*api.shortsai.ru"

# Проверить все location blocks
sudo nginx -T | grep -B 5 -A 10 "location.*/api"

# Проверить все proxy_pass директивы
sudo nginx -T | grep -B 5 -A 5 "proxy_pass"

# Проверить, нет ли нескольких конфигов
ls -la /etc/nginx/sites-enabled/ | grep api.shortsai
ls -la /etc/nginx/conf.d/ | grep api.shortsai
```

## Шаг 2: Обновление кода на Synology

В текущей SSH сессии на Synology:

```bash
# 1. Перейти в директорию backend
cd /volume1/docker/shortsai/backend

# 2. Скачать обновленный index.ts (я загружу его)
# Или вручную скопировать содержимое из локального файла

# 3. Пересобрать контейнер
sudo docker compose build --no-cache backend

# 4. Перезапустить
sudo docker compose up -d backend

# 5. Проверить логи
sudo docker logs shorts-backend --tail 50 | grep -E "routes registered|listening"
```

## Шаг 3: Тестирование диагностического endpoint

С VPS:
```bash
curl -i https://api.shortsai.ru/health | jq .
```

Из PowerShell (локально):
```powershell
curl.exe -i https://api.shortsai.ru/health
```

Сравнить diagnostic поля (hostname, pid, containerId, routesHash).

## Шаг 4: Тестирование проблемного endpoint

С VPS:
```bash
curl -i -X POST https://api.shortsai.ru/api/telegram/fetchAndSaveToServer \
  -H "Content-Type: application/json" \
  -d '{}'
```

Из PowerShell:
```powershell
curl.exe -i -X POST https://api.shortsai.ru/api/telegram/fetchAndSaveToServer `
  -H "Content-Type: application/json" `
  -d '{}'
```

## Шаг 5: Проверка DNS/IPv6

```bash
# Проверить A запись
nslookup api.shortsai.ru

# Проверить AAAA запись (IPv6)
nslookup -type=AAAA api.shortsai.ru

# Если есть IPv6, проверить доступность
curl -6 -i https://api.shortsai.ru/health
```

