# Исправление отдачи медиа-файлов по URL

## Что было исправлено

1. **Добавлено детальное логирование:**
   - Вход в роут с параметрами
   - Вычисленный путь к файлу
   - Проверка существования файла
   - Статус ответа (200/206/404)
   - Время выполнения запроса

2. **Улучшена обработка ошибок:**
   - Более информативные сообщения об ошибках
   - Логирование stack trace для диагностики

3. **Улучшена диагностика:**
   - Логирование STORAGE_ROOT
   - Логирование resolved путей
   - Логирование статистики файла

## Проверка работы

### 1. Пересобрать контейнер

```bash
ssh -p 777 admin@hotwell.synology.me
cd /volume1/docker/shortsai/backend
sudo /usr/local/bin/docker compose down
sudo /usr/local/bin/docker compose build --no-cache
sudo /usr/local/bin/docker compose up -d
```

### 2. Проверить логи при запросе

```bash
# В одном терминале - следить за логами
sudo /usr/local/bin/docker compose logs -f backend

# В другом терминале - сделать запрос
curl -I https://api.hotwell.synology.me/api/media/hotwell-kz-at-gmail-com/live-G8AXD07P/Paren_i_devushka_na_kukhne.mp4
```

### 3. Проверить внутри контейнера

```bash
# Проверить что файл существует
sudo /usr/local/bin/docker compose exec backend ls -la /app/storage/videos/hotwell-kz-at-gmail-com/live-G8AXD07P/

# Проверить STORAGE_ROOT
sudo /usr/local/bin/docker compose exec backend sh -c 'echo $STORAGE_ROOT'

# Проверить прямой доступ
sudo /usr/local/bin/docker compose exec backend curl -I http://127.0.0.1:3000/api/media/hotwell-kz-at-gmail-com/live-G8AXD07P/Paren_i_devushka_na_kukhne.mp4
```

### 4. Проверить снаружи

```bash
# Health check
curl -I https://api.hotwell.synology.me/health

# Media file
curl -I https://api.hotwell.synology.me/api/media/hotwell-kz-at-gmail-com/live-G8AXD07P/Paren_i_devushka_na_kukhne.mp4

# С Range запросом (для проверки 206)
curl -I -H "Range: bytes=0-1023" https://api.hotwell.synology.me/api/media/hotwell-kz-at-gmail-com/live-G8AXD07P/Paren_i_devushka_na_kukhne.mp4
```

## Ожидаемые результаты

### Health check:
```
HTTP/1.1 200 OK
Content-Type: application/json
```

### Media file (без Range):
```
HTTP/1.1 200 OK
Content-Type: video/mp4
Content-Length: <размер файла>
Accept-Ranges: bytes
Cache-Control: public, max-age=3600
```

### Media file (с Range):
```
HTTP/1.1 206 Partial Content
Content-Range: bytes 0-1023/<размер файла>
Content-Length: 1024
Content-Type: video/mp4
Accept-Ranges: bytes
```

## Логи для диагностики

При запросе файла в логах должно появиться:

```
MediaRoutes: Request received { userSlug, channelSlug, fileName, url, method }
MediaRoutes: Path calculation { storageRoot, filePath, resolvedPath }
MediaRoutes: File exists { filePath, exists: true }
MediaRoutes: File stats { size, isFile: true }
MediaRoutes: File served (200 OK) { size, contentType, statusCode: 200 }
```

Если файл не найден:
```
MediaRoutes: File not found { filePath, exists: false, storageRoot, resolvedPath }
```

## Возможные проблемы

1. **404 Not Found:**
   - Проверить что файл существует в контейнере
   - Проверить STORAGE_ROOT в env
   - Проверить что volume смонтирован правильно

2. **403 Forbidden:**
   - Проверить что путь не содержит `..`
   - Проверить что resolvedPath начинается с resolvedRoot

3. **500 Internal Server Error:**
   - Проверить логи на наличие ошибок
   - Проверить права доступа к файлу





