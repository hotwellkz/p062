import { Logger } from "./logger";
import * as fs from "fs/promises";
import { createWriteStream } from "fs";
import * as path from "path";
import { randomUUID } from "crypto";

/**
 * Универсальный извлекатель URL видео из любого текста/HTML
 * ПРИОРИТЕТ #1: Прямые ссылки на r2.syntx.ai/*.mp4
 * ПРИОРИТЕТ #2: Другие прямые ссылки на .mp4
 * ПРИОРИТЕТ #3: getvideo.syntxai.net (требует парсинга HTML)
 * ПРИОРИТЕТ #4: .m3u8 (возвращает ошибку, так как требует ffmpeg)
 */
export function extractVideoUrlFromText(
  text: string,
  maxLength: number = 50000
): { videoUrl: string; type: "mp4" | "webm" | "m3u8"; source: "direct_mp4" | "r2_syntx" | "getvideo" | "m3u8" } | null {
  const truncatedText = text.length > maxLength ? text.substring(0, maxLength) : text;
  
  Logger.info("Extracting video URL from text", {
    textLength: text.length,
    truncatedLength: truncatedText.length
  });

  // ПРИОРИТЕТ #1: r2.syntx.ai MP4 (самый надежный источник)
  const r2SyntxMatch = truncatedText.match(/https?:\/\/r2\.syntx\.ai\/[^\s"']+\.mp4(\?[^\s"']*)?/i);
  if (r2SyntxMatch && r2SyntxMatch[0]) {
    const url = r2SyntxMatch[0];
    Logger.info("Found r2.syntx.ai MP4 URL (PRIORITY #1)", {
      url: maskUrl(url),
      type: "mp4",
      source: "r2_syntx"
    });
    return { videoUrl: url, type: "mp4", source: "r2_syntx" };
  }

  // ПРИОРИТЕТ #2: Другие прямые MP4 ссылки
  const mp4Matches = truncatedText.matchAll(/https?:\/\/[^\s"']+\.mp4(\?[^\s"']*)?/gi);
  for (const match of mp4Matches) {
    if (match[0] && !match[0].includes("getvideo")) {
      const url = match[0];
      Logger.info("Found direct MP4 URL (PRIORITY #2)", {
        url: maskUrl(url),
        type: "mp4",
        source: "direct_mp4"
      });
      return { videoUrl: url, type: "mp4", source: "direct_mp4" };
    }
  }

  // ПРИОРИТЕТ #3: getvideo.syntxai.net (требует парсинга HTML)
  const getVideoMatch = truncatedText.match(/https?:\/\/[^\s"']*getvideo[^\s"']*/i);
  if (getVideoMatch && getVideoMatch[0]) {
    const url = getVideoMatch[0];
    Logger.info("Found getvideo URL (PRIORITY #3, requires HTML parsing)", {
      url: maskUrl(url),
      source: "getvideo"
    });
    // Возвращаем null, так как требуется парсинг HTML
    return null;
  }

  // ПРИОРИТЕТ #4: .m3u8 (возвращаем для обработки ошибки)
  const m3u8Match = truncatedText.match(/https?:\/\/[^\s"']+\.m3u8(\?[^\s"']*)?/i);
  if (m3u8Match && m3u8Match[0]) {
    const url = m3u8Match[0];
    Logger.warn("Found M3U8 URL (not supported yet)", {
      url: maskUrl(url),
      type: "m3u8",
      source: "m3u8"
    });
    return { videoUrl: url, type: "m3u8", source: "m3u8" };
  }

  Logger.warn("No video URL found in text", {
    textLength: text.length,
    hasR2Syntx: /r2\.syntx\.ai/i.test(truncatedText),
    hasGetVideo: /getvideo/i.test(truncatedText),
    hasMp4: /\.mp4/i.test(truncatedText),
    hasM3u8: /\.m3u8/i.test(truncatedText)
  });

  return null;
}

/**
 * Извлекает URL видео из HTML страницы getvideo.syntxai.net
 * Поддерживает: <video src>, <source src>, прямые ссылки на .mp4/.webm/.m3u8, JSON в скриптах
 */
export async function extractVideoUrlFromGetVideoPage(
  html: string,
  baseUrl: string
): Promise<{ videoUrl: string; type: "mp4" | "webm" | "m3u8" } | null> {
  Logger.info("Extracting video URL from getvideo page", {
    baseUrl: maskUrl(baseUrl),
    htmlLength: html.length
  });

  // 1. Ищем <video src="...">
  const videoSrcMatch = html.match(/<video[^>]+src=["']([^"']+)["']/i);
  if (videoSrcMatch && videoSrcMatch[1]) {
    const url = resolveUrl(videoSrcMatch[1], baseUrl);
    const type = getVideoType(url);
    if (type) {
      Logger.info("Found video URL in <video src>", {
        url: maskUrl(url),
        type
      });
      return { videoUrl: url, type };
    }
  }

  // 2. Ищем <source src="...">
  const sourceMatches = html.matchAll(/<source[^>]+src=["']([^"']+)["']/gi);
  for (const match of sourceMatches) {
    if (match[1]) {
      const url = resolveUrl(match[1], baseUrl);
      const type = getVideoType(url);
      if (type) {
        Logger.info("Found video URL in <source src>", {
          url: maskUrl(url),
          type
        });
        return { videoUrl: url, type };
      }
    }
  }

  // 3. ПРИОРИТЕТНО: Ищем прямые ссылки на r2.syntx.ai (финальный MP4)
  const r2SyntxMatches = html.matchAll(
    /https?:\/\/r2\.syntx\.ai\/[^\s"']+\.mp4(\?[^\s"']*)?/gi
  );
  for (const match of r2SyntxMatches) {
    if (match[0]) {
      const url = match[0];
      Logger.info("Found r2.syntx.ai MP4 URL (priority)", {
        url: maskUrl(url),
        type: "mp4"
      });
      return { videoUrl: url, type: "mp4" };
    }
  }

  // 4. Ищем прямые ссылки на видео файлы в тексте
  const directVideoMatches = html.matchAll(
    /https?:\/\/[^\s"']+\.(mp4|webm|m3u8)(\?[^\s"']*)?/gi
  );
  for (const match of directVideoMatches) {
    if (match[0]) {
      const url = match[0];
      const type = getVideoType(url);
      if (type) {
        Logger.info("Found direct video URL in text", {
          url: maskUrl(url),
          type
        });
        return { videoUrl: url, type };
      }
    }
  }

  // 5. Ищем JSON в скриптах (window.DATA, embedded json)
  const scriptMatches = html.matchAll(/<script[^>]*>([\s\S]*?)<\/script>/gi);
  for (const scriptMatch of scriptMatches) {
    const scriptContent = scriptMatch[1];
    
    // Ищем window.DATA или подобные объекты
    const dataMatch = scriptContent.match(
      /(?:window\.|var\s+)?DATA\s*=\s*({[^}]+"url"[^}]+})/i
    );
    if (dataMatch) {
      try {
        const jsonStr = dataMatch[1].replace(/'/g, '"');
        const data = JSON.parse(jsonStr);
        if (data.url || data.videoUrl || data.src) {
          const url = resolveUrl(data.url || data.videoUrl || data.src, baseUrl);
          const type = getVideoType(url);
          if (type) {
            Logger.info("Found video URL in JSON data", {
              url: maskUrl(url),
              type
            });
            return { videoUrl: url, type };
          }
        }
      } catch (e) {
        // Игнорируем ошибки парсинга JSON
      }
    }

    // Ищем другие JSON объекты с url
    const jsonUrlMatches = scriptContent.matchAll(
      /"url"\s*:\s*"([^"]+\.(mp4|webm|m3u8)[^"]*)"/gi
    );
    for (const jsonMatch of jsonUrlMatches) {
      if (jsonMatch[1]) {
        const url = resolveUrl(jsonMatch[1], baseUrl);
        const type = getVideoType(url);
        if (type) {
          Logger.info("Found video URL in JSON string", {
            url: maskUrl(url),
            type
          });
          return { videoUrl: url, type };
        }
      }
    }
  }

  Logger.warn("No video URL found in getvideo page", {
    baseUrl: maskUrl(baseUrl)
  });
  return null;
}

/**
 * Определяет тип видео по URL
 */
function getVideoType(url: string): "mp4" | "webm" | "m3u8" | null {
  const lowerUrl = url.toLowerCase();
  if (lowerUrl.includes(".m3u8") || lowerUrl.includes("m3u8")) {
    return "m3u8";
  }
  if (lowerUrl.includes(".webm") || lowerUrl.includes("webm")) {
    return "webm";
  }
  if (lowerUrl.includes(".mp4") || lowerUrl.includes("mp4")) {
    return "mp4";
  }
  return null;
}

/**
 * Разрешает относительный URL в абсолютный
 */
function resolveUrl(url: string, baseUrl: string): string {
  if (url.startsWith("http://") || url.startsWith("https://")) {
    return url;
  }
  try {
    const base = new URL(baseUrl);
    return new URL(url, base).toString();
  } catch {
    return url;
  }
}

/**
 * Маскирует токены в URL для логирования
 */
function maskUrl(url: string): string {
  try {
    const urlObj = new URL(url);
    // Маскируем query параметры, которые могут быть токенами
    const sensitiveParams = ["token", "key", "auth", "signature", "sig"];
    sensitiveParams.forEach((param) => {
      if (urlObj.searchParams.has(param)) {
        urlObj.searchParams.set(param, "***");
      }
    });
    return urlObj.toString();
  } catch {
    // Если не удалось распарсить URL, возвращаем как есть
    return url;
  }
}

/**
 * Скачивает HTML страницу getvideo.syntxai.net
 */
export async function downloadGetVideoPage(url: string): Promise<string> {
  Logger.info("Downloading getvideo page", {
    url: maskUrl(url)
  });

  try {
    // Используем fetch с правильными заголовками
    const response = await fetch(url, {
      method: "GET",
      headers: {
        "User-Agent":
          "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
        Accept:
          "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
        "Accept-Language": "en-US,en;q=0.9",
        "Accept-Encoding": "gzip, deflate, br",
        Connection: "keep-alive",
        "Upgrade-Insecure-Requests": "1"
      },
      redirect: "follow"
    });

    if (!response.ok) {
      throw new Error(
        `Failed to download getvideo page: ${response.status} ${response.statusText}`
      );
    }

    const html = await response.text();
    Logger.info("Downloaded getvideo page", {
      url: maskUrl(url),
      htmlLength: html.length,
      status: response.status
    });

    return html;
  } catch (error: any) {
    Logger.error("Error downloading getvideo page", {
      url: maskUrl(url),
      error: String(error?.message ?? error)
    });
    throw new Error(
      `GETVIDEO_DOWNLOAD_ERROR: Не удалось скачать страницу getvideo: ${error?.message ?? String(error)}`
    );
  }
}

/**
 * Скачивает видео файл по URL и сохраняет во временную папку
 * Поддерживает большие файлы через стриминг, Range запросы (206 Partial Content)
 * С ретраями и логированием прогресса
 */
export async function downloadVideoFromUrl(
  videoUrl: string,
  fileName?: string,
  options?: { maxRetries?: number; progressIntervalMB?: number }
): Promise<{ tempPath: string; fileName: string; fileSize: number }> {
  const TMP_DIR = path.join(process.cwd(), "tmp");
  await fs.mkdir(TMP_DIR, { recursive: true });

  const fileExtension = videoUrl.match(/\.(mp4|webm|m3u8)(\?|$)/i)?.[1] || "mp4";
  const uniqueFileName =
    fileName ||
    `${Date.now()}_${randomUUID().slice(0, 8)}.${fileExtension}`;
  const tempPath = path.join(TMP_DIR, uniqueFileName);

  const maxRetries = options?.maxRetries || 3;
  const progressIntervalMB = options?.progressIntervalMB || 10; // Логировать каждые 10 MB

  Logger.info("Downloading video from URL", {
    url: maskUrl(videoUrl),
    tempPath,
    fileName: uniqueFileName,
    maxRetries
  });

  let lastError: Error | null = null;

  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      if (attempt > 1) {
        Logger.info(`Retry attempt ${attempt}/${maxRetries}`, {
          url: maskUrl(videoUrl),
          previousError: String(lastError?.message || lastError)
        });
        // Небольшая задержка перед повтором
        await new Promise(resolve => setTimeout(resolve, 1000 * attempt));
      }

      // Сначала делаем HEAD запрос для проверки доступности и размера
      let contentLength: number | null = null;
      let supportsRange = false;
      
      try {
        const headResponse = await fetch(videoUrl, {
          method: "HEAD",
          headers: {
            "User-Agent":
              "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
            Accept: "*/*",
            Referer: "https://getvideo.syntxai.net/"
          },
          redirect: "follow",
          signal: AbortSignal.timeout(10000) // 10 секунд таймаут
        });

        if (headResponse.ok) {
          contentLength = headResponse.headers.get("content-length")
            ? parseInt(headResponse.headers.get("content-length")!, 10)
            : null;
          supportsRange = headResponse.headers.get("accept-ranges") === "bytes";
          
          const contentType = headResponse.headers.get("content-type");
          Logger.info("HEAD request successful", {
            url: maskUrl(videoUrl),
            attempt,
            contentLength: contentLength ? `${(contentLength / (1024 * 1024)).toFixed(2)} MB` : "unknown",
            contentType: contentType || "unknown",
            supportsRange
          });

          // Проверяем Content-Type
          if (contentType && !contentType.includes("video") && !contentType.includes("mp4") && !contentType.includes("octet-stream")) {
            Logger.warn("Content-Type is not video/mp4", {
              contentType,
              url: maskUrl(videoUrl)
            });
          }
        }
      } catch (headError: any) {
        Logger.warn("HEAD request failed, proceeding with GET", {
          url: maskUrl(videoUrl),
          attempt,
          error: String(headError?.message ?? headError)
        });
      }

      // Увеличиваем лимит для больших файлов (до 500 MB для r2.syntx.ai)
      const MAX_SIZE = 500 * 1024 * 1024; // 500 MB
      if (contentLength && contentLength > MAX_SIZE) {
        throw new Error(
          `FILE_TOO_LARGE: Файл слишком большой (${(contentLength / (1024 * 1024)).toFixed(2)} MB). Максимальный размер: ${MAX_SIZE / (1024 * 1024)} MB.`
        );
      }

      // Скачиваем файл с таймаутом
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), 300000); // 5 минут таймаут

      try {
        const response = await fetch(videoUrl, {
          method: "GET",
          headers: {
            "User-Agent":
              "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
            Accept: "*/*",
            "Accept-Language": "en-US,en;q=0.9",
            Connection: "keep-alive",
            Referer: "https://getvideo.syntxai.net/"
          },
          redirect: "follow",
          signal: controller.signal
        });

        clearTimeout(timeoutId);

        if (!response.ok) {
          throw new Error(
            `Failed to download video: ${response.status} ${response.statusText}`
          );
        }

        // Проверяем Content-Type в ответе
        const contentType = response.headers.get("content-type");
        if (contentType && !contentType.includes("video") && !contentType.includes("mp4") && !contentType.includes("octet-stream")) {
          Logger.warn("Response Content-Type is not video", {
            contentType,
            url: maskUrl(videoUrl),
            status: response.status,
            attempt
          });
        }

        // Скачиваем потоком
        const fileStream = createWriteStream(tempPath);
        const reader = response.body?.getReader();
        if (!reader) {
          throw new Error("Response body is not readable");
        }

        let totalSize = 0;
        let lastLoggedMB = 0;

        try {
          while (true) {
            const { done, value } = await reader.read();
            if (done) break;

            totalSize += value.length;
            
            // Логируем прогресс каждые N мегабайт
            const currentMB = Math.floor(totalSize / (1024 * 1024));
            if (currentMB >= lastLoggedMB + progressIntervalMB) {
              Logger.info("Download progress", {
                url: maskUrl(videoUrl),
                downloadedMB: currentMB.toFixed(2),
                totalMB: contentLength ? (contentLength / (1024 * 1024)).toFixed(2) : "unknown",
                progress: contentLength ? `${((totalSize / contentLength) * 100).toFixed(1)}%` : "unknown"
              });
              lastLoggedMB = currentMB;
            }

            if (totalSize > MAX_SIZE) {
              fileStream.destroy();
              await fs.unlink(tempPath).catch(() => {});
              throw new Error(
                `FILE_TOO_LARGE: Файл слишком большой (${(totalSize / (1024 * 1024)).toFixed(2)} MB). Максимальный размер: ${MAX_SIZE / (1024 * 1024)} MB.`
              );
            }

            await new Promise<void>((resolve, reject) => {
              if (fileStream.write(value)) {
                resolve();
              } else {
                fileStream.once("drain", resolve);
                fileStream.once("error", reject);
              }
            });
          }
          
          // Закрываем поток записи
          fileStream.end();
          
          // Ждём завершения записи
          await new Promise<void>((resolve, reject) => {
            fileStream.once("finish", resolve);
            fileStream.once("error", reject);
          });
        } catch (error) {
          fileStream.destroy();
          await fs.unlink(tempPath).catch(() => {});
          throw error;
        }

        const stats = await fs.stat(tempPath);
        if (stats.size === 0) {
          await fs.unlink(tempPath).catch(() => {});
          throw new Error("Downloaded file is empty");
        }

        Logger.info("Video downloaded from URL successfully", {
          url: maskUrl(videoUrl),
          tempPath,
          fileSize: stats.size,
          fileSizeMB: (stats.size / (1024 * 1024)).toFixed(2),
          expectedSize: contentLength ? `${(contentLength / (1024 * 1024)).toFixed(2)} MB` : "unknown",
          attempt
        });

        return {
          tempPath,
          fileName: uniqueFileName,
          fileSize: stats.size
        };
      } catch (fetchError: any) {
        clearTimeout(timeoutId);
        throw fetchError;
      }
    } catch (error: any) {
      lastError = error instanceof Error ? error : new Error(String(error));
      
      // Если это последняя попытка или ошибка не связана с сетью, пробрасываем дальше
      if (attempt === maxRetries || 
          (!String(error?.message || error).includes("timeout") && 
           !String(error?.message || error).includes("network") &&
           !String(error?.message || error).includes("ECONNRESET"))) {
        Logger.error("Error downloading video from URL (final attempt)", {
          url: maskUrl(videoUrl),
          attempt,
          maxRetries,
          error: String(error?.message ?? error)
        });
        throw new Error(
          `VIDEO_URL_DOWNLOAD_ERROR: Не удалось скачать видео по URL после ${attempt} попыток: ${error?.message ?? String(error)}`
        );
      }
      
      Logger.warn("Error downloading video from URL (will retry)", {
        url: maskUrl(videoUrl),
        attempt,
        maxRetries,
        error: String(error?.message ?? error)
      });
    }
  }

  // Этот код не должен выполниться, но на всякий случай
  throw new Error(
    `VIDEO_URL_DOWNLOAD_ERROR: Не удалось скачать видео по URL после ${maxRetries} попыток: ${lastError?.message || "Unknown error"}`
  );
}

