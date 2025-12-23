import type { Request, Response, NextFunction } from "express";
import * as admin from "firebase-admin";
import * as jwt from "jsonwebtoken";
import { Logger } from "../utils/logger";

export interface AuthUser {
  uid: string;
  email?: string;
  role?: string; // Для локального JWT
}

declare global {
  namespace Express {
    // eslint-disable-next-line @typescript-eslint/consistent-type-definitions
    interface Request {
      user?: AuthUser;
    }
  }
}

/**
 * Определяет тип токена: Firebase ID Token или локальный JWT
 * Firebase ID Token имеет:
 * - header.kid (key ID) в JWT header
 * - payload.iss включает "securetoken.google.com" или "https://securetoken.google.com"
 */
/**
 * Декодирует base64url в base64 для Buffer.from
 * base64url использует - и _ вместо + и /
 */
function base64UrlDecode(str: string): string {
  // Заменяем base64url символы на base64
  let base64 = str.replace(/-/g, "+").replace(/_/g, "/");
  // Добавляем padding если нужно
  while (base64.length % 4) {
    base64 += "=";
  }
  return base64;
}

function isFirebaseToken(token: string): boolean {
  try {
    // Декодируем JWT без проверки подписи (только для анализа структуры)
    const parts = token.split(".");
    if (parts.length !== 3) {
      return false;
    }

    const header = JSON.parse(Buffer.from(base64UrlDecode(parts[0]), "base64").toString("utf-8"));
    const payload = JSON.parse(Buffer.from(base64UrlDecode(parts[1]), "base64").toString("utf-8"));

    // Проверяем наличие kid в header (характерно для Firebase)
    if (header.kid) {
      Logger.info("authRequired: detected Firebase token by 'kid' in header", {
        hasKid: true,
        tokenPrefix: token.substring(0, 20) + "..."
      });
      return true;
    }

    // Проверяем issuer в payload (Firebase токены имеют специфичный issuer)
    if (payload.iss && (
      payload.iss.includes("securetoken.google.com") ||
      payload.iss.includes("https://securetoken.google.com")
    )) {
      Logger.info("authRequired: detected Firebase token by issuer", {
        iss: payload.iss,
        tokenPrefix: token.substring(0, 20) + "..."
      });
      return true;
    }

    return false;
  } catch (error) {
    // Если не удалось декодировать - считаем локальным JWT
    Logger.info("authRequired: failed to decode token for type detection, assuming local JWT", {
      error: error instanceof Error ? error.message : String(error)
    });
    return false;
  }
}

/**
 * Middleware для проверки авторизации (dual-auth):
 * - Firebase ID Token через Firebase Admin SDK (основной метод)
 * - Локальный JWT через jsonwebtoken (fallback для dev/admin)
 * 
 * Требует заголовок: Authorization: Bearer <token>
 * 
 * При успешной проверке:
 * - В req.user сохраняется информация о пользователе (uid, email, role)
 * - Запрос проходит дальше
 * 
 * При ошибке:
 * - Возвращает 401 с JSON { error: "Unauthorized" | "Invalid token" | ... }
 * - Логирует причину ошибки в консоль
 */
export async function authRequired(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  const authHeader = req.headers.authorization;

  // Проверяем наличие заголовка Authorization
  if (!authHeader?.startsWith("Bearer ")) {
    Logger.warn("authRequired: missing or invalid Authorization header", {
      hasHeader: !!authHeader,
      headerValue: authHeader ? `${authHeader.substring(0, 20)}...` : "none",
      method: req.method,
      path: req.path
    });
    res.status(401).json({ 
      error: "Unauthorized", 
      message: "Missing or invalid Authorization header" 
    });
    return;
  }

  const token = authHeader.slice("Bearer ".length);

  // Определяем тип токена
  const isFirebase = isFirebaseToken(token);

  if (isFirebase) {
    // ========== FIREBASE ID TOKEN ==========
    Logger.info("authRequired: using Firebase authentication", {
      method: req.method,
      path: req.path,
      tokenPrefix: token.substring(0, 20) + "..."
    });

    // Проверяем, что Firebase Admin инициализирован
    if (!admin.apps.length) {
      Logger.error("authRequired: Firebase Admin not initialized");
      res.status(500).json({ 
        error: "Internal server error", 
        message: "Authentication service unavailable" 
      });
      return;
    }

    try {
      // Верифицируем токен через Firebase Admin SDK
      const decodedToken = await admin.auth().verifyIdToken(token);

      // Сохраняем информацию о пользователе в req.user
      req.user = {
        uid: decodedToken.uid,
        email: decodedToken.email
      };

      Logger.info("authRequired: Firebase token verified successfully", {
        uid: decodedToken.uid,
        email: decodedToken.email || "not provided",
        method: req.method,
        path: req.path,
        authMethod: "firebase"
      });

      next();
      return;
    } catch (error) {
      // Обрабатываем различные типы ошибок Firebase Auth
      let errorMessage = "Invalid token";
      let logMessage = "authRequired: Firebase token verification failed";
      let errorCode = "INVALID_TOKEN";

      if (error instanceof Error) {
        if (error.message.includes("expired")) {
          errorMessage = "Token expired";
          logMessage = "authRequired: Firebase token expired";
          errorCode = "TOKEN_EXPIRED";
        } else if (error.message.includes("revoked")) {
          errorMessage = "Token revoked";
          logMessage = "authRequired: Firebase token revoked";
          errorCode = "TOKEN_REVOKED";
        } else if (error.message.includes("invalid")) {
          errorMessage = "Invalid token";
          logMessage = "authRequired: invalid Firebase token format";
          errorCode = "INVALID_TOKEN_FORMAT";
        } else {
          errorMessage = error.message;
        }
      }

      Logger.warn(logMessage, {
        error: errorMessage,
        errorCode,
        method: req.method,
        path: req.path,
        authMethod: "firebase",
        tokenPrefix: token.substring(0, 20) + "..."
      });

      res.status(401).json({ 
        error: "Unauthorized", 
        errorCode,
        message: errorMessage 
      });
      return;
    }
  } else {
    // ========== ЛОКАЛЬНЫЙ JWT ==========
    Logger.info("authRequired: using local JWT authentication", {
      method: req.method,
      path: req.path,
      tokenPrefix: token.substring(0, 20) + "..."
    });

    const jwtSecret = process.env.JWT_SECRET;
    if (!jwtSecret) {
      Logger.error("authRequired: JWT_SECRET not configured for local JWT authentication");
      res.status(500).json({ 
        error: "Internal server error", 
        message: "JWT authentication not configured" 
      });
      return;
    }

    try {
      // Верифицируем локальный JWT
      const decoded = jwt.verify(token, jwtSecret) as jwt.JwtPayload;

      // Проверяем, что токен содержит role: 'admin' для доступа к /api/telegram/*
      if (req.path.startsWith("/api/telegram") && decoded.role !== "admin") {
        Logger.warn("authRequired: local JWT token missing 'admin' role for /api/telegram endpoint", {
          role: decoded.role || "not provided",
          method: req.method,
          path: req.path,
          authMethod: "jwt"
        });
        res.status(403).json({ 
          error: "Forbidden", 
          errorCode: "INSUFFICIENT_PERMISSIONS",
          message: "Admin role required for this endpoint" 
        });
        return;
      }

      // Сохраняем информацию о пользователе в req.user
      // Для локального JWT используем role как uid (или генерируем фиктивный uid)
      req.user = {
        uid: decoded.uid || decoded.sub || `jwt-${decoded.role || "user"}`,
        email: decoded.email,
        role: decoded.role
      };

      Logger.info("authRequired: local JWT token verified successfully", {
        uid: req.user.uid,
        role: decoded.role || "not provided",
        email: decoded.email || "not provided",
        method: req.method,
        path: req.path,
        authMethod: "jwt"
      });

      next();
      return;
    } catch (error) {
      let errorMessage = "Invalid JWT token";
      let logMessage = "authRequired: local JWT token verification failed";
      let errorCode = "INVALID_JWT_TOKEN";

      if (error instanceof Error) {
        if (error.message.includes("expired")) {
          errorMessage = "JWT token expired";
          logMessage = "authRequired: local JWT token expired";
          errorCode = "JWT_TOKEN_EXPIRED";
        } else if (error.message.includes("invalid signature")) {
          errorMessage = "Invalid JWT signature";
          logMessage = "authRequired: invalid JWT signature";
          errorCode = "INVALID_JWT_SIGNATURE";
        } else {
          errorMessage = error.message;
        }
      }

      Logger.warn(logMessage, {
        error: errorMessage,
        errorCode,
        method: req.method,
        path: req.path,
        authMethod: "jwt",
        tokenPrefix: token.substring(0, 20) + "..."
      });

      res.status(401).json({ 
        error: "Unauthorized", 
        errorCode,
        message: errorMessage 
      });
      return;
    }
  }
}


