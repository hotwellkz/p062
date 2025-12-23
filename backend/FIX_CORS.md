# Исправление ошибки CORS

## Проблема

Ошибка: `No 'Access-Control-Allow-Origin' header is present on the requested resource`

Причина: Переменная `FRONTEND_ORIGIN` не установлена или установлена неправильно в `.env.production`.

## Решение

### Шаг 1: Проверить текущее значение FRONTEND_ORIGIN

Выполните на сервере:

```bash
ssh -p 777 admin@hotwell.synology.me
cd /volume1/docker/shortsai/backend

# Проверить значение FRONTEND_ORIGIN
grep FRONTEND_ORIGIN .env.production
```

### Шаг 2: Установить правильное значение

Если переменная отсутствует или неправильная, установите:

```bash
# Добавить или обновить FRONTEND_ORIGIN
echo "FRONTEND_ORIGIN=https://shortsai.ru" >> .env.production

# Или если переменная уже есть, замените её:
sed -i 's|^FRONTEND_ORIGIN=.*|FRONTEND_ORIGIN=https://shortsai.ru|' .env.production
```

### Шаг 3: Проверить значение

```bash
grep FRONTEND_ORIGIN .env.production
```

Должно быть:
```
FRONTEND_ORIGIN=https://shortsai.ru
```

### Шаг 4: Перезапустить контейнер

```bash
sudo /usr/local/bin/docker compose down
sudo /usr/local/bin/docker compose up -d
```

### Шаг 5: Проверить логи при старте

```bash
sudo /usr/local/bin/docker compose logs backend --tail=20 | grep -i "cors\|origin\|frontend"
```

### Шаг 6: Проверить переменную в контейнере

```bash
sudo /usr/local/bin/docker compose exec backend sh -c 'env | grep FRONTEND_ORIGIN'
```

Должно быть:
```
FRONTEND_ORIGIN=https://shortsai.ru
```

## Альтернативный метод: через SSH с редактированием

```bash
ssh -p 777 admin@hotwell.synology.me
cd /volume1/docker/shortsai/backend

# Открыть файл в редакторе (vi доступен)
vi .env.production
```

В vi:
1. Нажмите `/FRONTEND_ORIGIN` для поиска
2. Нажмите `i` для вставки
3. Измените или добавьте: `FRONTEND_ORIGIN=https://shortsai.ru`
4. Нажмите `Esc`
5. Введите `:wq` и нажмите `Enter`

Затем перезапустите контейнер.

## Проверка работы CORS

После перезапуска откройте frontend и проверьте консоль браузера. Ошибки CORS должны исчезнуть.

Также можно проверить через curl:

```bash
curl -H "Origin: https://shortsai.ru" \
     -H "Access-Control-Request-Method: GET" \
     -H "Access-Control-Request-Headers: Content-Type" \
     -X OPTIONS \
     https://api.hotwell.synology.me/api/user-settings \
     -v
```

Должен вернуться заголовок:
```
Access-Control-Allow-Origin: https://shortsai.ru
```

## Важно

- Переменная `FRONTEND_ORIGIN` должна быть установлена **до** запуска контейнера
- После изменения `.env.production` контейнер нужно **перезапустить**
- Значение должно быть **точно** `https://shortsai.ru` (без завершающего слеша)





