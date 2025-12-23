# Проверка ошибки POST 500

## Проблема

- ✅ OPTIONS возвращает 204 (работает)
- ❌ POST возвращает 500 (не работает)

## Возможные причины

1. Ошибка в обработчике OPTIONS в backend (может влиять на POST)
2. Ошибка в authRequired middleware
3. Ошибка в самом роуте fetchAndSaveToServer

## Проверка логов

На Synology выполните:

```bash
sudo docker logs shorts-backend --tail 100
```

Ищите:
- Ошибки при обработке POST
- Stack trace
- "INCOMING REQUEST" для POST запроса

## Проверка кода

Проверьте, что обработчик OPTIONS не влияет на POST запросы.

В `backend/src/index.ts`:
- `app.options("*", ...)` должен обрабатывать ТОЛЬКО OPTIONS
- POST запросы должны проходить дальше к роутам

## Временное решение

Если проблема в обработчике OPTIONS, можно временно отключить его и полагаться только на Nginx обработку OPTIONS.

