# Глубокая отладка контейнера

## Наблюдение
При запуске `node dist/index.js` вручную нет вывода - ни ошибок, ни успешного запуска.

## Команды для диагностики

В SSH сессии на Synology:

```bash
cd /volume1/docker/shortsai/backend

# 1. Проверить, что файл dist/index.js существует
sudo docker compose run --rm backend ls -la dist/index.js

# 2. Проверить синтаксис скомпилированного файла
sudo docker compose run --rm backend node -c dist/index.js

# 3. Запустить с явным выводом всех ошибок
sudo docker compose run --rm backend sh -c "node dist/index.js 2>&1"

# 4. Проверить переменные окружения
sudo docker compose run --rm backend printenv | head -20

# 5. Проверить, что .env.production загружается
cat .env.production | head -10

# 6. Попробовать запустить с явным указанием NODE_ENV
sudo docker compose run --rm backend sh -c "NODE_ENV=production node dist/index.js 2>&1"

# 7. Проверить, нет ли проблем с импортами
sudo docker compose run --rm backend sh -c "node -e 'require(\"./dist/index.js\")' 2>&1"

# 8. Проверить логирование - может быть ошибка подавляется
sudo docker compose run --rm backend sh -c "node dist/index.js 2>&1 | head -50"
```

## Возможные причины

1. **Приложение запускается и сразу завершается** - проверить код на наличие `process.exit()`
2. **Ошибка подавляется** - проверить обработчики ошибок
3. **Проблема с переменными окружения** - проверить .env.production
4. **Проблема с Firebase инициализацией** - проверить FIREBASE_* переменные

## Проверка кода на проблемные места

Проверить в `src/index.ts`:
- Нет ли `process.exit()` в начале файла
- Нет ли синхронных ошибок при импорте
- Правильно ли обрабатываются ошибки инициализации

## Альтернатива: запуск с отладкой

```bash
# Запустить с включенным выводом всех console.log
sudo docker compose run --rm backend sh -c "DEBUG=* node dist/index.js 2>&1"

# Или с явным выводом в консоль
sudo docker compose run --rm backend sh -c "node dist/index.js > /tmp/output.log 2>&1 && cat /tmp/output.log || cat /tmp/output.log"
```

