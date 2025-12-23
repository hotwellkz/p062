#!/bin/bash
# Поиск видео на сервере
cd /volume1/docker/shortsai/backend

echo "============================================"
echo "Поиск видео файлов на сервере"
echo "============================================"
echo ""

echo "=== STORAGE_ROOT из .env.production ==="
grep STORAGE_ROOT .env.production || echo "STORAGE_ROOT не установлен"
echo ""

echo "=== Структура storage ==="
find storage -type d 2>/dev/null | sort
echo ""

echo "=== Все файлы в storage ==="
find storage -type f 2>/dev/null
echo ""

echo "=== Поиск видео файлов ==="
find storage -type f \( -name "*.mp4" -o -name "*.mov" -o -name "*.avi" \) 2>/dev/null
echo ""

echo "=== Размер storage ==="
du -sh storage/ 2>/dev/null
echo ""

echo "=== Проверка через контейнер ==="
echo "Выполните вручную:"
echo "sudo /usr/local/bin/docker compose exec backend ls -la /app/storage/videos/"
echo ""

echo "=== Проверка логов ==="
echo "Выполните вручную:"
echo "sudo /usr/local/bin/docker compose logs backend | grep -i 'saved\|storage\|inputDir' | tail -20"
echo ""





