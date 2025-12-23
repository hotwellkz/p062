#!/bin/bash
# Скрипт для пересборки Docker контейнера на Synology NAS

set -e

echo "🔄 Начинаю пересборку контейнера..."

cd /volume1/docker/shortsai/backend

echo "📦 Останавливаю текущий контейнер..."
sudo /usr/local/bin/docker compose down

echo "🔨 Пересобираю контейнер с новыми изменениями..."
sudo /usr/local/bin/docker compose build --no-cache

echo "🚀 Запускаю контейнер..."
sudo /usr/local/bin/docker compose up -d

echo "⏳ Жду 5 секунд для запуска..."
sleep 5

echo "📋 Проверяю статус контейнера..."
sudo /usr/local/bin/docker compose ps

echo "📝 Последние 50 строк логов:"
sudo /usr/local/bin/docker compose logs --tail=50

echo "✅ Пересборка завершена!"





