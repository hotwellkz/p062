#!/bin/bash
# Команды для пересборки контейнера на Synology (исправление 404)

echo "=== Пересборка контейнера shorts-backend для исправления 404 ==="

# Перейти в директорию backend
cd /volume1/docker/shortsai/backend

echo "1. Текущая директория:"
pwd

echo ""
echo "2. Проверка наличия docker-compose.yml:"
ls -la docker-compose.yml || echo "Файл не найден!"

echo ""
echo "3. Остановка контейнера..."
sudo docker compose stop shorts-backend || sudo docker stop shorts-backend

echo ""
echo "4. Пересборка образа (это займет несколько минут)..."
sudo docker compose build --no-cache backend

echo ""
echo "5. Запуск контейнера..."
sudo docker compose up -d backend

echo ""
echo "6. Ожидание запуска (10 секунд)..."
sleep 10

echo ""
echo "7. Проверка статуса контейнера:"
sudo docker ps | grep shorts-backend || sudo docker ps | grep backend

echo ""
echo "8. Проверка логов (последние 50 строк):"
sudo docker logs shorts-backend --tail 50 | grep -E "routes registered|listening|INCOMING|Backend" || sudo docker logs shorts-backend --tail 30

echo ""
echo "=== Готово! ==="
echo ""
echo "Тест endpoint:"
echo "curl -i -X POST https://api.shortsai.ru/api/telegram/fetchAndSaveToServer -H 'Content-Type: application/json' -d '{\"channelId\":\"test\"}'"

