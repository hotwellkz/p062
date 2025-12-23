/**
 * Утилиты для работы с именами файлов
 */

import * as path from "path";
import * as fs from "fs/promises";

/**
 * Очищает название файла от недопустимых символов
 * @param title - Название ролика/файла
 * @returns Очищенное имя файла
 */
export function sanitizeFileName(title: string): string {
  if (!title || typeof title !== "string") {
    return "video";
  }

  return title
    .trim()
    // Удаляем недопустимые символы для файловых систем
    .replace(/[\\/:*?"<>|]/g, "_")
    // Заменяем пробелы и множественные подчёркивания на одно
    .replace(/\s+/g, "_")
    .replace(/_+/g, "_")
    // Удаляем подчёркивания в начале и конце
    .replace(/^_+|_+$/g, "")
    // Ограничиваем длину (120 символов для безопасности)
    .slice(0, 120)
    // Если после очистки строка пустая, используем дефолтное имя
    || "video";
}

/**
 * Формирует полное имя файла с расширением
 * @param title - Название ролика/файла
 * @param extension - Расширение файла (по умолчанию .mp4)
 * @returns Имя файла с расширением
 */
/**
 * Генерирует стабильный videoId (timestamp + short hash)
 * Формат: {timestamp}_{hash}
 */
export function generateVideoId(): string {
  const timestamp = Date.now();
  const random = Math.random().toString(36).substring(2, 10);
  return `${timestamp}_${random}`;
}

/**
 * Нормализует email в безопасное имя папки
 * Правила:
 * - trim, lower-case
 * - '@' -> '-at-'
 * - '.' -> '-'
 * - все прочие символы НЕ [a-z0-9-_] -> '-'
 * - сжать повторяющиеся '-' в один
 * - обрезать до 80 символов
 * 
 * @param email - Email адрес
 * @returns Нормализованный slug для использования в путях
 * 
 * @example
 * emailToSlug('HotWell.kz@gmail.com') -> 'hotwell-kz-at-gmail-com'
 * emailToSlug('user+tag@example.com') -> 'user-tag-at-example-com'
 */
export function emailToSlug(email: string): string {
  if (!email || typeof email !== "string") {
    return "unknown-email";
  }

  let slug = email
    .trim()
    .toLowerCase()
    .replace(/@/g, "-at-")      // @ -> -at-
    .replace(/\./g, "-")        // . -> -
    .replace(/[^a-z0-9-_]/g, "-") // все остальные не-ASCII -> -
    .replace(/-+/g, "-")        // множественные - -> один
    .replace(/^-+|-+$/g, "");   // убрать - в начале и конце

  // Обрезать до 80 символов
  if (slug.length > 80) {
    slug = slug.slice(0, 80);
    // Убрать возможный - в конце после обрезки
    slug = slug.replace(/-+$/, "");
  }

  // Если после всех преобразований строка пустая
  if (slug.length === 0) {
    return "unknown-email";
  }

  return slug;
}

/**
 * Нормализует название канала в безопасное имя папки
 * Правила:
 * - trim, lower-case
 * - пробелы -> '-'
 * - оставить только [a-z0-9-_]
 * - все остальные символы -> '-'
 * - сжать повторяющиеся '-' в один
 * - обрезать до 60-80 символов
 * 
 * @param name - Название канала
 * @returns Нормализованный slug для использования в путях
 * 
 * @example
 * channelNameToSlug('PostroimDom.kz') -> 'postroimdom-kz'
 * channelNameToSlug('Surprise Unbox Planet') -> 'surprise-unbox-planet'
 * channelNameToSlug('') -> 'channel'
 */
export function channelNameToSlug(name: string | null | undefined): string {
  if (!name || typeof name !== "string" || name.trim().length === 0) {
    return "channel";
  }

  let slug = name
    .trim()
    .toLowerCase()
    .replace(/\s+/g, "-")        // пробелы -> -
    .replace(/[^a-z0-9-_]/g, "-") // все не-ASCII -> -
    .replace(/-+/g, "-")          // множественные - -> один
    .replace(/^-+|-+$/g, "");     // убрать - в начале и конце

  // Обрезать до 60 символов
  if (slug.length > 60) {
    slug = slug.slice(0, 60);
    // Убрать возможный - в конце после обрезки
    slug = slug.replace(/-+$/, "");
  }

  // Если после всех преобразований строка пустая
  if (slug.length === 0) {
    return "channel";
  }

  return slug;
}

/**
 * Простая транслитерация кириллицы в латиницу
 * Без RegExp и объектных литералов, чтобы не ломаться на старых версиях TS
 */
function translitRuToLat(text: string): string {
  let result = "";

  for (const ch of text) {
    switch (ch) {
      // нижний регистр
      case "а": result += "a"; break;
      case "б": result += "b"; break;
      case "в": result += "v"; break;
      case "г": result += "g"; break;
      case "д": result += "d"; break;
      case "е": result += "e"; break;
      case "ё": result += "yo"; break;
      case "ж": result += "zh"; break;
      case "з": result += "z"; break;
      case "и": result += "i"; break;
      case "й": result += "y"; break;
      case "к": result += "k"; break;
      case "л": result += "l"; break;
      case "м": result += "m"; break;
      case "н": result += "n"; break;
      case "о": result += "o"; break;
      case "п": result += "p"; break;
      case "р": result += "r"; break;
      case "с": result += "s"; break;
      case "т": result += "t"; break;
      case "у": result += "u"; break;
      case "ф": result += "f"; break;
      case "х": result += "h"; break;
      case "ц": result += "ts"; break;
      case "ч": result += "ch"; break;
      case "ш": result += "sh"; break;
      case "щ": result += "sch"; break;
      case "ъ": break; // пропускаем
      case "ы": result += "y"; break;
      case "ь": break; // пропускаем
      case "э": result += "e"; break;
      case "ю": result += "yu"; break;
      case "я": result += "ya"; break;

      // верхний регистр
      case "А": result += "A"; break;
      case "Б": result += "B"; break;
      case "В": result += "V"; break;
      case "Г": result += "G"; break;
      case "Д": result += "D"; break;
      case "Е": result += "E"; break;
      case "Ё": result += "Yo"; break;
      case "Ж": result += "Zh"; break;
      case "З": result += "Z"; break;
      case "И": result += "I"; break;
      case "Й": result += "Y"; break;
      case "К": result += "K"; break;
      case "Л": result += "L"; break;
      case "М": result += "M"; break;
      case "Н": result += "N"; break;
      case "О": result += "O"; break;
      case "П": result += "P"; break;
      case "Р": result += "R"; break;
      case "С": result += "S"; break;
      case "Т": result += "T"; break;
      case "У": result += "U"; break;
      case "Ф": result += "F"; break;
      case "Х": result += "H"; break;
      case "Ц": result += "Ts"; break;
      case "Ч": result += "Ch"; break;
      case "Ш": result += "Sh"; break;
      case "Щ": result += "Sch"; break;
      case "Ъ": break; // пропускаем
      case "Ы": result += "Y"; break;
      case "Ь": break; // пропускаем
      case "Э": result += "E"; break;
      case "Ю": result += "Yu"; break;
      case "Я": result += "Ya"; break;

      default:
        result += ch;
    }
  }

  return result;
}

/**
 * Создаёт безопасное базовое имя файла из названия ролика
 * Правила:
 * - trim
 * - транслитерация кириллицы
 * - пробелы -> '_'
 * - удаление запрещённых символов: <>:"/\|?* и управляющие
 * - разрешены: латиница, цифры, '-', '_', '.'
 * - убрать повторяющиеся '_' и '-'
 * - ограничить длину до 80 символов
 * - если пусто -> "video"
 * 
 * @param title - Название ролика
 * @returns Безопасное базовое имя файла (без расширения)
 * 
 * @example
 * makeSafeBaseName("SipPani Stroitelstvo s yumorom") -> "SipPani_Stroitelstvo_s_yumorom"
 * makeSafeBaseName("ПостройДом юмор") -> "PostroiDom_yumor"
 * makeSafeBaseName("Test<>File") -> "Test_File"
 */
export function makeSafeBaseName(title: string | null | undefined): string {
  if (!title || typeof title !== "string" || title.trim().length === 0) {
    return "video";
  }

  let safe = title.trim();

  // Транслитерация кириллицы
  safe = translitRuToLat(safe);

  // Заменяем пробелы на '_'
  safe = safe.replace(/\s+/g, "_");

  // Удаляем запрещённые символы: <>:"/\|?* и управляющие символы
  safe = safe.replace(/[<>:"/\\|?*\x00-\x1F\x7F]/g, "");

  // Оставляем только латиницу, цифры, '-', '_', '.'
  safe = safe.replace(/[^a-zA-Z0-9._-]/g, "");

  // Заменяем точку на '-' (лучше для файловых систем)
  safe = safe.replace(/\./g, "-");

  // Убираем повторяющиеся '_' и '-'
  safe = safe.replace(/[-_]+/g, (match) => match[0] === '-' ? '-' : '_');
  safe = safe.replace(/_+/g, "_");
  safe = safe.replace(/-+/g, "-");

  // Убираем '_' и '-' в начале и конце
  safe = safe.replace(/^[-_]+|[-_]+$/g, "");

  // Обрезаем до 80 символов
  if (safe.length > 80) {
    safe = safe.slice(0, 80);
    // Убираем возможные '_' и '-' в конце после обрезки
    safe = safe.replace(/[-_]+$/, "");
  }

  // Если после всех преобразований строка пустая
  if (safe.length === 0) {
    return "video";
  }

  return safe;
}

/**
 * Генерирует уникальное имя файла на основе title
 * Проверяет существование файла и добавляет суффикс при необходимости
 * 
 * @param title - Название ролика
 * @param targetDir - Директория, где будет сохранён файл
 * @param shortId - Короткий ID для уникальности (опционально)
 * @returns Уникальное базовое имя файла (без расширения)
 */
export async function generateUniqueVideoFileName(
  title: string | null | undefined,
  targetDir: string,
  shortId?: string
): Promise<string> {
  const base = makeSafeBaseName(title);
  
  // Если title отсутствует, используем fallback на timestamp + shortId
  if (!title || base === "video") {
    const timestamp = Date.now();
    const random = Math.random().toString(36).substring(2, 8);
    return shortId ? `${timestamp}_${shortId.slice(0, 6)}` : `${timestamp}_${random}`;
  }

  // Проверяем существование файла
  let candidate = base;
  let counter = 2;

  while (true) {
    const mp4Path = path.join(targetDir, `${candidate}.mp4`);
    try {
      await fs.access(mp4Path);
      // Файл существует, пробуем следующий вариант
      candidate = `${base}__${counter}`;
      counter++;
    } catch {
      // Файл не существует, можно использовать это имя
      break;
    }

    // Защита от бесконечного цикла
    if (counter > 1000) {
      // Если слишком много конфликтов, добавляем короткий ID
      const fallbackId = shortId ? shortId.slice(0, 6) : Math.random().toString(36).substring(2, 8);
      candidate = `${base}__${fallbackId}`;
      break;
    }
  }

  return candidate;
}

export function formatFileName(title: string, extension: string = ".mp4"): string {
  const sanitized = sanitizeFileName(title);
  
  // Убираем расширение, если оно уже есть
  const withoutExt = sanitized.replace(/\.(mp4|avi|mov|mkv|webm)$/i, "");
  
  // Добавляем расширение
  return `${withoutExt}${extension}`;
}

/**
 * Генерирует осмысленное имя файла для видео на основе сгенерированного названия ролика
 * @param params - Параметры для генерации имени
 * @returns Нормализованное имя файла с расширением .mp4
 */
export function generateVideoFileName(params: {
  title?: string;      // сгенерированное название ролика
  prompt?: string;     // текст промпта (на случай, если title нет)
  channelName?: string;
  createdAt?: Date;
}): string {
  const { title, prompt, channelName, createdAt } = params;
  
  let name: string;
  
  // Приоритет: title > первые 60-80 символов промпта > название канала > fallback
  if (title && title.trim().length > 0) {
    name = title.trim();
  } else if (prompt && prompt.trim().length > 0) {
    // Берём первые 60-80 символов промпта
    name = prompt.trim().slice(0, 80);
  } else if (channelName && channelName.trim().length > 0) {
    name = channelName.trim();
  } else {
    // Fallback: используем дату и время
    const date = createdAt || new Date();
    const dateStr = date.toISOString().slice(0, 19).replace(/[:-]/g, "").replace("T", "_");
    return `video_${dateStr}.mp4`;
  }
  
  // Нормализация строки
  name = name.trim();
  
  // Удаление/замена запрещённых символов
  name = name
    .replace(/[\/\\\?\%\*\:"<>\|]/g, "")  // убрать опасные символы
    .replace(/!/g, "")                     // убрать восклицательные
    .replace(/:/g, "")                      // убрать двоеточия
    .replace(/\s+/g, " ");                  // схлопнуть повторные пробелы
  
  // Убираем пробелы в начале и конце
  name = name.trim();
  
  // Обрезка длины (80-100 символов)
  const MAX_LEN = 100;
  if (name.length > MAX_LEN) {
    name = name.slice(0, MAX_LEN).trim();
  }
  
  // Если после всех преобразований строка пустая, используем fallback
  if (name.length === 0) {
    const date = createdAt || new Date();
    const dateStr = date.toISOString().slice(0, 19).replace(/[:-]/g, "").replace("T", "_");
    return `video_${dateStr}.mp4`;
  }
  
  // Убираем расширение, если оно уже есть
  const withoutExt = name.replace(/\.(mp4|avi|mov|mkv|webm)$/i, "");
  
  // Добавляем расширение .mp4
  return `${withoutExt}.mp4`;
}





