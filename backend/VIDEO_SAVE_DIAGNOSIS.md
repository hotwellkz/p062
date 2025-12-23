# 🔍 ДИАГНОСТИКА ПРОБЛЕМЫ СОХРАНЕНИЯ ВИДЕО

## ШАГ 1. ПРОВЕРКА docker-compose.yml

### Текущее состояние:

```yaml
version: '3.8'
services:
  backend:
    container_name: shorts-backend
    build: .
    ports:
      - "${BACKEND_PORT:-3000}:${BACKEND_PORT:-3000}"
    env_file:
      - .env.production
    restart: always
    environment:
      - PORT=${BACKEND_PORT:-3000}
      - NODE_ENV=production
```

### ❌ ПРОБЛЕМА #1: ОТСУТСТВУЮТ VOLUMES

**Вывод:**
- ❌ Нет секции `volumes:` для монтирования storage
- ❌ Файлы сохраняются ВНУТРИ контейнера в `/app/storage/videos`
- ❌ После перезапуска контейнера файлы теряются
- ❌ Файлы недоступны с хоста (Synology NAS)

**Ожидаемое:**
```yaml
volumes:
  - ./storage:/app/storage
  - ./tmp:/app/tmp
```

---

## ШАГ 2. ПРОВЕРКА Dockerfile

### Текущее состояние:

```dockerfile
FROM node:20-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production
CMD ["node", "dist/index.js"]
```

### Анализ:

**WORKDIR:** `/app`
- Все относительные пути начинаются с `/app`
- `process.cwd()` вернёт `/app`

**USER:** Не указан (по умолчанию `root`)
- ✅ Нет проблем с правами доступа внутри контейнера
- ⚠️ Но может быть проблема с правами на хосте при монтировании volume

**Вывод:**
- ✅ WORKDIR установлен корректно
- ⚠️ Относительные пути будут работать, но только внутри контейнера
- ❌ Без volume файлы не попадут на хост

---

## ШАГ 3. АНАЛИЗ КОДА СОХРАНЕНИЯ ВИДЕО

### Код формирования пути:

**Файл:** `backend/src/services/storage/userChannelStorage.ts:81`

```typescript
const STORAGE_ROOT = process.env.STORAGE_ROOT || path.resolve(process.cwd(), 'storage/videos');
```

**Логика:**
1. Если есть `STORAGE_ROOT` в env → используется он
2. Если нет → `path.resolve(process.cwd(), 'storage/videos')`
3. `process.cwd()` = `/app` (из WORKDIR)
4. Итоговый путь: `/app/storage/videos` (если STORAGE_ROOT не задан)

### Код сохранения файла:

**Файл:** `backend/src/services/videoDownloadService.ts:1511`

```typescript
const filePath = path.join(paths.inputDir, safeFileName);
await fs.writeFile(filePath, fileBuffer);
```

**Где `paths.inputDir` формируется:**
```typescript
// STORAGE_ROOT/userSlug/channelSlug
const inputDir = path.join(STORAGE_ROOT, userSlug, channelSlug);
```

**Пример пути:**
- `STORAGE_ROOT` = `/app/storage/videos` (если не задан в env)
- `userSlug` = `hotwell-kz-at-gmail-com`
- `channelSlug` = `shortsairu-2-6akaezfN`
- **Итоговый путь:** `/app/storage/videos/hotwell-kz-at-gmail-com/shortsairu-2-6akaezfN/video.mp4`

### Вывод:

- ✅ Путь формируется корректно
- ✅ Используется `path.join()` (безопасно)
- ❌ **НО:** Путь `/app/storage/videos` находится ВНУТРИ контейнера
- ❌ Без volume этот путь НЕ синхронизируется с хостом

---

## ШАГ 4. ПРОВЕРКА ЛОГОВ

### Команда для проверки:

```bash
ssh -p 777 admin@hotwell.synology.me
cd /volume1/docker/shortsai/backend
sudo /usr/local/bin/docker compose logs backend | grep -i "saved\|storage\|inputDir" | tail -30
```

### Что искать:

1. **Строка:** `[Storage] Video saved to inputDir`
   - Должен быть `filePath` с полным путём
   - Пример: `filePath: '/app/storage/videos/...'`

2. **Строка:** `downloadAndSaveToLocal: file saved to local storage`
   - Должен быть `inputPath`

3. **Строка:** `[Storage] Using STORAGE_ROOT:`
   - Показывает, какой STORAGE_ROOT используется

### Ожидаемый вывод:

```
[Storage] Video saved to inputDir {
  filePath: '/app/storage/videos/hotwell-kz-at-gmail-com/shortsairu-2-6akaezfN/video.mp4',
  inputDir: '/app/storage/videos/hotwell-kz-at-gmail-com/shortsairu-2-6akaezfN'
}
```

**Вывод:**
- Если путь начинается с `/app/storage/videos` → файл ВНУТРИ контейнера
- Если путь начинается с `/volume1/docker/...` → файл на хосте (но такого не будет без volume)

---

## ШАГ 5. ПРОВЕРКА ИЗНУТРИ КОНТЕЙНЕРА

### Команды для выполнения:

```bash
ssh -p 777 admin@hotwell.synology.me
cd /volume1/docker/shortsai/backend

# Войти в контейнер
sudo /usr/local/bin/docker compose exec backend sh

# Внутри контейнера:
ls -la /app
ls -la /app/storage
ls -la /app/storage/videos
find /app/storage -type f -name "*.mp4" 2>/dev/null

# Проверить переменную STORAGE_ROOT
env | grep STORAGE_ROOT

# Выйти
exit
```

### Ожидаемый результат:

**Если файлы есть:**
```
/app/storage/videos/hotwell-kz-at-gmail-com/shortsairu-2-6akaezfN/
  video.mp4
```

**Если файлов нет:**
- Папка `/app/storage/videos` пустая или не существует
- Возможна ошибка создания папок

**Вывод:**
- ✅ Если файлы есть в `/app/storage/videos` → проблема в отсутствии volume
- ❌ Если файлов нет → проблема в коде сохранения или правах доступа

---

## ШАГ 6. ПРОВЕРКА ПРАВ ДОСТУПА

### Команды для выполнения:

```bash
ssh -p 777 admin@hotwell.synology.me
cd /volume1/docker/shortsai/backend

# Проверка прав на хосте
ls -ld storage/
ls -ld storage/videos/

# Проверка UID/GID контейнера
sudo /usr/local/bin/docker compose exec backend sh -c "id"

# Проверка прав внутри контейнера
sudo /usr/local/bin/docker compose exec backend sh -c "ls -ld /app/storage"
sudo /usr/local/bin/docker compose exec backend sh -c "ls -ld /app/storage/videos"
```

### Анализ:

**Внутри контейнера:**
- USER: `root` (по умолчанию в node:20-alpine)
- UID: `0`
- ✅ Нет проблем с правами внутри контейнера

**На хосте (после добавления volume):**
- Если volume примонтирован → права будут от root (UID 0)
- ⚠️ Может быть проблема доступа с хоста

**Вывод:**
- ✅ Права внутри контейнера OK
- ⚠️ После добавления volume может потребоваться `chmod` на хосте

---

## ШАГ 7. ФИНАЛЬНЫЙ ДИАГНОЗ

### 🎯 ГЛАВНАЯ ПРИЧИНА:

**ОТСУТСТВИЕ VOLUME В docker-compose.yml**

Файлы сохраняются в `/app/storage/videos` **ВНУТРИ контейнера**, но этот путь **НЕ ПРИМОНТИРОВАН** как volume на хост. Поэтому:

1. ✅ Backend успешно сохраняет файл (внутри контейнера)
2. ✅ Логи показывают "Video saved"
3. ❌ Файл недоступен на хосте (Synology NAS)
4. ❌ Файл теряется при перезапуске контейнера

### 🔧 ТОЧЕЧНОЕ ИСПРАВЛЕНИЕ:

**Файл:** `backend/docker-compose.yml`

**Добавить секцию volumes:**

```yaml
version: '3.8'

services:
  backend:
    container_name: shorts-backend
    build: .
    ports:
      - "${BACKEND_PORT:-3000}:${BACKEND_PORT:-3000}"
    env_file:
      - .env.production
    restart: always
    environment:
      - PORT=${BACKEND_PORT:-3000}
      - NODE_ENV=production
    volumes:
      - ./storage:/app/storage
      - ./tmp:/app/tmp
```

**Или с абсолютным путём (рекомендуется для Synology):**

```yaml
    volumes:
      - /volume1/docker/shortsai/backend/storage:/app/storage
      - /volume1/docker/shortsai/backend/tmp:/app/tmp
```

### 📝 ДОПОЛНИТЕЛЬНО:

**Проверить/установить STORAGE_ROOT в `.env.production`:**

```bash
STORAGE_ROOT=/app/storage/videos
```

**Важно:** Путь должен совпадать с тем, куда монтируется volume (`/app/storage/videos`).

---

## ШАГ 8. РЕКОМЕНДАЦИИ НА БУДУЩЕЕ

### 1. Использовать только абсолютные пути

**Плохо:**
```typescript
const STORAGE_ROOT = process.env.STORAGE_ROOT || path.resolve(process.cwd(), 'storage/videos');
```

**Хорошо:**
```typescript
const STORAGE_ROOT = process.env.STORAGE_ROOT || '/app/storage/videos';
```

### 2. Правильно монтировать volumes

**Всегда указывать volumes в docker-compose.yml:**
```yaml
volumes:
  - ./storage:/app/storage:rw
  - ./tmp:/app/tmp:rw
```

**Использовать абсолютные пути для production:**
```yaml
volumes:
  - /volume1/docker/shortsai/backend/storage:/app/storage:rw
```

### 3. Логировать путь сохранения

**Уже реализовано:**
```typescript
console.log('[Storage] Video saved to inputDir', {
  filePath  // ← полный путь
});
```

**Рекомендация:** Добавить проверку существования файла после сохранения:
```typescript
const stats = await fs.stat(filePath);
Logger.info("File verified", { filePath, size: stats.size });
```

### 4. Избежать проблемы при следующих деплоях

**Чеклист:**
- ✅ Проверить наличие `volumes:` в docker-compose.yml
- ✅ Убедиться, что пути в volume совпадают с STORAGE_ROOT
- ✅ Проверить права доступа на хосте после первого запуска
- ✅ Добавить healthcheck для проверки доступности storage
- ✅ Логировать STORAGE_ROOT при старте приложения

**Пример healthcheck:**
```yaml
healthcheck:
  test: ["CMD", "sh", "-c", "test -d /app/storage && test -w /app/storage"]
  interval: 30s
  timeout: 10s
  retries: 3
```

---

## 📋 ПЛАН ДЕЙСТВИЙ

1. **Добавить volumes в docker-compose.yml**
2. **Пересобрать и перезапустить контейнер:**
   ```bash
   sudo /usr/local/bin/docker compose down
   sudo /usr/local/bin/docker compose up -d --build
   ```
3. **Проверить логи:**
   ```bash
   sudo /usr/local/bin/docker compose logs backend | grep -i "saved\|storage"
   ```
4. **Проверить файлы на хосте:**
   ```bash
   find /volume1/docker/shortsai/backend/storage -type f
   ```
5. **Сохранить тестовое видео через frontend**
6. **Проверить наличие файла на хосте**

---

## ✅ ОЖИДАЕМЫЙ РЕЗУЛЬТАТ

После исправления:
- ✅ Файлы сохраняются в `/app/storage/videos/...` внутри контейнера
- ✅ Файлы доступны на хосте в `/volume1/docker/shortsai/backend/storage/videos/...`
- ✅ Файлы сохраняются после перезапуска контейнера
- ✅ Логи показывают корректный путь сохранения





