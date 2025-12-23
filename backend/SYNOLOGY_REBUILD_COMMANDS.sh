#!/bin/bash
# Команды для пересборки контейнера на Synology

echo "=== Пересборка контейнера shorts-backend ==="

cd /volume1/docker/shortsai

echo "1. Остановка контейнера..."
sudo docker compose stop shorts-backend

echo "2. Пересборка образа..."
sudo docker compose build --no-cache shorts-backend

echo "3. Запуск контейнера..."
sudo docker compose up -d shorts-backend

echo "4. Ожидание запуска (5 секунд)..."
sleep 5

echo "5. Проверка логов..."
sudo docker logs shorts-backend --tail 50 | grep -E "routes registered|listening|INCOMING" || sudo docker logs shorts-backend --tail 30

echo ""
echo "=== Готово! Проверьте логи выше. ==="
echo "Тест endpoint:"
echo "curl -i -X POST https://api.shortsai.ru/api/telegram/fetchAndSaveToServer -H 'Content-Type: application/json' -d '{\"channelId\":\"test\"}'"

