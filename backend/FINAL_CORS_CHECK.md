# Финальная проверка CORS

## ✅ Файл .env.production найден

Файл содержит:
- `FRONTEND_ORIGIN=https://shortsai.ru,https://www.shortsai.ru` ✅
- `PORT=7777` ✅
- Все необходимые переменные ✅

## Перезапуск контейнера для загрузки переменных

Выполните на сервере:

```bash
# Перезапустить контейнер
sudo /usr/local/bin/docker compose restart

# Проверить переменные в контейнере
sudo /usr/local/bin/docker compose exec backend sh -c 'env | grep FRONTEND_ORIGIN'
```

**Ожидаемый результат:**
```
FRONTEND_ORIGIN=https://shortsai.ru,https://www.shortsai.ru
```

## Проверка CORS

### Тест 1: Прямой доступ к контейнеру

```bash
curl -H "Origin: https://shortsai.ru" \
     -H "Access-Control-Request-Method: GET" \
     -X OPTIONS \
     http://localhost:3000/api/user-settings \
     -v 2>&1 | grep -i "access-control"
```

**Ожидаемый результат:**
```
< Access-Control-Allow-Origin: https://shortsai.ru
< Access-Control-Allow-Credentials: true
< Access-Control-Allow-Methods: GET,HEAD,PUT,PATCH,POST,DELETE
```

### Тест 2: Через Reverse Proxy

```bash
curl -H "Origin: https://shortsai.ru" \
     -H "Access-Control-Request-Method: GET" \
     -H "Access-Control-Request-Headers: Content-Type,Authorization" \
     -X OPTIONS \
     https://api.hotwell.synology.me/api/user-settings \
     -v 2>&1 | grep -i "access-control"
```

**Если заголовки не возвращаются** → нужно настроить Reverse Proxy (см. `SYNO_REVERSE_PROXY_SETUP.md`)

## Проверка в браузере

1. Откройте https://shortsai.ru
2. Откройте консоль разработчика (F12 → Console)
3. Проверьте, что ошибки CORS исчезли
4. Проверьте Network tab - запросы должны проходить успешно

## Важно: Порт

В `.env.production` указан `PORT=7777`, но в `docker-compose.yml` проброшен порт `3000`. 

Проверьте, какой порт использует контейнер:

```bash
sudo /usr/local/bin/docker compose exec backend sh -c 'env | grep PORT'
```

Если контейнер использует порт 3000, а Reverse Proxy настроен на другой порт, нужно либо:
1. Изменить `PORT=3000` в `.env.production`
2. Или изменить порт в `docker-compose.yml` на `7777:7777`

## Если CORS всё ещё не работает

1. **Проверьте Reverse Proxy** - он может блокировать заголовки
2. **Проверьте логи контейнера** на наличие ошибок CORS
3. **Проверьте, что переменная загружена** в контейнер





