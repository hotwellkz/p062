import "dotenv/config";
import { downloadFromUrl } from "../services/urlDownloader";
import { Logger } from "../utils/logger";

/**
 * Тестовый скрипт для проверки скачивания видео по URL
 * 
 * Использование:
 *   ts-node src/scripts/test_download_url.ts <URL>
 * 
 * Примеры:
 *   ts-node src/scripts/test_download_url.ts https://example.com/video.mp4
 *   ts-node src/scripts/test_download_url.ts https://example.com/page-with-video.html
 */
async function main() {
  const url = process.argv[2];

  if (!url) {
    console.error("Использование: ts-node src/scripts/test_download_url.ts <URL>");
    console.error("Пример: ts-node src/scripts/test_download_url.ts https://example.com/video.mp4");
    process.exit(1);
  }

  console.log("=== Тест скачивания видео по URL ===");
  console.log(`URL: ${url}`);
  console.log("");

  try {
    const startTime = Date.now();
    const result = await downloadFromUrl(url);
    const duration = Date.now() - startTime;

    console.log("");
    console.log("=== Результат ===");
    console.log(`Успех: ${result.success}`);
    
    if (result.success) {
      console.log(`Файл: ${result.filePath}`);
      console.log(`Размер: ${(result.bytes! / (1024 * 1024)).toFixed(2)} MB`);
      console.log(`Финальный URL: ${result.finalUrl || url}`);
      console.log(`Content-Type: ${result.contentType || "unknown"}`);
      console.log(`Время скачивания: ${(duration / 1000).toFixed(2)} сек`);
      console.log(`Скорость: ${((result.bytes! / (1024 * 1024)) / (duration / 1000)).toFixed(2)} MB/s`);
    } else {
      console.log(`Ошибка: ${result.error}`);
    }

    process.exit(result.success ? 0 : 1);
  } catch (error: any) {
    console.error("");
    console.error("=== Ошибка ===");
    console.error(error.message);
    if (error.stack) {
      console.error(error.stack);
    }
    process.exit(1);
  }
}

main().catch((error) => {
  console.error("Fatal error:", error);
  process.exit(1);
});



