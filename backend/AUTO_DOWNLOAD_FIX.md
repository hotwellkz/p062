# Исправление автоматического скачивания видео

## Проблема

Автоматизация отправляла промпты по расписанию, но **НЕ скачивала** сгенерированные видео автоматически. Ручная кнопка "Забрать видео из SyntX на сервер" работала корректно.

## Что было не так

1. **Неправильная функция**: Автоматизация использовала `downloadAndUploadVideoToDrive()` (загружает в Google Drive), вместо `downloadAndSaveToLocal()` (сохраняет в локальное хранилище `storage/videos`).

2. **Неправильные условия**: Планирование задачи требовало наличия `googleDriveFolderId`, хотя нужно было сохранять локально независимо от настроек Drive.

3. **Недостаточное логирование**: Не было видно, когда cron запускает скачивание, когда видео готово, и когда файл сохранен.

## Исправления

### 1. `backend/src/services/scheduledTasks.ts`

**Изменения:**
- Заменен вызов `downloadAndUploadVideoToDrive()` на `downloadAndSaveToLocal()`
- Обновлена проверка идемпотентности: теперь проверяет `generatedVideos` вместо `videoGenerations`
- Добавлено детальное логирование на всех этапах:
  - Когда задача стартует (`AUTO_TASK_START`)
  - Когда данные задачи получены (`AUTO_TASK_DATA_RETRIEVED`)
  - Когда начинается скачивание (`AUTO_DOWNLOAD_START`)
  - Когда скачивание успешно (`AUTO_DOWNLOAD_SUCCESS`)
  - Когда скачивание провалилось (`AUTO_DOWNLOAD_FAILED`)

**Ключевой код:**
```typescript
// Было:
const result = await downloadAndUploadVideoToDrive({...});

// Стало:
const result = await downloadAndSaveToLocal({
  channelId,
  userId,
  telegramMessageId: telegramMessageInfo.messageId,
  videoTitle: savedTask?.videoTitle,
  prompt: savedTask?.prompt
});
```

### 2. `backend/src/services/autoSendScheduler.ts`

**Изменения:**
- Убрана проверка на `googleDriveFolderId` - теперь планируется задача если включен `autoDownloadToDriveEnabled`
- Обновлены логи: указывают что видео будет сохранено в локальное хранилище
- Добавлено логирование `STORAGE_ROOT` для диагностики

**Ключевой код:**
```typescript
// Было:
if (hasAutoDownloadEnabled && hasGoogleDriveFolder) {

// Стало:
if (hasAutoDownloadEnabled) {
  // Планируем сохранение в локальное хранилище
  // независимо от настроек Google Drive
}
```

### 3. `backend/src/services/videoDownloadService.ts`

**Изменения:**
- Добавлено определение режима (`auto` или `manual`) на основе наличия `prompt`
- Добавлено логирование режима во всех ключевых точках:
  - `DOWNLOAD_TO_LOCAL_AUTO_START` / `DOWNLOAD_TO_LOCAL_MANUAL_START`
  - `VIDEO_DOWNLOADED_AUTO` / `VIDEO_DOWNLOADED_MANUAL`
  - `SAVING_TO_STORAGE_AUTO` / `SAVING_TO_STORAGE_MANUAL`
  - `FILE_SAVED_AUTO` / `FILE_SAVED_MANUAL`
- Изменен `source` в Firestore: `"schedule"` для автоматического режима, `"manual"` для ручного

**Ключевой код:**
```typescript
// Определяем режим
const mode = prompt ? "auto" : "manual";
const storageRoot = process.env.STORAGE_ROOT || "default (storage/videos)";

// Логирование с режимом
Logger.info(`downloadAndSaveToLocal [${mode}]: start`, {...});

// В Firestore
source: mode === "auto" ? "schedule" : "manual"
```

## Результат

Теперь автоматизация:
1. ✅ Отправляет промпт по расписанию
2. ✅ Ждет указанное время (настраивается через `autoDownloadDelayMinutes`)
3. ✅ Автоматически скачивает видео из Telegram
4. ✅ Сохраняет в **тот же каталог** что и ручное скачивание: `storage/videos/{userSlug}/{channelSlug}/`
5. ✅ Логирует все этапы для диагностики

## Путь сохранения

Видео сохраняются в:
```
{STORAGE_ROOT}/{userSlug}/{channelSlug}/{filename}.mp4
```

Где:
- `STORAGE_ROOT` = `process.env.STORAGE_ROOT` или `storage/videos` (по умолчанию)
- `userSlug` = безопасное имя из email пользователя
- `channelSlug` = безопасное имя из названия канала

На Synology NAS это будет:
```
/volume1/docker/shortsai/backend/storage/videos/{userSlug}/{channelSlug}/{filename}.mp4
```

## Логи для диагностики

При автоматическом скачивании вы увидите в логах:

1. **Планирование задачи:**
   ```
   processAutoSendTick: scheduling auto-download to local storage
   AUTO_DOWNLOAD_SCHEDULED: { taskId, channelId, willRunInMinutes }
   ```

2. **Запуск задачи:**
   ```
   AUTO_TASK_START: { taskId, channelId, scheduledAt }
   AUTO_DOWNLOAD_START: { taskId, channelId, storageRoot }
   ```

3. **Скачивание видео:**
   ```
   VIDEO_DOWNLOADED_AUTO: { channelId, fileName, messageId }
   ```

4. **Сохранение файла:**
   ```
   SAVING_TO_STORAGE_AUTO: { channelId, inputDir, storageRoot }
   FILE_SAVED_AUTO: { channelId, filePath, filename }
   ```

## Проверка работы

1. Включите `autoDownloadToDriveEnabled` для канала
2. Настройте расписание отправки промптов
3. Дождитесь отправки промпта по расписанию
4. Проверьте логи через `docker compose logs --tail=200 -f`
5. Проверьте наличие файла в `storage/videos/{userSlug}/{channelSlug}/`

## Важные замечания

- ✅ Ручное скачивание **НЕ затронуто** - работает как раньше
- ✅ Используется **тот же путь** что и для ручного скачивания
- ✅ Используется **правильный STORAGE_ROOT** из env переменных
- ✅ Работает **внутри Docker контейнера** (использует абсолютные пути)

## Переменные окружения

Убедитесь что установлена:
```bash
STORAGE_ROOT=/app/storage/videos
```

Или используйте значение по умолчанию: `storage/videos` (относительно рабочей директории).





