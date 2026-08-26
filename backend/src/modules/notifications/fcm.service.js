import fs from 'fs';
import admin from 'firebase-admin';
import config from '../../config/index.js';
import logger from '../../shared/utils/logger.util.js';
import DevicePushToken from './models/devicePushToken.model.js';

let initialized = false;
let initAttempted = false;

function tryInitializeFirebase() {
  if (initAttempted) {
    return initialized;
  }
  initAttempted = true;

  if (!config.fcm.enabled) {
    logger.info('FCM disabled or not configured — push delivery skipped');
    return false;
  }

  try {
    if (admin.apps.length === 0) {
      let credentials;
      if (config.fcm.serviceAccountJson) {
        credentials = JSON.parse(config.fcm.serviceAccountJson);
      } else if (config.fcm.serviceAccountPath) {
        const raw = fs.readFileSync(config.fcm.serviceAccountPath, 'utf8');
        credentials = JSON.parse(raw);
      } else {
        logger.warn('FCM enabled but no service account credentials provided');
        return false;
      }
      admin.initializeApp({
        credential: admin.credential.cert(credentials),
      });
    }
    initialized = true;
    logger.info('Firebase Admin initialized for FCM');
    return true;
  } catch (error) {
    logger.error({ err: error }, 'Failed to initialize Firebase Admin');
    initialized = false;
    return false;
  }
}

/**
 * Send an FCM notification to one or more device tokens.
 * Never throws to callers — push is a side effect.
 *
 * @returns {{ sent: number, failed: number, skipped: boolean }}
 */
export async function sendFcmToTokens({
  tokens,
  title,
  body,
  data = {},
  androidChannelId = 'infinity_default',
}) {
  if (!tokens?.length) {
    return { sent: 0, failed: 0, skipped: true };
  }

  if (!tryInitializeFirebase()) {
    return { sent: 0, failed: 0, skipped: true };
  }

  const stringData = Object.fromEntries(
    Object.entries(data).map(([key, value]) => [
      key,
      value == null ? '' : String(value),
    ])
  );

  let sent = 0;
  let failed = 0;

  // Batch in chunks of 500 (FCM limit).
  const chunkSize = 500;
  for (let i = 0; i < tokens.length; i += chunkSize) {
    const chunk = tokens.slice(i, i + chunkSize);
    try {
      const response = await admin.messaging().sendEachForMulticast({
        tokens: chunk.map((item) => item.token),
        notification: {
          title,
          body,
        },
        data: stringData,
        android: {
          priority: 'high',
          notification: {
            channelId: androidChannelId,
            clickAction: 'FLUTTER_NOTIFICATION_CLICK',
            tag: stringData.notificationId || undefined,
          },
        },
      });

      sent += response.successCount;
      failed += response.failureCount;

      const invalidTokens = [];
      response.responses.forEach((result, index) => {
        if (result.success) return;
        const code = result.error?.code || '';
        if (
          code.includes('registration-token-not-registered') ||
          code.includes('invalid-registration-token') ||
          code.includes('invalid-argument')
        ) {
          invalidTokens.push(chunk[index].token);
        } else {
          logger.warn(
            { code, message: result.error?.message },
            'FCM send failed for token'
          );
        }
      });

      if (invalidTokens.length) {
        await DevicePushToken.updateMany(
          { token: { $in: invalidTokens } },
          {
            $set: {
              active: false,
              deactivatedAt: new Date(),
              deactivationReason: 'fcm_invalid',
            },
          }
        );
      }
    } catch (error) {
      logger.error({ err: error }, 'FCM multicast failed');
      failed += chunk.length;
    }
  }

  return { sent, failed, skipped: false };
}

export function isFcmConfigured() {
  return tryInitializeFirebase();
}

export default {
  sendFcmToTokens,
  isFcmConfigured,
};
