import { Logger } from "../utils/logger";
import { downloadAndSaveToLocal } from "./videoDownloadService";

interface ScheduledTask {
  id: string;
  channelId: string;
  scheduleId: string;
  userId: string;
  runAt: number; // timestamp в миллисекундах
  telegramMessageId?: number;
  videoTitle?: string; // сгенерированное название ролика
  prompt?: string; // текст промпта для fallback
  timeoutId?: NodeJS.Timeout;
}

// Хранилище активных задач
const activeTasks = new Map<string, ScheduledTask>();

/**
 * Планирует автоматическое скачивание и сохранение видео в локальное хранилище
 * @param options - Параметры задачи
 * @returns ID задачи
 */
export function scheduleAutoDownload(options: {
  channelId: string;
  scheduleId: string;
  userId: string;
  telegramMessageInfo: { messageId: number; chatId: string };
  delayMinutes: number;
  videoTitle?: string; // сгенерированное название ролика
  prompt?: string; // текст промпта для fallback
}): string {
  const { channelId, scheduleId, userId, telegramMessageInfo, delayMinutes, videoTitle, prompt } = options;
  
  // ИСПРАВЛЕНИЕ: Используем более детерминированный taskId для лучшей дедупликации
  // Формат: channelId_telegramMessageId_timestamp
  // Это позволяет легче находить дубликаты
  const taskId = `${channelId}_${telegramMessageInfo.messageId}_${Date.now()}`;
  const delayMs = delayMinutes * 60 * 1000;
  const runAt = Date.now() + delayMs;

  Logger.info("scheduleAutoDownload: scheduling task", {
    taskId,
    channelId,
    scheduleId,
    userId,
    messageId: telegramMessageInfo.messageId,
    delayMinutes,
    runAt: new Date(runAt).toISOString(),
    hasVideoTitle: !!videoTitle,
    hasPrompt: !!prompt
  });

  // ДЕДУПЛИКАЦИЯ: Отменяем предыдущую задачу для этого telegramMessageId, если она существует
  // Это предотвращает дублирование загрузки одного и того же видео
  // ИСПРАВЛЕНИЕ: Используем более надёжный ключ для дедупликации
  const deduplicationKey = `${channelId}_${telegramMessageInfo.messageId}`;
  const existingTask = Array.from(activeTasks.values()).find(
    (task) => 
      task.channelId === channelId && 
      task.telegramMessageId === telegramMessageInfo.messageId
  );
  
  if (existingTask && existingTask.timeoutId) {
    console.log("DUPLICATE_TASK_CANCELLED:", {
      existingTaskId: existingTask.id,
      newTaskId: taskId,
      channelId,
      messageId: telegramMessageInfo.messageId,
      reason: "duplicate_prevention"
    });

    Logger.warn("scheduleAutoDownload: cancelling existing task for same telegramMessageId (duplicate prevention)", {
      existingTaskId: existingTask.id,
      channelId,
      scheduleId: existingTask.scheduleId,
      messageId: telegramMessageInfo.messageId,
      newScheduleId: scheduleId,
      deduplicationKey
    });
    clearTimeout(existingTask.timeoutId);
    activeTasks.delete(existingTask.id);
  }

  // Создаём таймаут для выполнения задачи
  // ВАЖНО: setTimeout может не сохранить контекст при перезапуске сервера
  // Для production лучше использовать persistent queue (например, Bull/BullMQ)
  const timeoutId = setTimeout(async () => {
    console.log("AUTO_TASK_START:", {
      taskId,
      channelId,
      scheduleId,
      userId,
      messageId: telegramMessageInfo.messageId,
      chatId: telegramMessageInfo.chatId,
      scheduledAt: new Date().toISOString(),
      delayMinutes,
      note: "Task execution started"
    });

    Logger.info("scheduleAutoDownload: executing scheduled task", {
      taskId,
      channelId,
      scheduleId,
      userId,
      messageId: telegramMessageInfo.messageId,
      chatId: telegramMessageInfo.chatId,
      scheduledAt: new Date().toISOString()
    });

    try {
      // Получаем сохранённые данные задачи
      const savedTask = activeTasks.get(taskId);
      
      if (!savedTask) {
        console.error("AUTO_TASK_ERROR: Task not found in activeTasks", {
          taskId,
          activeTasksCount: activeTasks.size,
          activeTaskIds: Array.from(activeTasks.keys()).slice(0, 5)
        });
        Logger.error("scheduleAutoDownload: task not found in activeTasks", {
          taskId,
          activeTasksCount: activeTasks.size
        });
        return;
      }
      
      console.log("AUTO_TASK_DATA_RETRIEVED:", {
        taskId,
        hasVideoTitle: !!savedTask?.videoTitle,
        hasPrompt: !!savedTask?.prompt,
        promptLength: savedTask?.prompt?.length || 0,
        videoTitle: savedTask?.videoTitle || "NOT_SET"
      });
      
      Logger.info("scheduleAutoDownload: task data retrieved", {
        taskId,
        hasVideoTitle: !!savedTask?.videoTitle,
        hasPrompt: !!savedTask?.prompt,
        promptLength: savedTask?.prompt?.length || 0
      });
      
      // ИДЕМПОТЕНТНОСТЬ: Проверяем, не было ли уже сохранено видео для этого telegramMessageId
      // Это дополнительная защита на случай, если задача была запланирована дважды
      try {
        const { db, isFirestoreAvailable } = await import("./firebaseAdmin");
        if (isFirestoreAvailable() && db) {
          const channelRef = db
            .collection("users")
            .doc(userId)
            .collection("channels")
            .doc(channelId);

          // Проверяем в generatedVideos, не было ли уже сохранено локально
          const existingVideosQuery = await channelRef
            .collection("generatedVideos")
            .where("telegramMessageId", "==", telegramMessageInfo.messageId)
            .limit(1)
            .get();

          if (!existingVideosQuery.empty) {
            const existingVideo = existingVideosQuery.docs[0].data();
            if (existingVideo.localFilePath) {
              console.log("DOWNLOAD_SKIPPED_ALREADY_SAVED:", {
                taskId,
                reason: "found_in_generatedVideos_before_download",
                localFilePath: existingVideo.localFilePath
              });

              Logger.warn("scheduleAutoDownload: task skipped - already saved locally", {
                taskId,
                channelId,
                telegramMessageId: telegramMessageInfo.messageId,
                localFilePath: existingVideo.localFilePath
              });

              activeTasks.delete(taskId);
              return;
            }
          }
        }
      } catch (checkError) {
        Logger.warn("scheduleAutoDownload: failed to check for existing save, proceeding anyway", {
          taskId,
          error: checkError instanceof Error ? checkError.message : String(checkError)
        });
        // Продолжаем выполнение, если проверка не удалась
      }

      // Логируем начало скачивания
      Logger.info("scheduleAutoDownload: starting video download to local storage", {
        taskId,
        channelId,
        userId,
        telegramMessageId: telegramMessageInfo.messageId,
        scheduleId,
        timestamp: new Date().toISOString(),
        videoTitle: savedTask?.videoTitle || "not provided",
        storageRoot: process.env.STORAGE_ROOT || "default (storage/videos)"
      });

      console.log("AUTO_DOWNLOAD_START:", {
        taskId,
        channelId,
        userId,
        telegramMessageId: telegramMessageInfo.messageId,
        scheduleId,
        timestamp: new Date().toISOString(),
        storageRoot: process.env.STORAGE_ROOT || "default (storage/videos)"
      });

      // Вызываем функцию скачивания и сохранения в локальное хранилище
      const result = await downloadAndSaveToLocal({
        channelId,
        userId,
        telegramMessageId: telegramMessageInfo.messageId,
        videoTitle: savedTask?.videoTitle,
        prompt: savedTask?.prompt
      });

      if (result.success) {
        Logger.info("scheduleAutoDownload: task completed successfully - video saved to local storage", {
          taskId,
          channelId,
          scheduleId,
          inputPath: result.inputPath,
          filename: result.filename,
          channelSlug: result.channelSlug || "",
          storage: {
            userDir: result.storage?.userDir || "",
            inputDir: result.storage?.inputDir || "",
            filePath: result.storage?.filePath || ""
          },
          savedAt: new Date().toISOString()
        });

        console.log("AUTO_DOWNLOAD_SUCCESS:", {
          taskId,
          channelId,
          scheduleId,
          inputPath: result.inputPath,
          filename: result.filename,
          filePath: result.storage?.filePath,
          timestamp: new Date().toISOString()
        });
      } else {
        Logger.error("scheduleAutoDownload: task failed - video not saved", {
          taskId,
          channelId,
          scheduleId,
          error: result.error,
          errorDetails: {
            hasInputPath: !!result.inputPath,
            hasFilename: !!result.filename
          }
        });

        console.error("AUTO_DOWNLOAD_FAILED:", {
          taskId,
          channelId,
          scheduleId,
          error: result.error,
          timestamp: new Date().toISOString()
        });
      }
    } catch (error) {
      Logger.error("scheduleAutoDownload: task execution error", {
        taskId,
        channelId,
        scheduleId,
        error: error instanceof Error ? error.message : String(error),
        errorStack: error instanceof Error ? error.stack : undefined,
        errorName: error instanceof Error ? error.name : undefined
      });
    } finally {
      // Удаляем задачу из активных
      activeTasks.delete(taskId);
      Logger.info("scheduleAutoDownload: task removed from active tasks", {
        taskId,
        remainingActiveTasks: activeTasks.size
      });
    }
  }, delayMs);

  // Сохраняем задачу
  const task: ScheduledTask = {
    id: taskId,
    channelId,
    scheduleId,
    userId,
    runAt,
    telegramMessageId: telegramMessageInfo.messageId,
    videoTitle,
    prompt,
    timeoutId
  };

  activeTasks.set(taskId, task);

  Logger.info("scheduleAutoDownload: task scheduled", {
    taskId,
    channelId,
    scheduleId,
    willRunAt: new Date(runAt).toISOString(),
    activeTasksCount: activeTasks.size
  });

  return taskId;
}

/**
 * Отменяет запланированную задачу
 * @param taskId - ID задачи
 */
export function cancelScheduledTask(taskId: string): boolean {
  const task = activeTasks.get(taskId);
  if (!task) {
    return false;
  }

  if (task.timeoutId) {
    clearTimeout(task.timeoutId);
  }

  activeTasks.delete(taskId);

  Logger.info("cancelScheduledTask: task cancelled", {
    taskId,
    channelId: task.channelId,
    scheduleId: task.scheduleId
  });

  return true;
}

/**
 * Отменяет все задачи для указанного канала и расписания
 * @param channelId - ID канала
 * @param scheduleId - ID расписания
 */
export function cancelTasksForSchedule(channelId: string, scheduleId: string): number {
  let cancelledCount = 0;

  for (const [taskId, task] of activeTasks.entries()) {
    if (task.channelId === channelId && task.scheduleId === scheduleId) {
      if (task.timeoutId) {
        clearTimeout(task.timeoutId);
      }
      activeTasks.delete(taskId);
      cancelledCount++;
    }
  }

  if (cancelledCount > 0) {
    Logger.info("cancelTasksForSchedule: tasks cancelled", {
      channelId,
      scheduleId,
      cancelledCount
    });
  }

  return cancelledCount;
}

/**
 * Получает информацию о всех активных задачах
 */
export function getActiveTasks(): Array<{
  id: string;
  channelId: string;
  scheduleId: string;
  userId: string;
  runAt: string;
  telegramMessageId?: number;
}> {
  return Array.from(activeTasks.values()).map((task) => ({
    id: task.id,
    channelId: task.channelId,
    scheduleId: task.scheduleId,
    userId: task.userId,
    runAt: new Date(task.runAt).toISOString(),
    telegramMessageId: task.telegramMessageId
  }));
}

