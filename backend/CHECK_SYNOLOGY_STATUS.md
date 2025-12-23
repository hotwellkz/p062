# Проверка статуса на Synology

## Проблема: 502 Bad Gateway
Backend недоступен по адресу `10.9.0.2:3000` с VPS.

## Команды для проверки на Synology

Выполните в SSH сессии на Synology:

```bash
# 1. Проверить статус контейнера
sudo docker ps | grep shorts-backend

# 2. Проверить логи контейнера
sudo docker logs shorts-backend --tail 50

# 3. Проверить, слушает ли контейнер на порту 3000
sudo docker exec shorts-backend netstat -tlnp | grep 3000 || sudo docker exec shorts-backend ss -tlnp | grep 3000

# 4. Проверить WireGuard интерфейс
sudo ip addr show wg0 || sudo wg show

# 5. Проверить доступность порта 3000 на WireGuard IP
curl -i http://10.9.0.2:3000/health || echo "Backend недоступен"

# 6. Проверить переменные окружения контейнера
sudo docker exec shorts-backend printenv | grep -E "PORT|NODE_ENV"

# 7. Проверить, запущен ли контейнер
sudo docker ps -a | grep shorts-backend
```

## Возможные причины 502:

1. **Контейнер не запущен** → запустить: `sudo docker compose up -d backend`
2. **Контейнер слушает на другом порту** → проверить PORT в .env.production
3. **WireGuard туннель не работает** → проверить статус WireGuard
4. **Контейнер упал** → проверить логи: `sudo docker logs shorts-backend --tail 100`

## Быстрое исправление:

```bash
cd /volume1/docker/shortsai/backend
sudo docker compose up -d backend
sleep 5
sudo docker logs shorts-backend --tail 30
```

