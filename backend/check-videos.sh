#!/bin/bash
# Скрипт для поиска видео на сервере
# Usage: bash check-videos.sh

cd /volume1/docker/shortsai/backend

echo "============================================"
echo "Поиск видео файлов на сервере"
echo "============================================"
echo ""

# Проверка STORAGE_ROOT из логов
echo "=== STORAGE_ROOT из логов контейнера ==="
sudo /usr/local/bin/docker compose logs backend 2>&1 | grep -i "STORAGE_ROOT\|Using STORAGE_ROOT" | tail -5
echo ""

# Проверка структуры storage
echo "=== Структура папки storage ==="
find storage -type d 2>/dev/null | sort
echo ""

# Поиск всех видео файлов
echo "=== Поиск всех видео файлов ==="
find storage -type f \( -name "*.mp4" -o -name "*.mov" -o -name "*.avi" -o -name "*.mkv" \) 2>/dev/null
echo ""

# Размер папки storage
echo "=== Размер папки storage ==="
du -sh storage/ 2>/dev/null
echo ""

# Проверка последних логов о сохранении
echo "=== Последние логи о сохранении видео ==="
sudo /usr/local/bin/docker compose logs backend 2>&1 | grep -i "saved\|saving\|download\|filePath\|inputPath" | tail -10
echo ""

# Проверка прав доступа
echo "=== Права доступа к папке storage ==="
ls -la storage/ 2>/dev/null
ls -la storage/videos/ 2>/dev/null
echo ""

echo "============================================"
echo "Проверка завершена"
echo "============================================"





