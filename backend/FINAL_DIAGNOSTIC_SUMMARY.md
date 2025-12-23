# Итоговая диагностика проблемы 404

## Текущий статус

✅ **Контейнер запущен** (статус "Up")
❌ **Backend недоступен** через WireGuard (Connection reset by peer)
❌ **502 Bad Gateway** при обращении через Nginx

## Найденные проблемы

1. **Контейнер постоянно перезапускался** - исправлено откатом /health к простой версии
2. **Backend недоступен по 10.9.0.2:3000** - возможно проблема с WireGuard или backend еще не полностью запустился

## Следующие шаги для диагностики

### На Synology (в SSH сессии):

```bash
# 1. Проверить логи более детально
sudo docker logs shorts-backend --tail 100

# 2. Проверить, слушает ли backend на порту 3000
sudo docker exec shorts-backend netstat -tlnp | grep 3000
# или
sudo docker exec shorts-backend ss -tlnp | grep 3000

# 3. Проверить доступность локально на Synology
curl -i http://localhost:3000/health
curl -i http://127.0.0.1:3000/health

# 4. Проверить переменные окружения
sudo docker exec shorts-backend printenv | grep -E "PORT|NODE_ENV"

# 5. Проверить WireGuard
sudo wg show
ip addr show wg0

# 6. Проверить маршруты
ip route | grep 10.9
```

### На VPS:

```bash
# Проверить доступность через WireGuard
ping 10.9.0.2
curl -i http://10.9.0.2:3000/health

# Проверить через публичный домен
curl -i https://api.shortsai.ru/health
curl -i -X POST https://api.shortsai.ru/api/telegram/fetchAndSaveToServer \
  -H "Content-Type: application/json" \
  -d '{}'
```

## Возможные причины

1. **Backend еще не полностью запустился** - нужно подождать несколько секунд
2. **Проблема с WireGuard туннелем** - проверить статус WireGuard
3. **Backend падает сразу после запуска** - проверить логи на ошибки
4. **Проблема с портом** - проверить, на каком порту слушает backend

## Ожидаемый результат после исправления

- `/health` возвращает `{"ok": true}` (200)
- `/api/telegram/fetchAndSaveToServer` возвращает 401 без токена (не 404, не 502)
- Backend доступен по `http://10.9.0.2:3000` с VPS

