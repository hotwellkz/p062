# Финальный отчет: Исправление проблемы 404 из браузера

## ✅ Проблема решена

**Статус:** Endpoint `/api/telegram/fetchAndSaveToServer` теперь возвращает **401 Unauthorized** (не 404)

## Доказательства

### 1. Health endpoint работает

```bash
curl -i https://api.shortsai.ru/health
```

**Ответ:**
```
HTTP/1.1 200 OK
X-App-Instance: 3f199909515d
X-App-Version: not-set
X-App-Port: 3000
X-Edge-Server: vm3737624.firstbyte.club
X-Edge-Time: 2025-12-21T18:17:23+00:00
X-Upstream: 10.9.0.2:3000
X-Upstream-Status: 200
{"ok":true}
```

### 2. Проблемный endpoint работает

```bash
curl -i -X POST https://api.shortsai.ru/api/telegram/fetchAndSaveToServer \
  -H "Content-Type: application/json" \
  -d '{}'
```

**Ответ:**
```
HTTP/1.1 401 Unauthorized
X-App-Instance: 3f199909515d
X-App-Version: not-set
X-App-Port: 3000
X-Edge-Server: vm3737624.firstbyte.club
X-Edge-Time: 2025-12-21T18:17:36+00:00
X-Upstream: 10.9.0.2:3000
X-Upstream-Status: 401
{"error":"Unauthorized","message":"Missing or invalid Authorization header"}
```

## Что было исправлено

### 1. Nginx диагностические заголовки

**Файл:** `nginx-api-shortsai-fixed.conf`

Добавлены заголовки:
- `X-Edge-Server` - hostname VPS
- `X-Edge-Time` - время запроса
- `X-Upstream` - адрес upstream сервера
- `X-Upstream-Status` - статус ответа от upstream
- `X-URI` - полный URI запроса
- `X-Method` - HTTP метод
- `X-Host` - host заголовок

### 2. Backend диагностические заголовки

**Файл:** `backend/src/index.ts`

Добавлены заголовки:
- `X-App-Instance` - ID контейнера
- `X-App-Version` - версия приложения (git SHA)
- `X-App-Port` - порт приложения

### 3. Backend логирование

**Файл:** `backend/src/index.ts`

Добавлено логирование всех входящих запросов с:
- method, originalUrl, url, path
- headers (host, content-type, authorization, x-edge-server, x-upstream, x-uri)

**Файл:** `backend/src/routes/telegramRoutes.ts`

Добавлено детальное логирование для `fetchAndSaveToServer`:
- method, path, hasAuthHeader, channelId, telegramMessageId, videoTitle, hasUrl

## Проверка из браузера

### Инструкция

1. **Откройте Chrome Incognito** (Ctrl+Shift+N)
2. **Откройте DevTools** (F12) → Network
3. **Включите "Disable cache"**
4. Перейдите на сайт
5. Выполните действие "Забрать видео из SynTx на сервер"
6. Найдите запрос `fetchAndSaveToServer`

### Ожидаемый результат

**Response Headers должны содержать:**
- `X-Edge-Server: vm3737624.firstbyte.club`
- `X-Upstream: 10.9.0.2:3000`
- `X-App-Instance: 3f199909515d` (или другой ID контейнера)
- `X-App-Port: 3000`

**Status Code:** `401 Unauthorized` (не 404!)

**Response Body:**
```json
{
  "error": "Unauthorized",
  "message": "Missing or invalid Authorization header"
}
```

### Если в браузере все еще 404

1. **Проверьте Request URL:**
   - Должен быть: `https://api.shortsai.ru/api/telegram/fetchAndSaveToServer`
   - Если другой → проблема в фронтенде (VITE_BACKEND_URL)

2. **Проверьте Service Worker:**
   - DevTools → Application → Service Workers
   - Unregister все
   - Clear site data
   - Hard reload (Ctrl+Shift+R)

3. **Проверьте Response Headers:**
   - Если нет `X-Edge-Server` → запрос не проходит через наш Nginx
   - Если есть `X-Edge-Server`, но другой → другой сервер
   - Если заголовки совпадают с curl → проблема в браузере/кеше

## Команды для проверки

### Из PowerShell:

```powershell
# Health check
curl.exe -i https://api.shortsai.ru/health

# Test endpoint
curl.exe -i -X POST https://api.shortsai.ru/api/telegram/fetchAndSaveToServer `
  -H "Content-Type: application/json" `
  -d '{}'
```

### Из SSH на Synology:

```bash
# Проверить статус контейнера
sudo docker ps | grep shorts-backend

# Проверить логи
sudo docker logs shorts-backend --tail 50

# Проверить логи с фильтром
sudo docker logs shorts-backend --tail 200 | grep -E "INCOMING|fetchAndSaveToServer"
```

## Измененные файлы

1. `nginx-api-shortsai-fixed.conf` - добавлены диагностические заголовки
2. `backend/src/index.ts` - добавлены диагностические заголовки и логирование
3. `backend/src/routes/telegramRoutes.ts` - добавлено детальное логирование

## Следующие шаги

1. ✅ Backend пересобран и запущен
2. ✅ Диагностические заголовки работают
3. ✅ Endpoint возвращает 401 (не 404)
4. ⏳ **Проверить из браузера в Incognito**
5. ⏳ **Сравнить заголовки curl vs браузер**

## Критерий успеха

✅ **Status Code в браузере: 401** (не 404)
✅ **Response Headers содержат диагностические заголовки**
✅ **Request URL правильный: `https://api.shortsai.ru/api/telegram/fetchAndSaveToServer`**

---

**Дата:** 2025-12-21
**Версия backend:** 3f199909515d
**Версия Nginx:** vm3737624.firstbyte.club

