# Загрузка обновленного index.ts на Synology

## Способ 1: Через scp из PowerShell (локально)

**Из PowerShell (на вашем ПК):**

```powershell
scp backend\src\index.ts admin@192.168.100.222:/volume1/docker/shortsai/backend/src/index.ts
```

## Способ 2: Через cat в SSH сессии

**В текущей SSH сессии на Synology:**

```bash
# 1. Создать файл через cat (скопируйте содержимое из локального файла)
nano /volume1/docker/shortsai/backend/src/index.ts
# или
vi /volume1/docker/shortsai/backend/src/index.ts

# 2. Вставить содержимое файла backend/src/index.ts из локального проекта
# 3. Сохранить и выйти
```

## Способ 3: Проверить, что файл обновлен

После загрузки проверьте:

```bash
cd /volume1/docker/shortsai/backend
head -5 src/index.ts
# Должно быть:
# process.stdout.write("[DEBUG] Starting backend application...\n");
# process.stderr.write("[DEBUG] Starting backend application (stderr)...\n");
# import "dotenv/config";
```

## После загрузки файла

```bash
cd /volume1/docker/shortsai/backend

# Пересобрать
sudo docker compose build --no-cache backend

# Запустить с debug логами
sudo docker compose run --rm backend sh -c "PORT=3000 node dist/index.js 2>&1"
```

