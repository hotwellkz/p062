# Проверка CORS после установки FRONTEND_ORIGIN

## ✅ Переменная установлена в .env.production

```
FRONTEND_ORIGIN=https://shortsai.ru
```

## Проверка загрузки переменной в контейнер

Выполните на сервере:

```bash
# Проверить переменную в контейнере
sudo /usr/local/bin/docker compose exec backend sh -c 'env | grep FRONTEND_ORIGIN'
```

**Ожидаемый результат:**
```
FRONTEND_ORIGIN=https://shortsai.ru
```

## Если переменная не загружена

### Вариант 1: Перезапустить контейнер

```bash
sudo /usr/local/bin/docker compose restart
```

### Вариант 2: Полный перезапуск

```bash
sudo /usr/local/bin/docker compose down
sudo /usr/local/bin/docker compose up -d
```

## Проверка логов при старте

```bash
sudo /usr/local/bin/docker compose logs backend --tail=50 | grep -i "cors\|origin\|frontend"
```

## Тест CORS через curl

```bash
# Проверить preflight запрос (OPTIONS)
curl -H "Origin: https://shortsai.ru" \
     -H "Access-Control-Request-Method: GET" \
     -H "Access-Control-Request-Headers: Content-Type,Authorization" \
     -X OPTIONS \
     https://api.hotwell.synology.me/api/user-settings \
     -v 2>&1 | grep -i "access-control"
```

**Ожидаемый результат:**
```
< Access-Control-Allow-Origin: https://shortsai.ru
< Access-Control-Allow-Methods: GET,HEAD,PUT,PATCH,POST,DELETE
< Access-Control-Allow-Credentials: true
```

## Если CORS всё ещё не работает

### Проверка 1: Убедиться, что .env.production загружается

В `docker-compose.yml` должна быть строка:
```yaml
env_file:
  - .env.production
```

### Проверка 2: Проверить синтаксис .env.production

```bash
# Проверить, нет ли проблем с синтаксисом
cat .env.production | grep FRONTEND_ORIGIN
```

Должно быть:
```
FRONTEND_ORIGIN=https://shortsai.ru
```

**НЕ должно быть:**
- Пробелы вокруг `=`
- Кавычки вокруг значения
- Завершающие пробелы

### Проверка 3: Проверить логи ошибок

```bash
sudo /usr/local/bin/docker compose logs backend | grep -i "error\|cors\|not allowed" | tail -20
```

## Альтернативное решение: Установить через environment в docker-compose.yml

Если переменная не загружается из .env.production, можно добавить напрямую:

```yaml
environment:
  - PORT=${BACKEND_PORT:-3000}
  - NODE_ENV=production
  - FRONTEND_ORIGIN=https://shortsai.ru
```

Затем перезапустить:
```bash
sudo /usr/local/bin/docker compose down
sudo /usr/local/bin/docker compose up -d --build
```

## Проверка работы после исправления

1. Откройте frontend в браузере: https://shortsai.ru
2. Откройте консоль разработчика (F12)
3. Проверьте, что ошибки CORS исчезли
4. Проверьте, что запросы к API проходят успешно





