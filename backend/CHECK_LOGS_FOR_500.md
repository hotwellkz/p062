# Проверка логов для ошибки 500

## Проблема

POST запрос все еще возвращает 500, даже после исправления конфликта переменных.

## Проверка логов

На Synology выполните:

```bash
# Полные логи (последние 100 строк)
sudo docker logs shorts-backend --tail 100

# Только ошибки
sudo docker logs shorts-backend 2>&1 | grep -i "error\|exception\|failed"

# Логи с временными метками
sudo docker logs shorts-backend --tail 50 --timestamps
```

## Возможные причины

1. Ошибка в обработчике OPTIONS (может влиять на все запросы)
2. Ошибка в CORS middleware
3. Ошибка в authRequired middleware
4. Ошибка в самом роуте fetchAndSaveToServer

## Временное решение

Если проблема в обработчике OPTIONS, можно временно его отключить, так как Nginx уже обрабатывает OPTIONS:

```typescript
// Временно закомментировать
// app.options("*", (req, res) => { ... });
```

И полагаться только на Nginx обработку OPTIONS.

