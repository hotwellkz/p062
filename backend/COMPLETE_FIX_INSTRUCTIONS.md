# Полная инструкция по исправлению проблемы 404 из браузера

## ✅ Текущий статус

- ✅ **Nginx обновлен** - диагностические заголовки работают
- ✅ **Endpoint работает из curl** - возвращает 401 (не 404)
- ✅ **Диагностические заголовки видны:**
  - `X-Edge-Server: vm3737624.firstbyte.club`
  - `X-Upstream: 10.9.0.2:3000`
  - `X-Upstream-Status: 401`

## Шаг 1: Обновить backend на Synology

В SSH сессии на Synology:

```bash
cd /volume1/docker/shortsai/backend

# Пересобрать с новыми диагностическими заголовками
sudo docker compose build --no-cache backend

# Запустить
sudo docker compose up -d backend

# Проверить
sleep 5
sudo docker ps | grep shorts-backend
sudo docker logs shorts-backend --tail 30
```

## Шаг 2: Проверить из браузера

### A) Чистый тест в Incognito

1. Откройте Chrome Incognito (Ctrl+Shift+N)
2. Откройте DevTools (F12) → Network
3. Включите "Disable cache"
4. Перейдите на сайт
5. Выполните действие "Забрать видео из SynTx на сервер"
6. Найдите запрос `fetchAndSaveToServer`

### B) Проверка Response Headers

В DevTools → Network → запрос → Headers → Response Headers проверьте:

**Должны быть видны:**
- `X-Edge-Server: vm3737624.firstbyte.club`
- `X-Upstream: 10.9.0.2:3000`
- `X-App-Instance` (от backend)
- `X-Request-ID` (от backend)

**Если заголовков НЕТ:**
- Запрос не проходит через наш Nginx
- Возможно, используется другой сервер/прокси/CDN
- Проверить DNS и маршрутизацию

**Если заголовки ЕСТЬ, но статус 404:**
- Проблема в backend маршрутизации
- Проверить логи backend на Synology

### C) Проверка Request URL

В DevTools → Network → запрос → Headers → General проверьте:

**Request URL должен быть:**
`https://api.shortsai.ru/api/telegram/fetchAndSaveToServer`

**Если URL другой:**
- Фронтенд использует неправильный `VITE_BACKEND_URL`
- Проверить переменные окружения на Netlify
- Пересобрать фронтенд

## Шаг 3: Проверка Service Worker и кеша

1. DevTools → Application → Service Workers
2. Если есть зарегистрированные → **Unregister**
3. DevTools → Application → Clear storage → **Clear site data**
4. Hard reload: **Ctrl+Shift+R**

## Шаг 4: Проверка переменных окружения фронтенда

### На Netlify:

1. Откройте Netlify Dashboard
2. Site settings → Environment variables
3. Проверьте `VITE_BACKEND_URL`
4. Должно быть: `https://api.shortsai.ru`

### В браузере Console:

```javascript
console.log('Backend URL:', import.meta.env.VITE_BACKEND_URL);
```

Должно вывести: `https://api.shortsai.ru`

## Шаг 5: Сравнение заголовков

### Из PowerShell (curl):
```powershell
curl.exe -i -X POST https://api.shortsai.ru/api/telegram/fetchAndSaveToServer `
  -H "Content-Type: application/json" `
  -d '{}'
```

### Из браузера:
Скопируйте Response Headers из DevTools

**Сравните:**
- `X-Edge-Server` - должны совпадать
- `X-Upstream` - должны совпадать
- `X-App-Instance` - должны совпадать
- `X-Request-ID` - должны быть разные (новый запрос)

## Ожидаемый результат

После всех проверок:
- ✅ Status Code в браузере: **401** (не 404)
- ✅ Response Headers содержат диагностические заголовки
- ✅ Request URL правильный: `https://api.shortsai.ru/api/telegram/fetchAndSaveToServer`
- ✅ В backend логах есть запись с requestId

## Если проблема сохраняется

1. **Скопируйте Response Headers из браузера** (если есть)
2. **Скопируйте Request URL** из браузера
3. **Проверьте логи backend:**
   ```bash
   sudo docker logs shorts-backend --tail 200 | grep -E "INCOMING|fetchAndSaveToServer"
   ```
4. **Сравните с curl заголовками**

Это поможет определить, попадает ли запрос из браузера на тот же сервер.

