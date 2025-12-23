#!/bin/bash
# Скрипт для обновления кода и тестирования на Synology

echo "=== Обновление кода на Synology ==="

cd /volume1/docker/shortsai/backend

echo "1. Проверка текущего состояния..."
sudo docker ps | grep shorts-backend

echo ""
echo "2. Остановка контейнера..."
sudo docker compose stop backend

echo ""
echo "3. Пересборка образа (займет несколько минут)..."
sudo docker compose build --no-cache backend

echo ""
echo "4. Запуск контейнера..."
sudo docker compose up -d backend

echo ""
echo "5. Ожидание запуска (10 секунд)..."
sleep 10

echo ""
echo "6. Проверка логов..."
sudo docker logs shorts-backend --tail 30 | grep -E "routes registered|listening|Backend"

echo ""
echo "=== Готово! ==="
echo ""
echo "Тест диагностического endpoint:"
echo "curl -i https://api.shortsai.ru/health"
echo ""
echo "Тест проблемного endpoint:"
echo "curl -i -X POST https://api.shortsai.ru/api/telegram/fetchAndSaveToServer -H 'Content-Type: application/json' -d '{}'"

