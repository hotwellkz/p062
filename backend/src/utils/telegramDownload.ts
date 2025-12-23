import * as fs from "fs/promises";
import * as path from "path";
import { randomUUID } from "crypto";
import type { TelegramClient } from "telegram";
import type { Api } from "telegram";
import { Logger } from "./logger";
import {
  extractVideoUrlFromGetVideoPage,
  downloadGetVideoPage,
  downloadVideoFromUrl,
  extractVideoUrlFromText
} from "./getvideoParser";

// Используем process.cwd() для определения корня проекта (backend/)
// Это работает и в dev режиме (ts-node-dev), и после компиляции (dist/)
const TMP_DIR = path.join(process.cwd(), "tmp");
const MAX_FILE_SIZE = 100 * 1024 * 1024; // 100 MB

/**
 * Создаёт временную директорию, если её нет
 */
async function ensureTmpDir(): Promise<void> {
  try {
    await fs.access(TMP_DIR);
    // Папка существует, не логируем (можно использовать Logger.info для отладки)
  } catch {
    await fs.mkdir(TMP_DIR, { recursive: true });
    Logger.info("Created tmp directory", { path: TMP_DIR });
  }
}

/**
 * Скачивает видео из Telegram во временную папку
 * @param client - Telegram клиент
 * @param messageId - ID сообщения с видео (опционально, если не указан - ищет последнее)
 * @param chatId - ID чата (например, SYNX_CHAT_ID)
 * @returns Путь к временному файлу и имя файла
 */
export async function downloadTelegramVideoToTemp(
  client: TelegramClient,
  chatId: string | number,
  messageId?: number
): Promise<{ tempPath: string; fileName: string; messageId: number }> {
  await ensureTmpDir();

  let videoMessage: Api.Message;

  try {
    // ИСПРАВЛЕНИЕ: Если указан messageId, это обычно ID промпта (текстового сообщения),
    // а не видео. Видео приходит позже. Поэтому мы НЕ пытаемся получить сообщение с этим ID,
    // а ищем последнее видео ПОСЛЕ этого messageId.
    // Всегда ищем последнее видео в чате, но если messageId указан, фильтруем только видео после него
    
    // Ищем последнее видео в чате
    // Если messageId передан, ищем видео ПОСЛЕ этого сообщения (для автоматического скачивания)
    Logger.info("Searching for latest video in Telegram chat", {
      chatId,
      limit: messageId ? 100 : 50,
      afterMessageId: messageId || "not specified",
      note: messageId 
        ? "Will search for video after this prompt message ID" 
        : "Will search for latest video in chat"
    });

      let messages: Api.Message[];
      try {
        // Получаем больше сообщений, если нужно искать после конкретного messageId
        const limit = messageId ? 100 : 50;
        
        messages = await Promise.race([
          client.getMessages(chatId, {
            limit
          }) as Promise<Api.Message[]>,
          new Promise<Api.Message[]>((_, reject) => 
            setTimeout(() => reject(new Error("Get messages timeout after 30 seconds")), 30000)
          )
        ]);
      } catch (getMsgError: any) {
        const errorMsg = String(getMsgError?.message ?? getMsgError);
        const errorCode = getMsgError?.code;
        const errorClassName = getMsgError?.className;
        const errorErrorCode = getMsgError?.error_code;
        const errorErrorMessage = getMsgError?.error_message;
        
        // Детальное логирование реальной ошибки
        Logger.error("Error getting messages from Telegram chat - ДЕТАЛЬНАЯ ИНФОРМАЦИЯ", {
          error: errorMsg,
          errorCode,
          errorClassName,
          errorErrorCode,
          errorErrorMessage,
          chatId,
          messageId: messageId || "not specified",
          fullError: {
            message: errorMsg,
            code: errorCode,
            className: errorClassName,
            error_code: errorErrorCode,
            error_message: errorErrorMessage,
            name: getMsgError?.name,
            constructor: getMsgError?.constructor?.name
          }
        });
        
        // ТОЧНАЯ проверка на AUTH_KEY_UNREGISTERED (только настоящая ошибка сессии)
        const isAuthKeyUnregistered = 
          (errorCode === 401 && errorMsg?.includes("AUTH_KEY_UNREGISTERED")) ||
          (errorErrorCode === 401 && errorErrorMessage?.includes("AUTH_KEY_UNREGISTERED")) ||
          errorClassName === "AuthKeyUnregistered" ||
          (errorMsg?.includes("AUTH_KEY_UNREGISTERED") && 
           !errorMsg.includes("TELEGRAM_DOWNLOAD") && 
           !errorMsg.includes("TELEGRAM_TIMEOUT"));
        
        const isSessionRevoked = 
          errorClassName === "SessionRevoked" ||
          (errorMsg?.includes("SESSION_REVOKED") && 
           !errorMsg.includes("TELEGRAM_DOWNLOAD") && 
           !errorMsg.includes("TELEGRAM_TIMEOUT"));
        
        // Обработка ТОЛЬКО настоящей ошибки недействительной сессии Telegram
        if (isAuthKeyUnregistered || isSessionRevoked) {
          Logger.error("Telegram session invalid during getMessages - РЕАЛЬНАЯ ОШИБКА СЕССИИ", {
            error: errorMsg,
            errorCode,
            errorClassName,
            errorErrorCode,
            chatId,
            isAuthKeyUnregistered,
            isSessionRevoked
          });
          throw new Error(
            "TELEGRAM_SESSION_INVALID: Сессия Telegram недействительна (AUTH_KEY_UNREGISTERED). " +
            "Отвяжите и заново привяжите Telegram в настройках аккаунта."
          );
        }
        
        if (errorMsg.includes("timeout") || errorMsg.includes("TIMEOUT")) {
          throw new Error(
            "TELEGRAM_TIMEOUT: Превышено время ожидания получения сообщений. " +
            "Проверьте подключение к интернету и попробуйте ещё раз."
          );
        }
        throw getMsgError;
      }

      Logger.info(`Received ${messages.length} messages from Telegram chat`);

      // ========== ШАГ 1: ДЕТАЛЬНОЕ ЛОГИРОВАНИЕ ВСЕХ TELEGRAM UPDATES ==========
      // Логируем ВСЕ сообщения для анализа того, что реально приходит из Telegram
      messages.forEach((msg, index) => {
        const msgData = msg as any;
        const messageId = msgData.id;
        const messageText = msgData.message || "";
        const caption = msgData.caption || "";
        const entities = msgData.entities || [];
        const captionEntities = msgData.captionEntities || [];
        const replyMarkup = msgData.replyMarkup || null;
        const media = msgData.media || null;
        const video = msgData.video || null;
        const document = msgData.document || null;
        const photo = msgData.photo || null;
        
        // Извлекаем все URL из текста, caption и entities
        const textUrls: string[] = [];
        const captionUrls: string[] = [];
        const entityUrls: string[] = [];
        
        // Ищем URL в тексте
        const textUrlMatches = messageText.match(/https?:\/\/[^\s"']+/gi) || [];
        textUrls.push(...textUrlMatches);
        
        // Ищем URL в caption
        const captionUrlMatches = caption.match(/https?:\/\/[^\s"']+/gi) || [];
        captionUrls.push(...captionUrlMatches);
        
        // Ищем URL в entities (MessageEntityUrl, MessageEntityTextUrl)
        entities.forEach((entity: any) => {
          if (entity?.className === "MessageEntityUrl" || entity?.className === "MessageEntityTextUrl") {
            if (entity.url) {
              entityUrls.push(entity.url);
            } else if (entity.offset !== undefined && entity.length !== undefined) {
              const urlText = messageText.substring(entity.offset, entity.offset + entity.length);
              if (urlText.match(/^https?:\/\//i)) {
                entityUrls.push(urlText);
              }
            }
          }
        });
        
        // Ищем URL в caption entities
        captionEntities.forEach((entity: any) => {
          if (entity?.className === "MessageEntityUrl" || entity?.className === "MessageEntityTextUrl") {
            if (entity.url) {
              entityUrls.push(entity.url);
            } else if (entity.offset !== undefined && entity.length !== undefined) {
              const urlText = caption.substring(entity.offset, entity.offset + entity.length);
              if (urlText.match(/^https?:\/\//i)) {
                entityUrls.push(urlText);
              }
            }
          }
        });
        
        // Ищем URL в reply_markup (inline_keyboard buttons)
        const replyMarkupUrls: string[] = [];
        if (replyMarkup && replyMarkup.className === "ReplyInlineMarkup") {
          const buttons = replyMarkup.rows || [];
          buttons.forEach((row: any) => {
            row.buttons?.forEach((button: any) => {
              if (button?.className === "KeyboardButtonUrl" || button?.className === "KeyboardButtonCallback") {
                if (button.url) {
                  replyMarkupUrls.push(button.url);
                }
              }
            });
          });
        }
        
        // Маскируем токены в URL для логирования
        const maskUrl = (url: string) => {
          try {
            const urlObj = new URL(url);
            const sensitiveParams = ["token", "key", "auth", "signature", "sig"];
            sensitiveParams.forEach((param) => {
              if (urlObj.searchParams.has(param)) {
                urlObj.searchParams.set(param, "***");
              }
            });
            return urlObj.toString();
          } catch {
            return url.substring(0, 100) + "...";
          }
        };
        
        Logger.info(`[TELEGRAM_UPDATE_ANALYSIS] Message #${index + 1}/${messages.length}`, {
          messageId,
          date: msgData.date ? (msgData.date instanceof Date ? msgData.date.toISOString() : new Date(msgData.date * 1000).toISOString()) : "unknown",
          // Текст сообщения
          hasText: !!messageText,
          textLength: messageText.length,
          textPreview: messageText.substring(0, 500).replace(/[?&](token|key|auth|signature|sig)=[^&]*/gi, "***"),
          // Caption
          hasCaption: !!caption,
          captionLength: caption.length,
          captionPreview: caption.substring(0, 500).replace(/[?&](token|key|auth|signature|sig)=[^&]*/gi, "***"),
          // Entities
          entitiesCount: entities.length,
          entities: entities.map((e: any) => ({
            className: e?.className,
            offset: e?.offset,
            length: e?.length,
            url: e?.url ? maskUrl(e.url) : undefined
          })),
          captionEntitiesCount: captionEntities.length,
          // Media
          hasMedia: !!media,
          mediaClassName: media?.className,
          hasVideo: !!video,
          hasDocument: !!document,
          hasPhoto: !!photo,
          documentFileName: document?.fileName,
          documentMimeType: document?.mimeType,
          // URLs найденные в тексте
          textUrls: textUrls.map(maskUrl),
          textUrlsCount: textUrls.length,
          // URLs найденные в caption
          captionUrls: captionUrls.map(maskUrl),
          captionUrlsCount: captionUrls.length,
          // URLs найденные в entities
          entityUrls: entityUrls.map(maskUrl),
          entityUrlsCount: entityUrls.length,
          // URLs найденные в reply_markup
          replyMarkupUrls: replyMarkupUrls.map(maskUrl),
          replyMarkupUrlsCount: replyMarkupUrls.length,
          // Все URL вместе
          allUrls: [...textUrls, ...captionUrls, ...entityUrls, ...replyMarkupUrls].map(maskUrl),
          allUrlsCount: textUrls.length + captionUrls.length + entityUrls.length + replyMarkupUrls.length,
          // Проверка на r2.syntx.ai
          hasR2SyntxUrl: [...textUrls, ...captionUrls, ...entityUrls, ...replyMarkupUrls].some(url => 
            url.toLowerCase().includes("r2.syntx.ai")
          ),
          // Проверка на getvideo
          hasGetVideoUrl: [...textUrls, ...captionUrls, ...entityUrls, ...replyMarkupUrls].some(url => 
            url.toLowerCase().includes("getvideo")
          ),
          // Проверка на mp4
          hasMp4Url: [...textUrls, ...captionUrls, ...entityUrls, ...replyMarkupUrls].some(url => 
            url.toLowerCase().includes(".mp4")
          ),
          // Reply markup
          hasReplyMarkup: !!replyMarkup,
          replyMarkupClassName: replyMarkup?.className
        });
      });
      
      // ========== КРИТИЧЕСКИЙ ВЫВОД: ЕСТЬ ЛИ URL В TELEGRAM UPDATE? ==========
      const allMessagesUrls: string[] = [];
      messages.forEach((msg) => {
        const msgData = msg as any;
        const messageText = msgData.message || "";
        const caption = msgData.caption || "";
        const entities = msgData.entities || [];
        const captionEntities = msgData.captionEntities || [];
        const replyMarkup = msgData.replyMarkup || null;
        
        // Собираем все URL
        const textUrls = messageText.match(/https?:\/\/[^\s"']+/gi) || [];
        const captionUrls = caption.match(/https?:\/\/[^\s"']+/gi) || [];
        
        entities.forEach((entity: any) => {
          if (entity?.url) allMessagesUrls.push(entity.url);
        });
        
        captionEntities.forEach((entity: any) => {
          if (entity?.url) allMessagesUrls.push(entity.url);
        });
        
        if (replyMarkup && replyMarkup.className === "ReplyInlineMarkup") {
          const buttons = replyMarkup.rows || [];
          buttons.forEach((row: any) => {
            row.buttons?.forEach((button: any) => {
              if (button?.url) allMessagesUrls.push(button.url);
            });
          });
        }
        
        allMessagesUrls.push(...textUrls, ...captionUrls);
      });
      
      const hasR2SyntxUrl = allMessagesUrls.some(url => url.toLowerCase().includes("r2.syntx.ai"));
      const hasGetVideoUrl = allMessagesUrls.some(url => url.toLowerCase().includes("getvideo"));
      const hasMp4Url = allMessagesUrls.some(url => url.toLowerCase().includes(".mp4"));
      
      Logger.info("[TELEGRAM_UPDATE_ANALYSIS] КРИТИЧЕСКИЙ ВЫВОД", {
        totalMessages: messages.length,
        totalUrlsFound: allMessagesUrls.length,
        hasR2SyntxUrl,
        hasGetVideoUrl,
        hasMp4Url,
        hasAnyVideoUrl: hasR2SyntxUrl || hasGetVideoUrl || hasMp4Url,
        conclusion: hasR2SyntxUrl || hasGetVideoUrl || hasMp4Url
          ? "✅ URL НАЙДЕН В TELEGRAM UPDATE - можно парсить"
          : "❌ URL НЕТ В TELEGRAM UPDATE - Telegram не содержит данных для скачивания видео"
      });

      // Фильтруем сообщения с видео или ссылками на getvideo
      // Если messageId указан, фильтруем только сообщения ПОСЛЕ него (с большим ID)
      const videoMessages = messages
        .filter((msg) => {
          // Если указан messageId, берём только сообщения после него
          if (messageId) {
            const msgId = (msg as any).id;
            if (typeof msgId === "number" && msgId <= messageId) {
              return false; // Пропускаем сообщения до или равные messageId промпта
            }
          }
          
          try {
            // Проверяем наличие video attachment
            const hasVideo =
              "video" in msg &&
              (msg as any).video != null &&
              !(msg as any).video.deleted;

            // Проверяем наличие document с видео-атрибутом
            const doc = (msg as any).document;
            const hasDocVideo =
              doc != null &&
              Array.isArray(doc.attributes) &&
              doc.attributes.some(
                (attr: any) =>
                  attr?.className === "DocumentAttributeVideo" ||
                  attr?.className === "MessageMediaDocument"
              ) &&
              // Дополнительная проверка MIME типа для документов
              (doc.mimeType?.startsWith("video/") ||
                doc.mimeType === "application/octet-stream" ||
                doc.fileName?.match(/\.(mp4|avi|mov|mkv|webm)$/i));

            // НОВОЕ: Проверяем наличие ссылки на getvideo.syntxai.net в тексте сообщения
            const messageText = (msg as any).message || "";
            const hasGetVideoLink =
              typeof messageText === "string" &&
              (messageText.includes("getvideo.syntxai.net") ||
                messageText.includes("getvideo") ||
                messageText.match(/https?:\/\/[^\s]+getvideo[^\s]+/i));

            return hasVideo || hasDocVideo || hasGetVideoLink;
          } catch (filterError) {
            Logger.warn("Error filtering video message", {
              messageId: (msg as any).id,
              error: String(filterError)
            });
            return false;
          }
        })
        .sort((a, b) => {
          // Сортируем по дате (самое свежее первым)
          let dateA = 0;
          let dateB = 0;

          try {
            const msgA = a as any;
            const msgB = b as any;

            if (msgA.date) {
              dateA =
                msgA.date instanceof Date
                  ? msgA.date.getTime()
                  : typeof msgA.date === "number"
                    ? msgA.date * 1000
                    : new Date(msgA.date).getTime();
            } else if (msgA.id) {
              dateA = msgA.id;
            }

            if (msgB.date) {
              dateB =
                msgB.date instanceof Date
                  ? msgB.date.getTime()
                  : typeof msgB.date === "number"
                    ? msgB.date * 1000
                    : new Date(msgB.date).getTime();
            } else if (msgB.id) {
              dateB = msgB.id;
            }
          } catch (sortError) {
            Logger.warn("Error sorting messages by date", {
              error: String(sortError)
            });
          }

          return dateB - dateA; // Сортируем по убыванию (новые первыми)
        });

      if (videoMessages.length === 0) {
        if (messageId) {
          throw new Error(
            `NO_VIDEO_FOUND: Видео ещё не готово в чате после сообщения ${messageId}. ` +
            `Подождите окончания генерации и попробуйте ещё раз.`
          );
        } else {
          throw new Error(
            "NO_VIDEO_FOUND: Видео ещё не готово в чате. Подождите окончания генерации и попробуйте ещё раз."
          );
        }
      }

      videoMessage = videoMessages[0];
      
      Logger.info("Found video message after filtering", {
        videoMessageId: (videoMessage as any).id,
        promptMessageId: messageId || "not specified",
        totalVideoMessages: videoMessages.length
      });

    Logger.info("Video message found, preparing to download", {
      messageId: videoMessage.id,
      hasVideo: "video" in videoMessage,
      hasDocument: "document" in videoMessage,
      hasText: !!(videoMessage as any).message
    });

    // УНИВЕРСАЛЬНЫЙ ИЗВЛЕКАТЕЛЬ URL: проверяем текст сообщения на наличие видео URL
    const messageText = (videoMessage as any).message || "";
    
    if (messageText && messageText.length > 0) {
      Logger.info("Checking message text for video URLs", {
        messageId: videoMessage.id,
        textLength: messageText.length,
        textPreview: messageText.substring(0, 200).replace(/[?&](token|key|auth|signature|sig)=[^&]*/gi, "***")
      });

      // Используем универсальный извлекатель
      const extractedUrl = extractVideoUrlFromText(messageText);

      if (extractedUrl) {
        Logger.info("Found video URL in message text", {
          messageId: videoMessage.id,
          source: extractedUrl.source,
          type: extractedUrl.type,
          url: extractedUrl.videoUrl.replace(/[?&](token|key|auth|signature|sig)=[^&]*/gi, "***")
        });

        // Если это M3U8, возвращаем понятную ошибку
        if (extractedUrl.type === "m3u8") {
          throw new Error(
            "M3U8_NOT_SUPPORTED: Найдена ссылка на M3U8 поток. Прямое скачивание M3U8 пока не поддерживается. Используйте другой формат видео."
          );
        }

        // Если это прямой MP4 (r2.syntx.ai или другой), скачиваем сразу
        if (extractedUrl.type === "mp4") {
          try {
            const downloadResult = await downloadVideoFromUrl(
              extractedUrl.videoUrl,
              undefined,
              { maxRetries: 3, progressIntervalMB: 10 }
            );

            Logger.info("Video downloaded from direct MP4 URL successfully", {
              messageId: videoMessage.id,
              source: extractedUrl.source,
              tempPath: downloadResult.tempPath,
              fileSize: downloadResult.fileSize,
              fileName: downloadResult.fileName
            });

            return {
              tempPath: downloadResult.tempPath,
              fileName: downloadResult.fileName,
              messageId: videoMessage.id as number
            };
          } catch (downloadError: any) {
            Logger.error("Error downloading direct MP4 URL", {
              messageId: videoMessage.id,
              source: extractedUrl.source,
              url: extractedUrl.videoUrl.replace(/[?&](token|key|auth|signature|sig)=[^&]*/gi, "***"),
              error: String(downloadError?.message ?? downloadError)
            });
            throw downloadError;
          }
        }
      }

      // Если не нашли прямой MP4, но есть getvideo URL, парсим HTML
      const getVideoUrlMatch = messageText.match(
        /https?:\/\/[^\s"']*getvideo[^\s"']*/i
      );

      if (getVideoUrlMatch && getVideoUrlMatch[0]) {
        const getVideoUrl = getVideoUrlMatch[0];
        Logger.info("Found getvideo URL in message, parsing HTML", {
          messageId: videoMessage.id,
          getVideoUrl: getVideoUrl.replace(/[?&](token|key|auth|signature|sig)=[^&]*/gi, "***")
        });

        try {
          // Скачиваем HTML страницу
          const html = await downloadGetVideoPage(getVideoUrl);
          
          // Извлекаем URL видео из HTML
          const videoInfo = await extractVideoUrlFromGetVideoPage(html, getVideoUrl);
          
          if (!videoInfo) {
            throw new Error(
              "GETVIDEO_PARSE_ERROR: Не удалось найти URL видео на странице getvideo"
            );
          }

          Logger.info("Extracted video URL from getvideo page", {
            messageId: videoMessage.id,
            videoType: videoInfo.type,
            videoUrl: videoInfo.videoUrl.replace(/[?&](token|key|auth|signature|sig)=[^&]*/gi, "***")
          });

          // Скачиваем видео по найденному URL
          const downloadResult = await downloadVideoFromUrl(
            videoInfo.videoUrl,
            undefined,
            { maxRetries: 3, progressIntervalMB: 10 }
          );

          Logger.info("Video downloaded from getvideo URL successfully", {
            messageId: videoMessage.id,
            tempPath: downloadResult.tempPath,
            fileSize: downloadResult.fileSize,
            fileName: downloadResult.fileName
          });

          return {
            tempPath: downloadResult.tempPath,
            fileName: downloadResult.fileName,
            messageId: videoMessage.id as number
          };
        } catch (getVideoError: any) {
          Logger.error("Error processing getvideo URL", {
            messageId: videoMessage.id,
            getVideoUrl: getVideoUrl.replace(/[?&](token|key|auth|signature|sig)=[^&]*/gi, "***"),
            error: String(getVideoError?.message ?? getVideoError)
          });
          
          // Если не удалось обработать getvideo, пробуем стандартный способ
          Logger.warn("Falling back to standard video download after getvideo error", {
            messageId: videoMessage.id
          });
          // Продолжаем выполнение ниже для стандартной обработки
        }
      }
    }

    // Определяем имя файла из сообщения или используем дефолтное
    let originalFileName = "video.mp4";
    const doc = (videoMessage as any).document;
    if (doc?.fileName) {
      originalFileName = doc.fileName;
    } else if ((videoMessage as any).video) {
      originalFileName = `video_${videoMessage.id}.mp4`;
    }

    // Генерируем уникальное имя файла для временной папки
    // Используем timestamp и UUID для уникальности
    const fileExtension = path.extname(originalFileName) || ".mp4";
    const uniqueFileName = `${Date.now()}_${randomUUID().slice(0, 8)}${fileExtension}`;
    const tempPath = path.join(TMP_DIR, uniqueFileName);
    
    // Логируем полный путь для отладки
    Logger.info("Generated temp file path", {
      tmpDir: TMP_DIR,
      uniqueFileName,
      tempPath,
      absolutePath: path.resolve(tempPath)
    });

    Logger.info("Starting video download from Telegram to temp file", {
      messageId: videoMessage.id,
      tempPath,
      originalFileName
    });

    const downloadStartTime = Date.now();

    // Скачиваем файл в Buffer, затем записываем в файл
    // Это более надёжный способ, чем прямое скачивание в файл
    Logger.info("Downloading media to buffer", {
      messageId: videoMessage.id,
      tempPath
    });

    let fileBuffer: Buffer;
    try {
      // Добавляем таймаут для скачивания (5 минут для больших файлов)
      const downloadTimeout = 5 * 60 * 1000; // 5 минут
      
      fileBuffer = await Promise.race([
        client.downloadMedia(videoMessage, {}) as Promise<Buffer>,
        new Promise<Buffer>((_, reject) => 
          setTimeout(() => reject(new Error("Download timeout after 5 minutes")), downloadTimeout)
        )
      ]);
    } catch (downloadError: any) {
      const errorMessage = String(downloadError?.message ?? downloadError);
      const errorCode = downloadError?.code;
      const errorClassName = downloadError?.className;
      const errorErrorCode = downloadError?.error_code;
      const errorErrorMessage = downloadError?.error_message;
      
      // Детальное логирование реальной ошибки
      Logger.error("Error during Telegram media download to buffer - ДЕТАЛЬНАЯ ИНФОРМАЦИЯ", {
        error: errorMessage,
        errorCode,
        errorClassName,
        errorErrorCode,
        errorErrorMessage,
        messageId: videoMessage.id,
        errorType: downloadError?.name,
        fullError: {
          message: errorMessage,
          code: errorCode,
          className: errorClassName,
          error_code: errorErrorCode,
          error_message: errorErrorMessage,
          name: downloadError?.name,
          constructor: downloadError?.constructor?.name
        }
      });
      
      // ТОЧНАЯ проверка на AUTH_KEY_UNREGISTERED (только настоящая ошибка сессии)
      const isAuthKeyUnregistered = 
        (errorCode === 401 && errorMessage?.includes("AUTH_KEY_UNREGISTERED")) ||
        (errorErrorCode === 401 && errorErrorMessage?.includes("AUTH_KEY_UNREGISTERED")) ||
        errorClassName === "AuthKeyUnregistered" ||
        (errorMessage?.includes("AUTH_KEY_UNREGISTERED") && 
         !errorMessage.includes("TELEGRAM_DOWNLOAD") && 
         !errorMessage.includes("TELEGRAM_TIMEOUT"));
      
      const isSessionRevoked = 
        errorClassName === "SessionRevoked" ||
        (errorMessage?.includes("SESSION_REVOKED") && 
         !errorMessage.includes("TELEGRAM_DOWNLOAD") && 
         !errorMessage.includes("TELEGRAM_TIMEOUT"));
      
      // Обработка ТОЛЬКО настоящей ошибки недействительной сессии Telegram
      if (isAuthKeyUnregistered || isSessionRevoked) {
        Logger.error("Telegram session invalid during video download - РЕАЛЬНАЯ ОШИБКА СЕССИИ", {
          error: errorMessage,
          errorCode,
          errorClassName,
          errorErrorCode,
          chatId,
          messageId: videoMessage.id,
          isAuthKeyUnregistered,
          isSessionRevoked
        });
        throw new Error(
          "TELEGRAM_SESSION_INVALID: Сессия Telegram недействительна (AUTH_KEY_UNREGISTERED). " +
          "Отвяжите и заново привяжите Telegram в настройках аккаунта."
        );
      }
      
      // Специальная обработка таймаутов
      if (errorMessage.includes("timeout") || errorMessage.includes("TIMEOUT")) {
        throw new Error(
          "TELEGRAM_DOWNLOAD_TIMEOUT: Превышено время ожидания скачивания видео. " +
          "Проверьте подключение к интернету и попробуйте ещё раз."
        );
      }
      
      throw new Error(
        `TELEGRAM_DOWNLOAD_ERROR: ${errorMessage || "Не удалось скачать видео из Telegram"}`
      );
    }

    if (!fileBuffer || fileBuffer.length === 0) {
      Logger.error("Downloaded file buffer is empty", {
        messageId: videoMessage.id,
        hasVideo: "video" in videoMessage,
        hasDocument: "document" in videoMessage
      });
      throw new Error(
        "TELEGRAM_DOWNLOAD_FAILED: Скачанный файл пуст или повреждён. Возможно, видео ещё не готово."
      );
    }
    
    // Дополнительная проверка: файл должен быть больше 1KB (минимальный размер для видео)
    if (fileBuffer.length < 1024) {
      Logger.error("Downloaded file is too small (likely incomplete)", {
        messageId: videoMessage.id,
        fileSize: fileBuffer.length,
        expectedMinSize: 1024
      });
      throw new Error(
        "TELEGRAM_DOWNLOAD_FAILED: Скачанный файл слишком мал (возможно, видео ещё не готово или повреждено)."
      );
    }

    // Записываем Buffer в файл
    Logger.info("Writing buffer to file", {
      tempPath,
      bufferSize: fileBuffer.length
    });

    await fs.writeFile(tempPath, fileBuffer);

    // Проверяем, что файл был создан и не пустой
    const stats = await fs.stat(tempPath);
    if (stats.size === 0) {
      await fs.unlink(tempPath).catch(() => {});
      Logger.error("File written to disk is empty", {
        messageId: videoMessage.id,
        tempPath,
        bufferSize: fileBuffer.length
      });
      throw new Error(
        "TELEGRAM_DOWNLOAD_FAILED: Скачанный файл пуст или повреждён. Возможно, видео ещё не готово."
      );
    }
    
    // Проверяем, что размер файла на диске совпадает с размером буфера
    if (stats.size !== fileBuffer.length) {
      Logger.error("File size mismatch", {
        messageId: videoMessage.id,
        tempPath,
        bufferSize: fileBuffer.length,
        fileSize: stats.size
      });
      await fs.unlink(tempPath).catch(() => {});
      throw new Error(
        "TELEGRAM_DOWNLOAD_FAILED: Размер файла на диске не совпадает с размером буфера. Файл может быть повреждён."
      );
    }

    // Проверяем размер файла
    if (stats.size > MAX_FILE_SIZE) {
      await fs.unlink(tempPath).catch(() => {});
      throw new Error(
        `FILE_TOO_LARGE: Файл слишком большой (${(stats.size / (1024 * 1024)).toFixed(2)} MB). Максимальный размер: ${MAX_FILE_SIZE / (1024 * 1024)} MB.`
      );
    }

    const downloadDuration = Date.now() - downloadStartTime;
    const fileSizeMB = (stats.size / (1024 * 1024)).toFixed(2);

    Logger.info("Video downloaded successfully to temp file", {
      messageId: videoMessage.id,
      tempPath,
      fileSizeBytes: stats.size,
      fileSizeMB,
      downloadDurationMs: downloadDuration,
      downloadSpeedMBps: (
        (stats.size / (1024 * 1024)) /
        (downloadDuration / 1000)
      ).toFixed(2)
    });

    return {
      tempPath,
      fileName: originalFileName,
      messageId: videoMessage.id as number
    };
  } catch (error: any) {
    const errorMessage = String(error?.message ?? error);
    const errorCode = error?.code;
    const errorClassName = error?.className;

    Logger.error("Error downloading video from Telegram", {
      error: errorMessage,
      errorCode,
      errorClassName,
      chatId,
      messageId,
      fullError: error
    });

    // Пробрасываем ошибку дальше с понятным сообщением
    if (errorMessage.includes("TELEGRAM_SESSION_INVALID")) {
      throw new Error(errorMessage);
    }
    
    if (errorMessage.includes("NO_VIDEO_FOUND")) {
      throw new Error(errorMessage);
    }

    if (errorMessage.includes("not found")) {
      throw new Error(
        `TELEGRAM_MESSAGE_NOT_FOUND: Сообщение с ID ${messageId} не найдено в чате.`
      );
    }

    throw new Error(
      `TELEGRAM_DOWNLOAD_ERROR: ${errorMessage || "Не удалось скачать видео из Telegram"}`
    );
  }
}

/**
 * Удаляет временный файл
 * @param tempPath - Путь к временному файлу
 */
export async function cleanupTempFile(tempPath: string): Promise<void> {
  try {
    await fs.unlink(tempPath);
    Logger.info("Temporary file deleted", { tempPath });
  } catch (error) {
    Logger.warn("Failed to delete temporary file", {
      tempPath,
      error: String(error)
    });
    // Не пробрасываем ошибку, так как это cleanup операция
  }
}

