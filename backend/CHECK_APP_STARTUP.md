# Проверка запуска приложения

## Наблюдение
Firebase Admin загружается успешно, но при запуске `node dist/index.js` нет вывода.

## Команды для проверки

В SSH сессии на Synology:

```bash
cd /volume1/docker/shortsai/backend

# 1. Проверить переменную PORT
sudo docker compose run --rm backend sh -c "printenv | grep PORT"

# 2. Запустить с явным выводом всех console.log
sudo docker compose run --rm backend sh -c "node dist/index.js 2>&1"

# 3. Проверить, что приложение пытается запуститься (добавить временный console.log)
# Но сначала проверим, может быть приложение запускается, но сразу завершается

# 4. Проверить, нет ли process.exit() где-то в коде
sudo docker compose run --rm backend sh -c "grep -r 'process.exit' dist/ || echo 'No process.exit found'"

# 5. Запустить с таймаутом, чтобы увидеть, запускается ли сервер
sudo docker compose run --rm backend sh -c "timeout 5 node dist/index.js 2>&1 || true"

# 6. Проверить, слушает ли что-то на порту после запуска
sudo docker compose run --rm backend sh -c "node dist/index.js & sleep 3 && netstat -tlnp 2>/dev/null | grep 3000 || ss -tlnp | grep 3000; pkill node || true"
```

## Возможная проблема: приложение запускается, но сразу завершается

Если приложение запускается и сразу завершается без ошибок, возможно:
1. Проблема с переменной PORT (не установлена или 0)
2. Ошибка в app.listen, которая не логируется
3. Проблема с одним из импортов роутов

## Быстрый тест: проверить PORT

```bash
# Проверить PORT в .env.production
cat .env.production | grep -E "^PORT|^BACKEND_PORT"

# Если PORT не установлен, установить временно
sudo docker compose run --rm backend sh -c "PORT=3000 node dist/index.js 2>&1 | head -20"
```

## Альтернатива: добавить временный console.log в начало

Можно временно добавить в начало `dist/index.js` (или пересобрать с добавлением в `src/index.ts`):

```javascript
console.log("=== STARTING BACKEND ===");
console.log("PORT:", process.env.PORT);
console.log("NODE_ENV:", process.env.NODE_ENV);
```

Это поможет увидеть, доходит ли выполнение до app.listen.

