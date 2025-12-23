import { Router } from "express";
import { authRequired } from "../middleware/auth";
import { db, isFirestoreAvailable } from "../services/firebaseAdmin";
import { Logger } from "../utils/logger";
import {
  extractVideoUrlFromGetVideoPage,
  downloadGetVideoPage
} from "../utils/getvideoParser";
import * as fs from "fs/promises";
import { getStorageService } from "../services/storageService";
import * as path from "path";

const router = Router();

// Диагностические эндпоинты доступны только если DEBUG_DIAG=true
const isDiagEnabled = process.env.DEBUG_DIAG === "true";

if (!isDiagEnabled) {
  // Если диагностика отключена, возвращаем 404 для всех запросов
  router.use((req, res) => {
    res.status(404).json({
      error: "Not Found",
      message: "Diagnostic endpoints are disabled. Set DEBUG_DIAG=true to enable."
    });
  });
} else {
  /**
   * GET /api/diag/buildinfo
   * Возвращает информацию о сборке (без auth, только если DEBUG_DIAG=true)
   */
  router.get("/buildinfo", (req, res) => {
    try {
      const os = require("os");
      const buildId = process.env.BUILD_ID || process.env.BUILD_DATE || `manual-${Date.now()}`;
      const gitSha = process.env.GIT_SHA || process.env.GIT_COMMIT || "unknown";
      const image = process.env.DOCKER_IMAGE || "unknown";
      const hostname = process.env.HOSTNAME || os.hostname() || "unknown";
      const version = process.env.APP_VERSION || process.env.npm_package_version || "unknown";
      const startedAt = process.env.STARTED_AT || new Date().toISOString();

      res.charset = "utf-8";
      res.setHeader("Content-Type", "application/json; charset=utf-8");
      
      return res.json({
        buildId,
        gitSha,
        image,
        hostname,
        version,
        startedAt,
        nodeVersion: process.version,
        platform: process.platform,
        arch: process.arch,
        timestamp: new Date().toISOString()
      });
    } catch (error: any) {
      Logger.error("DIAG /api/diag/buildinfo: error", error);
      return res.status(500).json({
        error: "Failed to get build info",
        message: String(error?.message || error)
      });
    }
  });

  /**
   * GET /api/diag/whoami
   * Возвращает uid из токена (для проверки авторизации)
   */
  router.get("/whoami", authRequired, async (req, res) => {
    try {
      const userId = req.user?.uid || "unknown";
      Logger.info("DIAG /api/diag/whoami", { userId });
      
      return res.json({
        success: true,
        userId,
        hasUser: !!req.user,
        userEmail: req.user?.email || "not available"
      });
    } catch (error: any) {
      Logger.error("DIAG /api/diag/whoami: error", error);
      return res.status(500).json({
        error: "Failed to get user info",
        message: error?.message || String(error)
      });
    }
  });

  /**
   * GET /api/diag/channels
   * Возвращает список channelId из users/{uid}/channels (лимит 20)
   */
  router.get("/channels", authRequired, async (req, res) => {
    try {
      if (!isFirestoreAvailable() || !db) {
        return res.status(503).json({
          error: "FIRESTORE_NOT_AVAILABLE",
          message: "Firestore is not available"
        });
      }

      const userId = req.user?.uid;
      if (!userId) {
        return res.status(401).json({
          error: "UNAUTHORIZED",
          message: "User ID not found in token"
        });
      }

      Logger.info("DIAG /api/diag/channels: fetching channels", { userId });

      const channelsRef = db
        .collection("users")
        .doc(userId)
        .collection("channels")
        .limit(20);

      const channelsSnapshot = await channelsRef.get();

      const channelIds = channelsSnapshot.docs.map(doc => ({
        id: doc.id,
        exists: true,
        name: doc.data()?.name || "unnamed"
      }));

      Logger.info("DIAG /api/diag/channels: found channels", {
        userId,
        count: channelIds.length,
        channelIds: channelIds.map(c => c.id)
      });

      return res.json({
        success: true,
        userId,
        firestorePath: `users/${userId}/channels`,
        count: channelIds.length,
        channels: channelIds
      });
    } catch (error: any) {
      Logger.error("DIAG /api/diag/channels: error", error);
      return res.status(500).json({
        error: "Failed to fetch channels",
        message: error?.message || String(error)
      });
    }
  });

  /**
   * GET /api/diag/channel/:id
   * Проверяет существование канала по ID и возвращает путь + exists
   */
  router.get("/channel/:id", authRequired, async (req, res) => {
    try {
      if (!isFirestoreAvailable() || !db) {
        return res.status(503).json({
          error: "FIRESTORE_NOT_AVAILABLE",
          message: "Firestore is not available"
        });
      }

      const userId = req.user?.uid;
      const channelId = req.params.id;

      if (!userId) {
        return res.status(401).json({
          error: "UNAUTHORIZED",
          message: "User ID not found in token"
        });
      }

      if (!channelId) {
        return res.status(400).json({
          error: "BAD_REQUEST",
          message: "Channel ID is required"
        });
      }

      const firestorePath = `users/${userId}/channels/${channelId}`;
      
      Logger.info("DIAG /api/diag/channel/:id: checking channel", {
        userId,
        channelId,
        firestorePath
      });

      const channelRef = db
        .collection("users")
        .doc(userId)
        .collection("channels")
        .doc(channelId);

      const channelSnap = await channelRef.get();

      const result = {
        success: true,
        userId,
        channelId,
        firestorePath,
        exists: channelSnap.exists,
        data: channelSnap.exists ? {
          name: channelSnap.data()?.name || "unnamed",
          hasGoogleDriveFolderId: !!channelSnap.data()?.googleDriveFolderId
        } : null
      };

      Logger.info("DIAG /api/diag/channel/:id: result", result);

      return res.json(result);
    } catch (error: any) {
      Logger.error("DIAG /api/diag/channel/:id: error", error);
      return res.status(500).json({
        error: "Failed to check channel",
        message: error?.message || String(error)
      });
    }
  });

  /**
   * POST /api/diag/download
   * Скачивает видео по URL и возвращает информацию о файле (для тестирования)
   */
  router.post("/download", authRequired, async (req, res) => {
    try {
      const { url } = req.body;
      
      if (!url || typeof url !== "string") {
        return res.status(400).json({
          error: "BAD_REQUEST",
          message: "URL parameter is required in request body"
        });
      }

      Logger.info("DIAG /api/diag/download: starting download", {
        url: url.replace(/[?&](token|key|auth|signature|sig)=[^&]*/gi, "***")
      });

      const { downloadVideoFromUrl } = await import("../utils/getvideoParser");
      
      const result = await downloadVideoFromUrl(url, undefined, {
        maxRetries: 2,
        progressIntervalMB: 5
      });

      const stats = await fs.stat(result.tempPath);

      Logger.info("DIAG /api/diag/download: download successful", {
        url: url.replace(/[?&](token|key|auth|signature|sig)=[^&]*/gi, "***"),
        fileSize: stats.size,
        fileSizeMB: (stats.size / (1024 * 1024)).toFixed(2),
        tempPath: result.tempPath
      });

      res.charset = "utf-8";
      res.setHeader("Content-Type", "application/json; charset=utf-8");
      
      return res.json({
        ok: true,
        path: result.tempPath,
        bytes: stats.size,
        fileSizeMB: (stats.size / (1024 * 1024)).toFixed(2),
        fileName: result.fileName
      });
    } catch (error: any) {
      Logger.error("DIAG /api/diag/download: error", error);
      
      const errorMessage = Buffer.isBuffer(error?.message) 
        ? error.message.toString("utf-8")
        : String(error?.message || error);
      
      res.charset = "utf-8";
      res.setHeader("Content-Type", "application/json; charset=utf-8");
      
      return res.status(500).json({
        ok: false,
        error: "DOWNLOAD_FAILED",
        message: errorMessage
      });
    }
  });

  /**
   * GET /api/diag/parse-getvideo?url=...
   * Парсит страницу getvideo.syntxai.net и возвращает найденные ссылки на видео
   */
  router.get("/parse-getvideo", authRequired, async (req, res) => {
    try {
      const url = req.query.url as string;

      if (!url) {
        return res.status(400).json({
          error: "BAD_REQUEST",
          message: "URL parameter is required"
        });
      }

      // Проверяем, что это URL getvideo
      if (!url.includes("getvideo") && !url.includes("syntxai")) {
        return res.status(400).json({
          error: "BAD_REQUEST",
          message: "URL must be a getvideo.syntxai.net link"
        });
      }

      Logger.info("DIAG /api/diag/parse-getvideo: parsing URL", {
        url: url.replace(/[?&](token|key|auth|signature|sig)=[^&]*/gi, "***")
      });

      // Скачиваем HTML страницу
      const html = await downloadGetVideoPage(url);

      // Извлекаем URL видео
      const videoInfo = await extractVideoUrlFromGetVideoPage(html, url);

      if (!videoInfo) {
        return res.json({
          success: false,
          url: url.replace(/[?&](token|key|auth|signature|sig)=[^&]*/gi, "***"),
          message: "No video URL found in getvideo page",
          htmlLength: html.length,
          foundElements: {
            hasVideoTag: html.includes("<video"),
            hasSourceTag: html.includes("<source"),
            hasMp4Links: /\.mp4/i.test(html),
            hasWebmLinks: /\.webm/i.test(html),
            hasM3u8Links: /\.m3u8/i.test(html)
          }
        });
      }

      return res.json({
        success: true,
        url: url.replace(/[?&](token|key|auth|signature|sig)=[^&]*/gi, "***"),
        videoUrl: videoInfo.videoUrl.replace(/[?&](token|key|auth|signature|sig)=[^&]*/gi, "***"),
        videoType: videoInfo.type,
        htmlLength: html.length
      });
    } catch (error: any) {
      Logger.error("DIAG /api/diag/parse-getvideo: error", error);
      return res.status(500).json({
        error: "Failed to parse getvideo URL",
        message: error?.message || String(error)
      });
    }
  });

  /**
   * GET /api/diag/storage
   * Диагностика хранилища: показывает корневой путь, существование, права доступа, примеры путей
   */
  router.get("/storage", authRequired, async (req, res) => {
    try {
      const storage = getStorageService();
      const userId = req.user?.uid || "test-user-id";
      const channelId = "test-channel-id";
      const videoId = "test-video-id";

      // Получаем userFolderKey и channelFolderKey (для тестового пользователя используем fallback)
      let userFolderKey: string;
      let channelFolderKey: string;
      try {
        userFolderKey = await storage.resolveUserFolderKey(userId);
        channelFolderKey = await storage.resolveChannelFolderKey(userId, channelId);
      } catch (error) {
        // Для тестового пользователя используем fallback
        userFolderKey = `test-email__${userId}`;
        channelFolderKey = `test-channel__${channelId}`;
      }

      const root = storage.getRoot();
      const videosRoot = storage.getVideosRoot();
      const userDir = storage.resolveUserDir(userFolderKey);
      const channelDir = storage.resolveChannelDir(userFolderKey, channelFolderKey);
      const inboxPath = storage.resolveInboxPath(userFolderKey, channelFolderKey, videoId);
      const uploadedPath = storage.resolveUploadedPath(userFolderKey, channelFolderKey, "youtube", videoId);

      // Проверяем существование и права
      let rootExists = false;
      let rootWritable = false;
      let freeSpace: number | null = null;

      try {
        await fs.access(root, fs.constants.F_OK);
        rootExists = true;
      } catch (e) {
        rootExists = false;
      }

      try {
        await fs.access(root, fs.constants.W_OK);
        rootWritable = true;
      } catch (e) {
        rootWritable = false;
      }

      // Пытаемся получить свободное место (опционально, через exec)
      // Для простоты оставляем null - можно добавить через child_process.exec('df')
      freeSpace = null;

      const result = {
        success: true,
        storage: {
          root,
          resolvedRoot: path.resolve(root),
          exists: rootExists,
          writable: rootWritable,
          freeSpaceBytes: freeSpace,
          freeSpaceGB: freeSpace ? (freeSpace / (1024 * 1024 * 1024)).toFixed(2) : null
        },
        examplePaths: {
          userDir: {
            path: userDir,
            resolved: path.resolve(userDir)
          },
          channelDir: {
            path: channelDir,
            resolved: path.resolve(channelDir)
          },
          inboxPath: {
            path: inboxPath,
            resolved: path.resolve(inboxPath)
          },
          uploadedPath: {
            path: uploadedPath,
            resolved: path.resolve(uploadedPath)
          }
        },
        testUser: {
          userId,
          userFolderKey,
          channelId,
          channelFolderKey,
          videoId
        },
        timestamp: new Date().toISOString()
      };

      Logger.info("DIAG /api/diag/storage: storage info", result);

      return res.json(result);
    } catch (error: any) {
      Logger.error("DIAG /api/diag/storage: error", error);
      return res.status(500).json({
        error: "Failed to get storage info",
        message: error?.message || String(error)
      });
    }
  });
}

export default router;

