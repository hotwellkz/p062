# Проверка файла на Synology

## Проверка содержимого файла

На Synology выполните:

```bash
# Проверить, что обработчик OPTIONS удален
grep -n "app.options" /volume1/docker/shortsai/backend/src/index.ts

# Если найдено - файл не обновлен
# Если не найдено - файл обновлен правильно

# Проверить строки вокруг места, где был OPTIONS
sed -n '60,70p' /volume1/docker/shortsai/backend/src/index.ts
```

## Проверка логов для понимания ошибки 500

```bash
# Полные логи
sudo docker logs shorts-backend --tail 100

# Только ошибки и исключения
sudo docker logs shorts-backend 2>&1 | grep -i "error\|exception\|failed\|at " | tail -30

# Логи с временными метками
sudo docker logs shorts-backend --tail 50 --timestamps
```

## Если файл не обновлен

Повторно загрузите файл из PowerShell:

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

