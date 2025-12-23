# Финальная диагностика и исправление проблемы 404 из браузера

## ✅ Выполнено

1. ✅ **Nginx обновлен** - добавлены диагностические заголовки
2. ✅ **Backend файлы загружены** на Synology
3. ✅ **Диагностические заголовки работают** в Nginx:
   - `X-Edge-Server: vm3737624.firstbyte.club`
   - `X-Upstream: 10.9.0.2:3000`
   - `X-Upstream-Status: 200`

## Следующие шаги

### 1. Пересобрать backend на Synology

В SSH сессии на Synology:

```bash
cd /volume1/docker/shortsai/backend

# Пересобрать
sudo docker compose build --no-cache backend

# Запустить
sudo docker compose up -d backend

# Проверить статус
sleep 5
sudo docker ps | grep shorts-backend
sudo docker logs shorts-backend --tail 30
```

### 2. Проверить диагностические заголовки

**Из PowerShell:**
```powershell
# Проверить все заголовки
curl.exe -i https://api.shortsai.ru/health

# Проверить проблемный endpoint
curl.exe -i -X POST https://api.shortsai.ru/api/telegram/fetchAndSaveToServer `
  -H "Content-Type: application/json" `
  -d '{}'
```

**Ожидаемые заголовки:**
- `X-Edge-Server` - hostname VPS
- `X-Upstream` - 10.9.0.2:3000
- `X-App-Instance` - hostname контейнера
- `X-Request-ID` - уникальный ID

### 3. Проверить из браузера

1. **Откройте сайт в Chrome Incognito** (без расширений)
2. Откройте DevTools (F12) → Network
3. Выполните действие "Забрать видео из SynTx на сервер"
4. Найдите запрос `fetchAndSaveToServer`
5. Проверьте:
   - **Request URL** - должен быть `https://api.shortsai.ru/api/telegram/fetchAndSaveToServer`
   - **Status Code** - должен быть 401 (не 404)
   - **Response Headers** - должны быть видны:
     - `X-Edge-Server`
     - `X-Upstream`
     - `X-App-Instance`
     - `X-Request-ID`

### 4. Если в браузере все еще 404

**Проверить Service Worker:**
1. DevTools → Application → Service Workers
2. Если есть зарегистрированные → Unregister
3. Clear site data
4. Hard reload (Ctrl+Shift+R)

**Проверить, какой URL использует фронтенд:**
1. DevTools → Console
2. Выполните: `console.log('Backend URL:', import.meta.env.VITE_BACKEND_URL)`
3. Или проверьте в Network → запрос → Headers → Request URL

**Проверить, нет ли кеша:**
1. DevTools → Network → включите "Disable cache"
2. Hard reload (Ctrl+Shift+R)

### 5. Сравнить заголовки curl vs браузер

**Если заголовки разные:**
- Разные `X-Edge-Server` → разные серверы
- Разные `X-Upstream` → разные upstream
- Нет заголовков в браузере → запрос не проходит через наш Nginx

**Если заголовки одинаковые, но статус разный:**
- Проблема в backend логике или маршрутизации
- Проверить логи backend на Synology

## Ожидаемый результат

После всех проверок:
- ✅ В браузере Status Code: **401** (не 404)
- ✅ В Response Headers видны диагностические заголовки
- ✅ В backend логах есть запись с requestId

## Команды для проверки логов

На Synology:
```bash
sudo docker logs shorts-backend --tail 100 | grep -E "INCOMING|fetchAndSaveToServer|requestId"
```

