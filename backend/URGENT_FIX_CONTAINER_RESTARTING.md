# Срочное исправление: контейнер перезапускается

## Проблема
Контейнер постоянно перезапускается. Backend не запускается.

## Команды для диагностики в SSH сессии на Synology

Выполните по порядку:

```bash
# 1. Остановить контейнер
sudo docker compose stop backend

# 2. Проверить логи полностью (без grep, чтобы увидеть все)
sudo docker logs shorts-backend 2>&1 | tail -100

# 3. Попробовать запустить вручную для просмотра ошибки
cd /volume1/docker/shortsai/backend
sudo docker compose run --rm backend node dist/index.js

# 4. Проверить скомпилированный код на ошибки
sudo docker compose run --rm backend node -c dist/index.js

# 5. Проверить переменные окружения
cat .env.production | grep -E "PORT|NODE_ENV|FIREBASE"

# 6. Проверить, что файл index.ts обновлен
head -10 src/index.ts | grep -E "import.*Logger|Logger"
```

## Возможные причины

1. **Ошибка в коде** - нужно увидеть полные логи
2. **Отсутствует обязательная переменная окружения** - проверить .env.production
3. **Проблема с Firebase инициализацией** - проверить FIREBASE_* переменные
4. **Проблема с зависимостями** - проверить package.json

## Быстрое решение: откат к предыдущей рабочей версии

Если проблема не решается быстро:

```bash
cd /volume1/docker/shortsai/backend

# Откатиться к предыдущей версии файла
cp src/index.ts.backup src/index.ts

# Или использовать git (если есть)
git log --oneline -5
git checkout <предыдущий-рабочий-коммит> -- src/index.ts

# Пересобрать
sudo docker compose build --no-cache backend
sudo docker compose up -d backend
```

## Критично: увидеть ошибку

Самое важное - увидеть полные логи без фильтрации:

```bash
sudo docker logs shorts-backend 2>&1 | tail -200
```

Это покажет реальную ошибку, из-за которой контейнер падает.

