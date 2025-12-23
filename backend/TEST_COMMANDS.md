# Команды для тестирования диагностики

## Шаг 1: Обновление кода на Synology

В SSH сессии на Synology выполните:

```bash
cd /volume1/docker/shortsai/backend

# Остановить контейнер
sudo docker compose stop backend

# Пересобрать
sudo docker compose build --no-cache backend

# Запустить
sudo docker compose up -d backend

# Подождать 10 секунд
sleep 10

# Проверить логи
sudo docker logs shorts-backend --tail 50 | grep -E "routes registered|listening"
```

## Шаг 2: Тестирование диагностического endpoint

### С VPS (159.255.37.158):
```bash
curl -i https://api.shortsai.ru/health
```

Сохраните вывод, особенно поле `diagnostic`.

### Из PowerShell (локально):
```powershell
curl.exe -i https://api.shortsai.ru/health
```

Сохраните вывод и сравните `diagnostic` поля:
- `hostname`
- `pid`
- `containerId`
- `routesHash`

**Если поля разные → значит разные инстансы backend!**

## Шаг 3: Тестирование проблемного endpoint

### С VPS:
```bash
curl -i -X POST https://api.shortsai.ru/api/telegram/fetchAndSaveToServer \
  -H "Content-Type: application/json" \
  -d '{}'
```

### Из PowerShell:
```powershell
curl.exe -i -X POST https://api.shortsai.ru/api/telegram/fetchAndSaveToServer `
  -H "Content-Type: application/json" `
  -d '{}'
```

### Из браузера:
1. Откройте DevTools (F12)
2. Перейдите на вкладку Network
3. Выполните действие "Забрать видео из SynTx на сервер"
4. Найдите запрос к `fetchAndSaveToServer`
5. Посмотрите:
   - Request URL (полный путь)
   - Status Code
   - Response Headers
   - Response Body

## Шаг 4: Сравнение результатов

Сравните:
- **Status Code**: должен быть одинаковый (401 без токена, не 404)
- **Response Headers**: особенно `X-Powered-By`, `Server`
- **Diagnostic fields** из `/health`: должны быть одинаковые, если один инстанс

## Ожидаемый результат

После обновления кода:
- `/health` должен возвращать `diagnostic` объект с информацией об инстансе
- `/api/telegram/fetchAndSaveToServer` должен возвращать 401 (не 404) из всех источников
- Если из браузера все еще 404, а из curl 401 → значит разные инстансы или проблема в Nginx routing

