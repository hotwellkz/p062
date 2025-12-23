# Настройка STORAGE_ROOT для Synology

## ✅ Выполнено

Переменная `STORAGE_ROOT` установлена в `.env.production`:
```
STORAGE_ROOT=/app/storage/videos
```

## Где хранятся видео

### В Docker контейнере:
```
/app/storage/videos/
```

### На Synology сервере (хост):
```
/volume1/docker/shortsai/backend/storage/videos/
```

### Структура папок:
```
storage/videos/
  └── {userSlug}/                    # Email пользователя (например: hotwell-kz3-at-gmail-com)
      └── {channelSlug}/             # Название канала + ID (например: shortsairu-2-6akaezfN)
          ├── video.mp4              # Входящие видео для автопубликации
          └── Загруженные - {channelName}/  # Архив опубликованных видео
              └── video.mp4
```

## Проверка

После сохранения видео через фронтенд проверьте:

```bash
ssh -p 777 admin@hotwell.synology.me
cd /volume1/docker/shortsai/backend

# Найти все видео файлы
find storage/videos -type f -name "*.mp4"

# Показать структуру
find storage/videos -type d | sort

# Размер папки
du -sh storage/videos/
```

## Доступ через File Station

1. Откройте **File Station** в DSM
2. Перейдите в `/volume1/docker/shortsai/backend/storage/videos/`
3. Найдите папку с вашим email
4. Войдите в папку канала
5. Там должны быть видео файлы

## Важно

- ✅ Папка `storage/videos` создана
- ✅ Переменная `STORAGE_ROOT=/app/storage/videos` установлена
- ✅ Volume маппинг настроен: `./storage:/app/storage`
- ✅ Контейнер перезапущен

Теперь все видео будут сохраняться в `/volume1/docker/shortsai/backend/storage/videos/` на сервере.





