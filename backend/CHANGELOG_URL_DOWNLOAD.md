# Изменения: Поддержка скачивания видео по URL

**Дата:** 21 декабря 2025  
**Ветка:** `feature/url-download`

## Описание

Добавлена поддержка скачивания видео по URL (новая схема Syntax AI в Telegram). Backend теперь может:
- Принимать URL вместо file_id из Telegram
- Следовать редиректам (до 10)
- Скачивать прямые mp4 файлы
- Извлекать mp4 URL из HTML страниц
- Использовать Playwright для сложных случаев (опционально)

## Изменённые файлы

### Новые файлы:
- `backend/src/services/urlDownloader.ts` - сервис для скачивания по URL
- `backend/src/scripts/test_download_url.ts` - тестовый скрипт

### Изменённые файлы:
- `backend/src/routes/telegramRoutes.ts` - добавлена поддержка параметра `url` в endpoint `/fetchLatestVideoToDrive`

## Новые ENV переменные

Добавьте в `backend/.env`:

```env
# Таймаут скачивания (мс)
DOWNLOAD_TIMEOUT_MS=60000

# Максимальный размер файла (MB)
DOWNLOAD_MAX_MB=500

# Максимальное количество редиректов
DOWNLOAD_MAX_REDIRECTS=10

# User-Agent для HTTP запросов
DOWNLOAD_USER_AGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"

# Временная директория для скачивания
TMP_DIR=/app/tmp

# Использовать Playwright для извлечения видео из сложных страниц (true/false)
PLAYWRIGHT_FALLBACK=false
```

**Примечание:** Если переменные не заданы, используются значения по умолчанию.

## Использование

### Endpoint: `POST /api/telegram/fetchLatestVideoToDrive`

**Старый способ (без изменений):**
```json
{
  "channelId": "channel123"
}
```
Скачивает последнее видео из Telegram и загружает в Google Drive.

**Новый способ (с URL):**
```json
{
  "channelId": "channel123",
  "url": "https://example.com/video.mp4"
}
```
Скачивает видео по URL и сохраняет в локальное storage.

### Тестовый скрипт

```bash
# Прямой mp4 URL
ts-node src/scripts/test_download_url.ts https://example.com/video.mp4

# HTML страница с видео
ts-node src/scripts/test_download_url.ts https://example.com/page-with-video.html
```

## Как работает

1. **Если передан `url`**:
   - Разрешает финальный URL (следует редиректам)
   - Пробует прямое скачивание (если это mp4)
   - Если HTML - парсит и ищет mp4 URL
   - Опционально использует Playwright для сложных случаев
   - Сохраняет в `STORAGE_ROOT/${userSlug}/${channelSlug}/`
   - Возвращает путь к файлу

2. **Если `url` не передан**:
   - Работает как раньше (Telegram → Google Drive)

## Совместимость

- ✅ Старая логика (без `url`) работает без изменений
- ✅ Формат ответа расширен, но обратно совместим
- ✅ Все существующие endpoint'ы работают как раньше

## Тестирование

### Локально:

1. Запустите backend:
   ```bash
   npm run dev
   ```

2. Протестируйте через curl:
   ```bash
   curl -X POST http://localhost:3000/api/telegram/fetchLatestVideoToDrive \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer YOUR_TOKEN" \
     -d '{"channelId": "test", "url": "https://example.com/video.mp4"}'
   ```

3. Или используйте тестовый скрипт:
   ```bash
   ts-node src/scripts/test_download_url.ts https://example.com/video.mp4
   ```

### На Synology:

После деплоя проверьте:
```bash
curl -X POST https://api.shortsai.ru/api/telegram/fetchLatestVideoToDrive \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{"channelId": "test", "url": "https://example.com/video.mp4"}'
```

## Откат изменений

Если нужно откатить:

```bash
cd backend
git checkout main
git branch -D feature/url-download
```

Или через revert:
```bash
git revert <commit-hash>
```

## Зависимости

### Обязательные:
- `axios` - уже установлен ✅

### Опциональные (только если `PLAYWRIGHT_FALLBACK=true`):
- `playwright` - нужно установить:
  ```bash
  npm install playwright
  ```

## Известные ограничения

1. Playwright требует установки браузера (при первом использовании):
   ```bash
   npx playwright install chromium
   ```

2. Максимальный размер файла ограничен `DOWNLOAD_MAX_MB` (по умолчанию 500 MB)

3. Таймаут скачивания: `DOWNLOAD_TIMEOUT_MS` (по умолчанию 60 секунд)

4. Максимум редиректов: `DOWNLOAD_MAX_REDIRECTS` (по умолчанию 10)

## Troubleshooting

### Ошибка: "File too large"
- Увеличьте `DOWNLOAD_MAX_MB` в .env

### Ошибка: "Timeout"
- Увеличьте `DOWNLOAD_TIMEOUT_MS` в .env

### Ошибка: "No video URL found"
- Проверьте, что URL доступен
- Попробуйте включить `PLAYWRIGHT_FALLBACK=true`
- Установите Playwright: `npm install playwright && npx playwright install chromium`

### Ошибка: "Failed to resolve URL"
- Проверьте доступность URL
- Увеличьте `DOWNLOAD_MAX_REDIRECTS` если много редиректов



