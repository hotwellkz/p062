#!/bin/bash
# Скрипт для диагностики сохранения видео
# Usage: bash debug-video-save.sh

cd /volume1/docker/shortsai/backend

echo "============================================"
echo "Диагностика сохранения видео"
echo "============================================"
echo ""

# Проверка STORAGE_ROOT
echo "=== STORAGE_ROOT из .env.production ==="
grep STORAGE_ROOT .env.production || echo "STORAGE_ROOT не установлен"
echo ""

# Проверка структуры storage (рекурсивно)
echo "=== Структура папки storage (все папки) ==="
find storage -type d 2>/dev/null | sort
echo ""

# Поиск всех файлов (рекурсивно)
echo "=== Все файлы в storage (рекурсивно) ==="
find storage -type f 2>/dev/null | head -50
echo ""

# Поиск видео файлов
echo "=== Видео файлы (mp4, mov, avi) ==="
find storage -type f \( -name "*.mp4" -o -name "*.mov" -o -name "*.avi" -o -name "*.mkv" \) 2>/dev/null
echo ""

# Размер папки
echo "=== Размер папки storage ==="
du -sh storage/ 2>/dev/null
du -sh storage/*/ 2>/dev/null | head -20
echo ""

# Проверка прав доступа
echo "=== Права доступа storage ==="
ls -la storage/ 2>/dev/null
echo ""

# Проверка прав доступа videos
echo "=== Права доступа storage/videos ==="
ls -la storage/videos/ 2>/dev/null
echo ""

# Проверка вложенных папок (если есть)
echo "=== Содержимое storage/videos (если есть папки) ==="
if [ -d "storage/videos" ]; then
  for dir in storage/videos/*/; do
    if [ -d "$dir" ]; then
      echo "--- $dir ---"
      ls -la "$dir" 2>/dev/null | head -10
      echo ""
    fi
  done
fi

# Проверка логов (требует sudo)
echo "=== Последние логи о сохранении (требует sudo) ==="
echo "Выполните вручную: sudo /usr/local/bin/docker compose logs backend | grep -i 'saved\|storage\|inputDir\|Video saved' | tail -30"
echo ""

# Проверка переменных окружения в контейнере (требует sudo)
echo "=== Проверка STORAGE_ROOT в контейнере (требует sudo) ==="
echo "Выполните вручную: sudo /usr/local/bin/docker compose exec backend sh -c 'env | grep STORAGE_ROOT'"
echo ""

# Проверка структуры папок в контейнере (требует sudo)
echo "=== Проверка папок в контейнере (требует sudo) ==="
echo "Выполните вручную: sudo /usr/local/bin/docker compose exec backend sh -c 'find /app/storage -type d | sort'"
echo ""

echo "============================================"
echo "Проверка завершена"
echo "============================================"
echo ""
echo "ВАЖНО: Видео сохраняются в структуру:"
echo "  storage/videos/{userSlug}/{channelSlug}/video.mp4"
echo ""
echo "Где:"
echo "  - userSlug = email преобразован в slug (например: hotwell-kz-at-gmail-com)"
echo "  - channelSlug = название канала + ID (например: shortsairu-2-6akaezfN)"
echo ""
echo "Проверьте вложенные папки внутри storage/videos/"

