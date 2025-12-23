# Итоговый отчет: Исправление 404 для /api/telegram/fetchAndSaveToServer

## Проблема
POST `https://api.shortsai.ru/api/telegram/fetchAndSaveToServer` возвращал 404 Not Found.

## Диагностика

### Проверено:
1. ✅ **Nginx конфиг** - правильный: `proxy_pass http://10.9.0.2:3000;` (без слэша, путь сохраняется)
2. ✅ **Код содержит маршрут**: `router.post("/fetchAndSaveToServer", ...)` в `telegramRoutes.ts` (строка 997)
3. ✅ **Маршрут подключен**: `app.use("/api/telegram", telegramRoutes)` в `index.ts` (строка 128)
4. ✅ **Полный путь должен быть**: `/api/telegram/fetchAndSaveToServer`

### Вероятная причина:
Старый код в Docker контейнере. Код обновлен локально, но контейнер на Synology использует старый образ.

## Внесенные изменения

### 1. Добавлено диагностическое логирование (`backend/src/index.ts`)

**Строки 111-126**: Добавлен middleware для логирования всех входящих запросов ДО обработки роутами:

```typescript
// Диагностическое логирование всех входящих запросов
app.use((req, res, next) => {
  Logger.info("INCOMING REQUEST", {
    method: req.method,
    originalUrl: req.originalUrl,
    url: req.url,
    path: req.path,
    baseUrl: req.baseUrl,
    headers: {
      host: req.headers.host,
      "content-type": req.headers["content-type"],
      authorization: req.headers.authorization ? `${req.headers.authorization.substring(0, 20)}...` : "none"
    }
  });
  next();
});
```

**Строки 143-164**: Обновлено логирование зарегистрированных маршрутов с примерами путей.

## Команды для исправления на Synology

### Шаг 1: Пересборка контейнера

Выполните на Synology через SSH:

```bash
cd /volume1/docker/shortsai
sudo docker compose build --no-cache shorts-backend
sudo docker compose up -d shorts-backend
```

### Шаг 2: Проверка логов

```bash
# Дождаться запуска (5-10 секунд)
sleep 5

# Проверить логи запуска
sudo docker logs shorts-backend --tail 50 | grep -E "routes registered|listening|INCOMING"
```

**Ожидаемый вывод:**
```
Backend routes registered { routes: [...], examplePaths: [...] }
Backend listening on port 3000
```

### Шаг 3: Тестирование endpoint

**Без токена (должен вернуть 401, НЕ 404):**
```bash
curl -i -X POST https://api.shortsai.ru/api/telegram/fetchAndSaveToServer \
  -H "Content-Type: application/json" \
  -d '{"channelId":"test"}'
```

**С токеном (если есть):**
```bash
curl -i -X POST https://api.shortsai.ru/api/telegram/fetchAndSaveToServer \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{"channelId":"test","url":"https://example.com/video.mp4"}'
```

### Шаг 4: Проверка логов после запроса

```bash
sudo docker logs shorts-backend --tail 20 | grep -E "INCOMING|fetchAndSaveToServer"
```

**Ожидаемый вывод при успехе:**
```
INCOMING REQUEST { method: 'POST', originalUrl: '/api/telegram/fetchAndSaveToServer', ... }
fetchAndSaveToServer: REQUEST RECEIVED { ... }
```

## Альтернативный способ: использование скрипта

Скопируйте файл `backend/SYNOLOGY_REBUILD_COMMANDS.sh` на Synology и выполните:

```bash
chmod +x SYNOLOGY_REBUILD_COMMANDS.sh
./SYNOLOGY_REBUILD_COMMANDS.sh
```

## Проверка из браузера

После пересборки контейнера:
1. Откройте DevTools (F12)
2. Перейдите на вкладку Network
3. Выполните действие, которое вызывает `POST /api/telegram/fetchAndSaveToServer`
4. Проверьте статус ответа - должен быть **НЕ 404** (может быть 401 без токена или 200/400/500 с токеном)

## Измененные файлы

- `backend/src/index.ts` - добавлено логирование входящих запросов и обновлено логирование маршрутов

## Команды для повторной проверки

### Локально (PowerShell):
```powershell
curl.exe -i -X POST https://api.shortsai.ru/api/telegram/fetchAndSaveToServer `
  -H "Content-Type: application/json" `
  -d '{\"channelId\":\"test\"}'
```

### На Synology:
```bash
sudo docker logs shorts-backend --tail 100 | grep "INCOMING"
```

## Ожидаемый результат

После пересборки контейнера:
- ✅ Запрос `POST /api/telegram/fetchAndSaveToServer` должен возвращать **НЕ 404**
- ✅ В логах должны появляться записи `INCOMING REQUEST` для каждого запроса
- ✅ Без токена: 401 Unauthorized
- ✅ С валидным токеном: 200 или 400/500 с ошибкой валидации (но не 404)

## Если проблема сохраняется

1. Проверьте, что файл `index.ts` обновлен в контейнере:
   ```bash
   sudo docker exec -it shorts-backend cat /app/dist/index.js | grep "INCOMING"
   ```

2. Проверьте, что контейнер использует правильный образ:
   ```bash
   sudo docker ps | grep shorts-backend
   sudo docker images | grep shorts-backend
   ```

3. Проверьте логи Nginx на VPS (если нужно):
   ```bash
   ssh root@159.255.37.158 "tail -20 /var/log/nginx/error.log"
   ```

