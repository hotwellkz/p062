/**
 * Worker script for Cloud Run Job
 * Executes one cycle of automation tasks and exits
 * Designed to be run by Cloud Scheduler every minute
 */

import { Logger } from "./utils/logger";
import { processAutoSendTick } from "./services/autoSendScheduler";
import { processBlottataTick } from "./services/blottataDriveMonitor";
import { db, isFirestoreAvailable } from "./services/firebaseAdmin";

const LOCK_COLLECTION = "locks";
const LOCK_DOC_ID = "worker";
const LOCK_TTL_MS = 5 * 60 * 1000; // 5 minutes

interface LockDocument {
  locked: boolean;
  lockedAt: number;
  lockedBy: string;
  expiresAt: number;
}

/**
 * Acquires a distributed lock in Firestore
 * Returns true if lock was acquired, false if already locked
 */
async function acquireLock(): Promise<boolean> {
  if (!isFirestoreAvailable() || !db) {
    Logger.warn("Firestore not available, proceeding without lock");
    return true;
  }

  try {
    const lockRef = db.collection(LOCK_COLLECTION).doc(LOCK_DOC_ID);
    const now = Date.now();
    const expiresAt = now + LOCK_TTL_MS;

    // Try to get existing lock
    const lockDoc = await lockRef.get();
    
    if (lockDoc.exists) {
      const data = lockDoc.data() as LockDocument;
      
      // Check if lock is expired
      if (data.expiresAt && data.expiresAt < now) {
        Logger.info("Worker lock expired, acquiring new lock", {
          expiredAt: new Date(data.expiresAt).toISOString(),
          now: new Date(now).toISOString()
        });
      } else if (data.locked) {
        Logger.info("Worker lock is active, skipping execution", {
          lockedAt: new Date(data.lockedAt).toISOString(),
          lockedBy: data.lockedBy,
          expiresAt: new Date(data.expiresAt).toISOString()
        });
        return false;
      }
    }

    // Acquire lock
    await lockRef.set({
      locked: true,
      lockedAt: now,
      lockedBy: `worker-${process.pid}-${Date.now()}`,
      expiresAt: expiresAt
    });

    Logger.info("Worker lock acquired", {
      lockedAt: new Date(now).toISOString(),
      expiresAt: new Date(expiresAt).toISOString()
    });

    return true;
  } catch (error) {
    Logger.error("Failed to acquire worker lock", error);
    // Proceed anyway if lock fails (fail open)
    return true;
  }
}

/**
 * Releases the distributed lock
 */
async function releaseLock(): Promise<void> {
  if (!isFirestoreAvailable() || !db) {
    return;
  }

  try {
    const lockRef = db.collection(LOCK_COLLECTION).doc(LOCK_DOC_ID);
    await lockRef.set({
      locked: false,
      lockedAt: null,
      lockedBy: null,
      expiresAt: null
    }, { merge: true });

    Logger.info("Worker lock released");
  } catch (error) {
    Logger.error("Failed to release worker lock", error);
  }
}

/**
 * Main worker function
 * Executes one cycle of automation tasks
 */
async function runWorker(): Promise<void> {
  const startTime = Date.now();
  Logger.info("Worker: Starting execution", {
    timestamp: new Date().toISOString(),
    pid: process.pid
  });

  try {
    // Acquire lock
    const lockAcquired = await acquireLock();
    if (!lockAcquired) {
      Logger.info("Worker: Lock not acquired, exiting");
      process.exit(0);
      return;
    }

    try {
      // Run automation tasks
      Logger.info("Worker: Running processAutoSendTick");
      await processAutoSendTick();

      Logger.info("Worker: Running processBlottataTick");
      await processBlottataTick();

      const duration = Date.now() - startTime;
      Logger.info("Worker: Execution completed successfully", {
        durationMs: duration,
        durationSeconds: (duration / 1000).toFixed(2)
      });
    } finally {
      // Always release lock
      await releaseLock();
    }
  } catch (error) {
    Logger.error("Worker: Execution failed", error);
    await releaseLock();
    process.exit(1);
  }

  // Exit successfully
  process.exit(0);
}

// Run worker
runWorker().catch((error) => {
  Logger.error("Worker: Unhandled error", error);
  process.exit(1);
});

