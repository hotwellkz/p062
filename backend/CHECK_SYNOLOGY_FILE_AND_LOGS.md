# Проверка файла на Synology и логов

## Шаг 1: Проверка файла на Synology

Выполните на Synology:

```bash
# Проверить, есть ли обработчик OPTIONS
grep -n "app.options" /volume1/docker/shortsai/backend/src/index.ts

# Если команда ничего не выводит - файл обновлен правильно ✅
# Если выводит строки - файл НЕ обновлен ❌

# Проверить содержимое вокруг строки 62
sed -n '60,65p' /volume1/docker/shortsai/backend/src/index.ts
```

**Ожидаемый результат:**
```
// OPTIONS обрабатывается на уровне Nginx, поэтому здесь не нужен отдельный обработчик
// Nginx возвращает 204 с CORS заголовками для OPTIONS запросов
```

## Шаг 2: Проверка логов при POST запросе

Выполните POST запрос и сразу проверьте логи:

```bash
# В одном терминале - смотреть логи в реальном времени
sudo docker logs -f shorts-backend

# В другом терминале - отправить POST
curl -i -X POST https://api.shortsai.ru/api/telegram/fetchAndSaveToServer \
  -H "Origin: https://shortsai.ru" \
  -H "Content-Type: application/json" \
  -d '{}'
```

Или проверьте последние логи:

```bash
# Полные логи
sudo docker logs shorts-backend --tail 100

# Только ошибки
sudo docker logs shorts-backend 2>&1 | grep -i "error\|exception\|failed" | tail -30

# Логи с временными метками
sudo docker logs shorts-backend --tail 50 --timestamps
```

## Шаг 3: Если файл не обновлен

Повторно загрузите из PowerShell:

```powershell
$content = Get-Content backend\src\index.ts -Raw
$content | ssh admin@192.168.100.222 "cat > /volume1/docker/shortsai/backend/src/index.ts"
```

Затем пересоберите:

```bash
cd /volume1/docker/shortsai/backend
sudo docker compose build --no-cache backend
sudo docker compose up -d backend
```

## Шаг 4: Если файл обновлен, но POST все еще 500

Проблема не в OPTIONS обработчике. Проверьте:
1. Логи backend - какая реальная ошибка?
2. CORS middleware - может быть ошибка там
3. authRequired middleware - может быть ошибка там
4. Сам роут fetchAndSaveToServer - может быть ошибка там

