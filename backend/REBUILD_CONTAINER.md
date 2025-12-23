# Пересборка контейнера

## Команды для выполнения на сервере

```bash
ssh -p 777 admin@hotwell.synology.me
cd /volume1/docker/shortsai/backend

# Остановить контейнер
sudo /usr/local/bin/docker compose down

# Пересобрать и запустить
sudo /usr/local/bin/docker compose up -d --build

# Проверить логи
sudo /usr/local/bin/docker compose logs backend --tail=30
```

## Проверка после пересборки

```bash
# Проверить статус
sudo /usr/local/bin/docker compose ps

# Проверить переменные окружения
sudo /usr/local/bin/docker compose exec backend sh -c 'env | grep FRONTEND_ORIGIN'

# Проверить работу CORS напрямую
curl -H "Origin: https://shortsai.ru" \
     -H "Access-Control-Request-Method: GET" \
     -X OPTIONS \
     http://localhost:3000/api/user-settings \
     -v 2>&1 | grep -i "access-control"
```

## Ожидаемый результат

- Контейнер должен быть в статусе `Up`
- `FRONTEND_ORIGIN=https://shortsai.ru` должен быть загружен
- CORS заголовки должны возвращаться при прямом доступе





