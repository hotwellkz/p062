# Проверка импортов и запуска

## Проблема
Приложение не запускается, но нет вывода ошибок. Возможно, ошибка происходит при импорте модулей.

## Команды для проверки

В SSH сессии на Synology:

```bash
cd /volume1/docker/shortsai/backend

# 1. Проверить, что файл существует и компилируется
sudo docker compose run --rm backend sh -c "ls -la dist/index.js && node -c dist/index.js"

# 2. Попробовать загрузить модуль пошагово
sudo docker compose run --rm backend sh -c "node -e 'console.log(\"Step 1: Loading dotenv\"); require(\"dotenv/config\"); console.log(\"Step 2: Loading express\"); require(\"express\"); console.log(\"Step 3: OK\");'"

# 3. Проверить импорт Logger
sudo docker compose run --rm backend sh -c "node -e 'const {Logger} = require(\"./dist/utils/logger\"); console.log(\"Logger loaded:\", typeof Logger);'"

# 4. Проверить импорт firebaseAdmin (может быть проблема здесь)
sudo docker compose run --rm backend sh -c "node -e 'console.log(\"Loading firebaseAdmin...\"); try { require(\"./dist/services/firebaseAdmin\"); console.log(\"OK\"); } catch(e) { console.error(\"ERROR:\", e.message); }'"

# 5. Проверить переменную PORT
sudo docker compose run --rm backend sh -c "node -e 'console.log(\"PORT:\", process.env.PORT || \"not set\");'"

# 6. Запустить с явным выводом всех console.log
sudo docker compose run --rm backend sh -c "NODE_ENV=production node dist/index.js 2>&1 | tee /tmp/startup.log || cat /tmp/startup.log"
```

## Возможная проблема: Firebase инициализация

Если проблема в Firebase, можно временно закомментировать импорт:

```typescript
// Временно закомментировать для теста
// import "./services/firebaseAdmin";
```

Или проверить переменные окружения Firebase:

```bash
cat .env.production | grep FIREBASE
```

## Быстрый тест: минимальный запуск

Создать тестовый файл `test-start.js`:

```javascript
console.log("Starting...");
const port = process.env.PORT || 3000;
console.log("Port:", port);
console.log("OK - server would start on port", port);
```

Запустить:
```bash
sudo docker compose run --rm backend node test-start.js
```

Если это работает - проблема в импортах или инициализации.

