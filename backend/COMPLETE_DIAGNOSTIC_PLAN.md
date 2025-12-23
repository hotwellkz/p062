# Полный план диагностики проблемы 404 из браузера

## Найденные факты

1. ✅ Nginx конфиг для `api.shortsai.ru` правильный: `proxy_pass http://10.9.0.2:3000;`
2. ⚠️ Есть старый конфиг `api.hotwell.synology.me` → `http://10.8.0.2:5000` (только HTTP, без HTTPS)
3. ✅ С curl с VPS endpoint возвращает 401 (маршрут существует)
4. ❌ С браузера endpoint возвращает 404

## Возможные причины

### A) DNS/IPv6 проблема
- Браузер может резолвить на другой IP (IPv6)
- Проверить: `nslookup api.shortsai.ru` и `nslookup -type=AAAA api.shortsai.ru`

### B) Фронтенд использует старый URL
- Проверить в коде фронтенда: какой `VITE_BACKEND_URL` используется
- Может быть кэш в браузере

### C) Разные инстансы backend
- Нужно добавить диагностический endpoint `/health` с информацией об инстансе
- Сравнить ответы из разных источников

### D) Nginx default server перехватывает
- Проверить, нет ли default server block, который перехватывает запросы

## План действий

### Шаг 1: Обновить код на Synology с диагностическим endpoint

```bash
# На Synology в SSH сессии:
cd /volume1/docker/shortsai/backend

# Загрузить обновленный index.ts (я подготовлю команду)
# Или скопировать вручную

# Пересобрать
sudo docker compose build --no-cache backend
sudo docker compose up -d backend
```

### Шаг 2: Тестирование диагностического endpoint

**С VPS:**
```bash
curl -i https://api.shortsai.ru/health
```

**Из PowerShell (локально):**
```powershell
curl.exe -i https://api.shortsai.ru/health
```

**Сравнить:**
- `diagnostic.hostname`
- `diagnostic.pid`
- `diagnostic.containerId`
- `diagnostic.routesHash`

Если разные → значит разные инстансы!

### Шаг 3: Тестирование проблемного endpoint

**С VPS:**
```bash
curl -i -X POST https://api.shortsai.ru/api/telegram/fetchAndSaveToServer \
  -H "Content-Type: application/json" \
  -d '{}'
```

**Из PowerShell:**
```powershell
curl.exe -i -X POST https://api.shortsai.ru/api/telegram/fetchAndSaveToServer `
  -H "Content-Type: application/json" `
  -d '{}'
```

**Из браузера DevTools:**
- Открыть Network tab
- Выполнить действие "Забрать видео из SynTx на сервер"
- Посмотреть Request URL и Response

### Шаг 4: Проверка фронтенда

Проверить в коде фронтенда:
- Какой `VITE_BACKEND_URL` используется?
- Может быть кэш в браузере?

### Шаг 5: Проверка Nginx default server

```bash
ssh root@159.255.37.158 "sudo nginx -T 2>&1 | grep -B 5 -A 20 'default_server'"
```

## Ожидаемый результат диагностики

После добавления диагностического endpoint мы сможем точно определить:
- Один ли инстанс обслуживает запросы
- Куда реально попадают запросы из браузера
- В чем разница между curl и браузером

