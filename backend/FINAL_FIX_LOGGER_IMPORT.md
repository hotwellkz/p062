# Финальное исправление: порядок импорта Logger

## Проблема
Контейнер падает из-за использования `Logger` до его импорта (строка 26 использует Logger, но импорт в строке 43).

## Исправление
Импорт `Logger` перенесен в начало файла (строка 5).

## Команды для обновления на Synology

### Вариант 1: Загрузка через PowerShell (локально)

Из PowerShell выполните:

```powershell
Get-Content backend\src\index.ts | ssh admin@192.168.100.222 "cat > /volume1/docker/shortsai/backend/src/index.ts"
```

### Вариант 2: Ручное копирование

В SSH сессии на Synology:

```bash
cd /volume1/docker/shortsai/backend

# 1. Создать резервную копию
cp src/index.ts src/index.ts.backup2

# 2. Открыть файл для редактирования
nano src/index.ts
# или
vi src/index.ts

# 3. Найти строку 43: import { Logger } from "./utils/logger";
# 4. Переместить её после строки 4 (после import cron from "node-cron";)
# 5. Удалить дублирующий импорт из строки 43
# 6. Сохранить файл

# 7. Пересобрать
sudo docker compose build --no-cache backend

# 8. Запустить
sudo docker compose up -d backend

# 9. Проверить
sleep 10
sudo docker ps | grep shorts-backend
sudo docker logs shorts-backend --tail 50
```

## Ожидаемый результат

После исправления:
- Контейнер должен запуститься и остаться в статусе "Up"
- В логах должно появиться: "Backend listening on port 3000"
- Endpoint `/health` должен работать
- Endpoint `/api/telegram/fetchAndSaveToServer` должен возвращать 401 (не 404/502)

## Проверка исправления

После пересборки проверьте:

```bash
# На Synology
sudo docker logs shorts-backend --tail 50 | grep -E "listening|Error|error"

# С VPS
curl -i http://10.9.0.2:3000/health
curl -i https://api.shortsai.ru/health

# Из PowerShell
curl.exe -i https://api.shortsai.ru/health
```

