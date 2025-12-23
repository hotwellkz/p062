import axios, { AxiosResponse, AxiosError } from "axios";
import * as fs from "fs/promises";
import * as path from "path";
import { Logger } from "../utils/logger";

/**
 * Результат скачивания видео по URL
 */
export interface UrlDownloadResult {
  success: boolean;
  filePath?: string;
  bytes?: number;
  finalUrl?: string;
  contentType?: string;
  error?: string;
}

/**
 * Конфигурация для скачивания
 */
interface DownloadConfig {
  timeoutMs: number;
  maxSizeMB: number;
  maxRedirects: number;
  userAgent?: string;
  tmpDir?: string;
}

/**
 * Получает конфигурацию из env переменных
 */
function getDownloadConfig(): DownloadConfig {
  return {
    timeoutMs: parseInt(process.env.DOWNLOAD_TIMEOUT_MS || "60000", 10),
    maxSizeMB: parseInt(process.env.DOWNLOAD_MAX_MB || "500", 10),
    maxRedirects: parseInt(process.env.DOWNLOAD_MAX_REDIRECTS || "10", 10),
    userAgent: process.env.DOWNLOAD_USER_AGENT || "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
    tmpDir: process.env.TMP_DIR || path.join(process.cwd(), "tmp")
  };
}

/**
 * Следует по редиректам и возвращает финальный URL
 * @param url - Начальный URL
 * @param maxRedirects - Максимальное количество редиректов
 * @returns Финальный URL после всех редиректов
 */
export async function resolveFinalUrl(
  url: string,
  maxRedirects: number = 10
): Promise<string> {
  let currentUrl = url;
  let redirectCount = 0;
  const config = getDownloadConfig();

  Logger.info("resolveFinalUrl: start", { url, maxRedirects });

  while (redirectCount < maxRedirects) {
    try {
      const response = await axios.head(currentUrl, {
        maxRedirects: 0,
        timeout: config.timeoutMs,
        validateStatus: (status) => status < 400,
        headers: {
          "User-Agent": config.userAgent
        }
      });

      // Если это редирект
      if (response.status >= 300 && response.status < 400) {
        const location = response.headers.location;
        if (!location) {
          Logger.warn("resolveFinalUrl: redirect without location header", {
            url: currentUrl,
            status: response.status
          });
          break;
        }

        // Обработка относительных URL
        const nextUrl = location.startsWith("http")
          ? location
          : new URL(location, currentUrl).toString();

        Logger.info("resolveFinalUrl: redirect", {
          from: currentUrl,
          to: nextUrl,
          status: response.status,
          redirectCount: redirectCount + 1
        });

        currentUrl = nextUrl;
        redirectCount++;
        continue;
      }

      // Если это финальный URL (не редирект)
      Logger.info("resolveFinalUrl: final URL resolved", {
        originalUrl: url,
        finalUrl: currentUrl,
        redirectCount,
        status: response.status
      });

      return currentUrl;
    } catch (error: any) {
      // Если HEAD не поддерживается, пробуем GET с maxRedirects
      if (error.response?.status === 405 || error.code === "ENOTFOUND") {
        try {
          const getResponse = await axios.get(currentUrl, {
            maxRedirects: config.maxRedirects,
            timeout: config.timeoutMs,
            validateStatus: () => true,
            headers: {
              "User-Agent": config.userAgent
            }
          });

          return getResponse.request.res.responseUrl || currentUrl;
        } catch (getError: any) {
          Logger.error("resolveFinalUrl: failed to resolve", {
            url: currentUrl,
            error: getError.message
          });
          throw new Error(`Failed to resolve URL: ${getError.message}`);
        }
      }

      Logger.error("resolveFinalUrl: error", {
        url: currentUrl,
        error: error.message
      });
      throw new Error(`Failed to resolve URL: ${error.message}`);
    }
  }

  if (redirectCount >= maxRedirects) {
    Logger.warn("resolveFinalUrl: max redirects reached", {
      url,
      finalUrl: currentUrl,
      redirectCount
    });
  }

  return currentUrl;
}

/**
 * Пытается скачать видео напрямую, если это прямой mp4 URL
 * @param url - URL для проверки
 * @returns Результат скачивания или null, если это не прямой mp4
 */
export async function tryDirectDownload(
  url: string
): Promise<UrlDownloadResult | null> {
  const config = getDownloadConfig();

  Logger.info("tryDirectDownload: checking", { url });

  try {
    // Сначала делаем HEAD запрос для проверки content-type
    let response: AxiosResponse;
    try {
      response = await axios.head(url, {
        timeout: config.timeoutMs,
        maxRedirects: config.maxRedirects,
        headers: {
          "User-Agent": config.userAgent
        },
        validateStatus: () => true
      });
    } catch (headError: any) {
      // Если HEAD не поддерживается, пробуем GET
      Logger.info("tryDirectDownload: HEAD not supported, trying GET", { url });
      response = await axios.get(url, {
        timeout: config.timeoutMs,
        maxRedirects: config.maxRedirects,
        headers: {
          "User-Agent": config.userAgent
        },
        validateStatus: () => true,
        responseType: "stream"
      });
    }

    const contentType = response.headers["content-type"] || "";
    const contentLength = parseInt(response.headers["content-length"] || "0", 10);
    const urlLower = url.toLowerCase();

    // Проверяем, является ли это видео
    const isVideo =
      contentType.startsWith("video/") ||
      urlLower.endsWith(".mp4") ||
      urlLower.endsWith(".mov") ||
      urlLower.endsWith(".avi") ||
      urlLower.endsWith(".mkv") ||
      urlLower.endsWith(".webm");

    if (!isVideo) {
      Logger.info("tryDirectDownload: not a video URL", {
        url,
        contentType
      });
      return null;
    }

    // Проверяем размер файла
    if (contentLength > 0) {
      const sizeMB = contentLength / (1024 * 1024);
      if (sizeMB > config.maxSizeMB) {
        throw new Error(
          `File too large: ${sizeMB.toFixed(2)} MB (max: ${config.maxSizeMB} MB)`
        );
      }
    }

    Logger.info("tryDirectDownload: direct video detected", {
      url,
      contentType,
      contentLength
    });

    // Скачиваем файл
    const downloadResponse = await axios.get(url, {
      timeout: config.timeoutMs,
      maxRedirects: config.maxRedirects,
      responseType: "arraybuffer",
      headers: {
        "User-Agent": config.userAgent
      },
      maxContentLength: config.maxSizeMB * 1024 * 1024,
      maxBodyLength: config.maxSizeMB * 1024 * 1024
    });

    const fileBuffer = Buffer.from(downloadResponse.data);
    const finalBytes = fileBuffer.length;

    // Проверяем размер
    const sizeMB = finalBytes / (1024 * 1024);
    if (sizeMB > config.maxSizeMB) {
      throw new Error(
        `File too large: ${sizeMB.toFixed(2)} MB (max: ${config.maxSizeMB} MB)`
      );
    }

    // Создаём временный файл
    await fs.mkdir(config.tmpDir!, { recursive: true });
    const fileName = `video_${Date.now()}_${Math.random().toString(36).substring(7)}.mp4`;
    const filePath = path.join(config.tmpDir!, fileName);

    // Сохраняем файл
    await fs.writeFile(filePath, fileBuffer);

    Logger.info("tryDirectDownload: download completed", {
      url,
      filePath,
      bytes: finalBytes,
      contentType: downloadResponse.headers["content-type"]
    });

    return {
      success: true,
      filePath,
      bytes: finalBytes,
      finalUrl: url,
      contentType: downloadResponse.headers["content-type"] || contentType
    };
  } catch (error: any) {
    Logger.error("tryDirectDownload: error", {
      url,
      error: error.message
    });
    return null;
  }
}

/**
 * Извлекает URL видео из HTML страницы
 * @param html - HTML содержимое
 * @param baseUrl - Базовый URL для разрешения относительных путей
 * @returns URL видео или null, если не найдено
 */
export function parseHtmlForVideoUrl(html: string, baseUrl: string): string | null {
  Logger.info("parseHtmlForVideoUrl: parsing HTML", { baseUrl, htmlLength: html.length });

  try {
    // 1. Ищем <video> теги с src или source
    const videoSrcMatch = html.match(/<video[^>]+src=["']([^"']+\.mp4[^"']*)["']/i);
    if (videoSrcMatch) {
      const videoUrl = resolveUrl(videoSrcMatch[1], baseUrl);
      Logger.info("parseHtmlForVideoUrl: found video src", { videoUrl });
      return videoUrl;
    }

    // 2. Ищем <source> внутри <video>
    const sourceMatch = html.match(/<source[^>]+src=["']([^"']+\.mp4[^"']*)["']/i);
    if (sourceMatch) {
      const videoUrl = resolveUrl(sourceMatch[1], baseUrl);
      Logger.info("parseHtmlForVideoUrl: found source src", { videoUrl });
      return videoUrl;
    }

    // 3. Ищем ссылки с .mp4
    const linkMatch = html.match(/<a[^>]+href=["']([^"']+\.mp4[^"']*)["']/i);
    if (linkMatch) {
      const videoUrl = resolveUrl(linkMatch[1], baseUrl);
      Logger.info("parseHtmlForVideoUrl: found link href", { videoUrl });
      return videoUrl;
    }

    // 4. Ищем в JSON (например, в script тегах)
    const jsonMatches = html.match(/<script[^>]*>([\s\S]*?)<\/script>/gi);
    if (jsonMatches) {
      for (const script of jsonMatches) {
        // Ищем URL в JSON структурах
        const jsonUrlMatch = script.match(/["']([^"']*\.mp4[^"']*)["']/gi);
        if (jsonUrlMatch) {
          for (const match of jsonUrlMatch) {
            const url = match.replace(/["']/g, "");
            if (url.includes(".mp4") && (url.startsWith("http") || url.startsWith("//"))) {
              const videoUrl = resolveUrl(url, baseUrl);
              Logger.info("parseHtmlForVideoUrl: found in JSON/script", { videoUrl });
              return videoUrl;
            }
          }
        }
      }
    }

    // 5. Ищем прямые упоминания .mp4 в тексте (последняя попытка)
    const directMp4Match = html.match(/(https?:\/\/[^\s"']+\.mp4[^\s"']*)/i);
    if (directMp4Match) {
      const videoUrl = directMp4Match[1];
      Logger.info("parseHtmlForVideoUrl: found direct mp4 URL", { videoUrl });
      return videoUrl;
    }

    Logger.warn("parseHtmlForVideoUrl: no video URL found", { baseUrl });
    return null;
  } catch (error: any) {
    Logger.error("parseHtmlForVideoUrl: error", {
      baseUrl,
      error: error.message
    });
    return null;
  }
}

/**
 * Разрешает относительный URL в абсолютный
 */
function resolveUrl(url: string, baseUrl: string): string {
  if (url.startsWith("http://") || url.startsWith("https://")) {
    return url;
  }
  if (url.startsWith("//")) {
    return new URL(baseUrl).protocol + url;
  }
  return new URL(url, baseUrl).toString();
}

/**
 * Fallback через Playwright (опционально, только если включен)
 * @param url - URL страницы
 * @returns URL видео или null
 */
export async function fallbackPlaywright(url: string): Promise<string | null> {
  const usePlaywright = process.env.PLAYWRIGHT_FALLBACK === "true";
  
  if (!usePlaywright) {
    Logger.info("fallbackPlaywright: disabled", { url });
    return null;
  }

  Logger.info("fallbackPlaywright: starting", { url });

  try {
    // Динамический импорт Playwright (чтобы не требовать его, если не используется)
    // eslint-disable-next-line @typescript-eslint/no-var-requires
    const playwright = require("playwright");
    const { chromium } = playwright;
    const browser = await chromium.launch({ headless: true });
    const page = await browser.newPage();

    // Отслеживаем network requests для поиска mp4
    let videoUrl: string | null = null;

    page.on("response", (response: any) => {
      const url = response.url();
      const contentType = response.headers()["content-type"] || "";
      
      if (
        (url.includes(".mp4") || contentType.startsWith("video/")) &&
        response.status() === 200
      ) {
        videoUrl = url;
        Logger.info("fallbackPlaywright: found video in network", { videoUrl });
      }
    });

    await page.goto(url, { waitUntil: "networkidle", timeout: 30000 });

    // Также проверяем DOM после загрузки
    if (!videoUrl) {
      const videoElement = await page.$("video");
      if (videoElement) {
        const src = await videoElement.getAttribute("src");
        if (src) {
          videoUrl = resolveUrl(src, url);
          Logger.info("fallbackPlaywright: found video in DOM", { videoUrl });
        }
      }
    }

    await browser.close();

    if (videoUrl) {
      Logger.info("fallbackPlaywright: success", { url, videoUrl });
      return videoUrl;
    }

    Logger.warn("fallbackPlaywright: no video found", { url });
    return null;
  } catch (error: any) {
    Logger.error("fallbackPlaywright: error", {
      url,
      error: error.message
    });
    return null;
  }
}

/**
 * Главная функция для скачивания видео по URL
 * @param inputUrl - URL для скачивания
 * @returns Результат скачивания
 */
export async function downloadFromUrl(inputUrl: string): Promise<UrlDownloadResult> {
  const config = getDownloadConfig();
  const maxRetries = 3;

  Logger.info("downloadFromUrl: start", { inputUrl, config });

  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      Logger.info("downloadFromUrl: attempt", { inputUrl, attempt, maxRetries });

      // Шаг 1: Разрешаем финальный URL (следуем редиректам)
      const finalUrl = await resolveFinalUrl(inputUrl, config.maxRedirects);
      Logger.info("downloadFromUrl: final URL resolved", { inputUrl, finalUrl });

      // Шаг 2: Пробуем прямое скачивание
      const directResult = await tryDirectDownload(finalUrl);
      if (directResult?.success) {
        Logger.info("downloadFromUrl: direct download success", {
          inputUrl,
          finalUrl,
          filePath: directResult.filePath,
          bytes: directResult.bytes
        });
        return directResult;
      }

      // Шаг 3: Если не прямой mp4, получаем HTML и парсим
      Logger.info("downloadFromUrl: trying HTML parse", { finalUrl });
      const htmlResponse = await axios.get(finalUrl, {
        timeout: config.timeoutMs,
        maxRedirects: config.maxRedirects,
        headers: {
          "User-Agent": config.userAgent
        }
      });

      const html = htmlResponse.data;
      if (typeof html !== "string") {
        throw new Error("Response is not HTML text");
      }

      const videoUrl = parseHtmlForVideoUrl(html, finalUrl);
      if (videoUrl) {
        Logger.info("downloadFromUrl: video URL found in HTML", { finalUrl, videoUrl });
        // Пробуем скачать найденный URL
        const videoResult = await tryDirectDownload(videoUrl);
        if (videoResult?.success) {
          return videoResult;
        }
      }

      // Шаг 4: Fallback на Playwright (если включен)
      if (process.env.PLAYWRIGHT_FALLBACK === "true") {
        Logger.info("downloadFromUrl: trying Playwright fallback", { finalUrl });
        const playwrightUrl = await fallbackPlaywright(finalUrl);
        if (playwrightUrl) {
          const playwrightResult = await tryDirectDownload(playwrightUrl);
          if (playwrightResult?.success) {
            return playwrightResult;
          }
        }
      }

      // Если ничего не сработало
      throw new Error("No video URL found in page");
    } catch (error: any) {
      Logger.error("downloadFromUrl: attempt failed", {
        inputUrl,
        attempt,
        maxRetries,
        error: error.message
      });

      if (attempt === maxRetries) {
        return {
          success: false,
          error: `Failed after ${maxRetries} attempts: ${error.message}`
        };
      }

      // Ждём перед повтором
      await new Promise((resolve) => setTimeout(resolve, 1000 * attempt));
    }
  }

  return {
    success: false,
    error: "Max retries exceeded"
  };
}

