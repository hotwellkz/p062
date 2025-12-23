# Отладка падения контейнера

## Проблема
Контейнер постоянно перезапускается. В логах только команда запуска, но нет ошибок.

## Команды для отладки на Synology

В SSH сессии выполните:

```bash
cd /volume1/docker/shortsai/backend

# 1. Проверить, что файл обновлен
grep -A 3 "app.get.*health" src/index.ts

# 2. Проверить скомпилированный код
sudo docker compose run --rm backend cat dist/index.js | grep -A 5 "app.get.*health" | head -10

# 3. Попробовать запустить вручную с выводом ошибок
sudo docker compose run --rm backend sh -c "node dist/index.js 2>&1"

# 4. Проверить переменные окружения в .env.production
cat .env.production | grep -E "PORT|NODE_ENV|FIREBASE"

# 5. Проверить, нет ли синтаксических ошибок в скомпилированном коде
sudo docker compose run --rm backend node -c dist/index.js

# 6. Проверить логи более детально с stderr
sudo docker logs shorts-backend 2>&1 | tail -100
```

## Возможные причины

1. **Проблема с переменными окружения** - отсутствует обязательная переменная
2. **Проблема с Firebase инициализацией** - ошибка при инициализации Firebase Admin
3. **Проблема с импортами** - отсутствует модуль или неправильный путь
4. **Проблема в другом месте кода** - не в /health endpoint

## Быстрое решение: откат к рабочей версии

Если проблема не решается, можно временно откатиться к предыдущей рабочей версии:

```bash
cd /volume1/docker/shortsai/backend
git log --oneline -10  # посмотреть последние коммиты
git checkout <commit-hash>  # откатиться к рабочему коммиту
sudo docker compose build --no-cache backend
sudo docker compose up -d backend
```

