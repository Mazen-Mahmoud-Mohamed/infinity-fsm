import AppNotification from './models/appNotification.model.js';
import User from '../core/organization/models/user.model.js';
import { listActiveTokensForUsers } from './deviceToken.service.js';
import { sendFcmToTokens } from './fcm.service.js';
import logger from '../../shared/utils/logger.util.js';
import { mapWithConcurrency } from '../../shared/utils/concurrency.util.js';

/** Max concurrent per-recipient FCM sends after a shared token lookup. */
const FCM_DELIVERY_CONCURRENCY = 8;

/**
 * Create recipient notifications + deliver via Socket.IO and FCM.
 * Duplicate dedupeKey → no second push.
 * Push/socket failures never throw to business callers.
 */
export async function notifyUsers({
  companyId,
  recipientUserIds,
  type,
  module,
  titleAr,
  titleEn,
  bodyAr,
  bodyEn,
  entityType = null,
  entityId = null,
  data = {},
  actorId = null,
  actorName = null,
  dedupeKey,
  io = null,
}) {
  const recipients = [
    ...new Set(
      (recipientUserIds || [])
        .map((id) => id?.toString?.() ?? String(id || ''))
        .filter(Boolean)
    ),
  ];

  if (!recipients.length || !dedupeKey) {
    return { created: [], skipped: true };
  }

  const notificationData = {
    ...data,
    type: data.type || entityType || module,
    entityId: data.entityId || (entityId ? String(entityId) : ''),
    event: data.event || type,
  };

  const docsToInsert = [];
  const recipientDedupes = [];

  for (const recipientUserId of recipients) {
    const recipientDedupe = `${dedupeKey}:${recipientUserId}`;
    recipientDedupes.push(recipientDedupe);
    docsToInsert.push({
      companyId,
      recipientUserId,
      type,
      module,
      titleAr,
      titleEn,
      bodyAr,
      bodyEn,
      entityType,
      entityId,
      data: notificationData,
      actorId,
      actorName,
      isRead: false,
      dedupeKey: recipientDedupe,
    });
  }

  let existingKeys = new Set();
  try {
    const existing = await AppNotification.find({
      companyId,
      dedupeKey: { $in: recipientDedupes },
    })
      .select('dedupeKey')
      .lean();
    existingKeys = new Set(existing.map((row) => row.dedupeKey));
  } catch (error) {
    logger.error({ err: error }, 'Failed to preload notification dedupe keys');
  }

  const freshDocs = docsToInsert.filter(
    (doc) => !existingKeys.has(doc.dedupeKey)
  );

  const created = [];
  if (freshDocs.length) {
    try {
      const inserted = await AppNotification.insertMany(freshDocs, {
        ordered: false,
      });
      for (const doc of inserted) {
        created.push(typeof doc.toObject === 'function' ? doc.toObject() : doc);
      }
    } catch (error) {
      const insertedDocs = extractInsertedDocs(error);
      for (const doc of insertedDocs) {
        created.push(typeof doc.toObject === 'function' ? doc.toObject() : doc);
      }

      const writeErrors = Array.isArray(error?.writeErrors)
        ? error.writeErrors
        : [];
      const unexpected = writeErrors.filter((err) => err?.code !== 11000);
      if (unexpected.length) {
        logger.error(
          { err: error, unexpectedCount: unexpected.length },
          'Failed to persist some notifications'
        );
      } else if (!insertedDocs.length && error?.code !== 11000) {
        // Non-bulk failure (or empty insert with unexpected error).
        const isDuplicate =
          error?.code === 11000 ||
          writeErrors.every((err) => err?.code === 11000);
        if (!isDuplicate) {
          logger.error({ err: error }, 'Failed to persist notification batch');
        }
      }
    }
  }

  if (created.length) {
    deliverCreatedNotifications(created, io).catch((error) => {
      logger.error({ err: error }, 'Notification delivery side effect failed');
    });
  }

  return { created, skipped: false };
}

function extractInsertedDocs(error) {
  if (Array.isArray(error?.insertedDocs)) {
    return error.insertedDocs;
  }
  if (Array.isArray(error?.mongoose?.results)) {
    return error.mongoose.results.filter(Boolean);
  }
  return [];
}

/**
 * Socket emits are targeted per user room. FCM uses one token query then
 * bounded per-recipient sends (payload includes per-notification ids).
 */
async function deliverCreatedNotifications(created, io) {
  for (const doc of created) {
    emitSocketNotification(doc, io);
  }

  const userIds = [
    ...new Set(
      created
        .map((doc) => doc.recipientUserId?.toString?.() ?? String(doc.recipientUserId || ''))
        .filter(Boolean)
    ),
  ];

  let tokens = [];
  try {
    tokens = await listActiveTokensForUsers(userIds);
  } catch (error) {
    logger.error({ err: error }, 'FCM token lookup failed');
    return;
  }

  if (!tokens.length) {
    return;
  }

  /** @type {Map<string, typeof tokens>} */
  const tokensByUser = new Map();
  for (const token of tokens) {
    const userId = token.userId?.toString?.() ?? String(token.userId || '');
    if (!userId) continue;
    if (!tokensByUser.has(userId)) {
      tokensByUser.set(userId, []);
    }
    tokensByUser.get(userId).push(token);
  }

  await mapWithConcurrency(created, FCM_DELIVERY_CONCURRENCY, async (doc) => {
    const recipientId =
      doc.recipientUserId?.toString?.() ?? String(doc.recipientUserId || '');
    const userTokens = tokensByUser.get(recipientId) || [];
    if (!userTokens.length) return;
    await sendFcmForNotification(doc, userTokens);
  });
}

function emitSocketNotification(doc, io) {
  try {
    if (!io) return;
    const payload = mapNotification(doc, 'ar');
    io.to(`user:${doc.recipientUserId.toString()}`).emit('notification:new', {
      ...payload,
      titleAr: doc.titleAr,
      titleEn: doc.titleEn,
      bodyAr: doc.bodyAr,
      bodyEn: doc.bodyEn,
    });
  } catch (error) {
    logger.warn({ err: error }, 'Socket notification emit failed');
  }
}

async function sendFcmForNotification(doc, tokens) {
  try {
    const byLocale = { ar: [], en: [] };
    for (const token of tokens) {
      const locale = token.locale === 'en' ? 'en' : 'ar';
      byLocale[locale].push(token);
    }

    for (const locale of ['ar', 'en']) {
      const group = byLocale[locale];
      if (!group.length) continue;
      const title = locale === 'en' ? doc.titleEn : doc.titleAr;
      const body = locale === 'en' ? doc.bodyEn : doc.bodyAr;
      const flatData = Object.fromEntries(
        Object.entries(doc.data || {}).map(([k, v]) => [
          k,
          v == null ? '' : String(v),
        ])
      );
      const entityType = doc.entityType || doc.module || 'general';
      const entityId = doc.entityId ? String(doc.entityId) : '';
      // Visible title/body stay in `notification`; navigation lives in `data`.
      // Stable keys are forced last so callers can rely on them for deep links.
      const isAppUpdate =
        entityType === 'app_update' ||
        doc.type === 'app_update' ||
        doc.module === 'app_update';
      await sendFcmToTokens({
        tokens: group,
        title,
        body,
        androidChannelId: isAppUpdate ? 'infinity_updates' : 'infinity_default',
        data: {
          ...flatData,
          notificationId: doc._id.toString(),
          type: flatData.type || entityType,
          entityId: flatData.entityId || entityId,
          workOrderId:
            flatData.workOrderId ||
            (entityType === 'work_order' ? entityId : ''),
          overtimeId:
            flatData.overtimeId ||
            (entityType === 'overtime' ? entityId : ''),
          event: flatData.event || doc.type || '',
          recipientUserId: doc.recipientUserId.toString(),
        },
      });
    }
  } catch (error) {
    logger.error({ err: error }, 'FCM delivery failed');
  }
}

/**
 * List recipient notifications for the authenticated user.
 *
 * Backend path is AppNotification-only (company + recipient scoped). There is
 * no dashboard-summary fallback here — that legacy fallback lives only in the
 * Flutter client when the dedicated API is unavailable.
 */
export async function listNotifications(user, auth, { page = 1, limit = 50 } = {}) {
  const pageNum = Math.max(1, Number(page) || 1);
  const limitNum = Math.min(100, Math.max(1, Number(limit) || 50));
  const skip = (pageNum - 1) * limitNum;

  const filter = {
    companyId: auth.companyId,
    recipientUserId: user._id,
  };

  const [items, total, unreadCount] = await Promise.all([
    AppNotification.find(filter)
      .select(
        'type module titleAr titleEn bodyAr bodyEn entityType entityId data actorName isRead createdAt'
      )
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limitNum)
      .lean(),
    AppNotification.countDocuments(filter),
    AppNotification.countDocuments({ ...filter, isRead: false }),
  ]);

  return {
    items: items.map((doc) => mapNotification(doc)),
    pagination: {
      page: pageNum,
      limit: limitNum,
      total,
      totalPages: Math.ceil(total / limitNum) || 1,
    },
    unreadCount,
  };
}

export async function getUnreadCount(user, auth) {
  const count = await AppNotification.countDocuments({
    companyId: auth.companyId,
    recipientUserId: user._id,
    isRead: false,
  });
  return { count };
}

export async function markAsRead(user, auth, id) {
  const doc = await AppNotification.findOneAndUpdate(
    {
      _id: id,
      companyId: auth.companyId,
      recipientUserId: user._id,
    },
    { $set: { isRead: true, readAt: new Date() } },
    { new: true }
  ).lean();

  if (!doc) {
    const error = new Error('Notification not found');
    error.statusCode = 404;
    error.code = 'NOT_FOUND';
    error.isOperational = true;
    throw error;
  }

  return mapNotification(doc);
}

export async function markAllAsRead(user, auth) {
  const result = await AppNotification.updateMany(
    {
      companyId: auth.companyId,
      recipientUserId: user._id,
      isRead: false,
    },
    { $set: { isRead: true, readAt: new Date() } }
  );
  return { updated: result.modifiedCount };
}

/**
 * Company admins + supervisors who should see management events.
 */
export async function findManagementRecipientIds(
  companyId,
  { excludeUserId = null } = {}
) {
  const users = await User.find({
    companyId,
    isActive: true,
    deletedAt: null,
    roles: { $in: ['ADMIN', 'SUPERVISOR'] },
  })
    .select('_id')
    .lean();

  return users
    .map((u) => u._id.toString())
    .filter((id) => !excludeUserId || id !== String(excludeUserId));
}

export function mapNotification(doc, localeHint) {
  const preferEn = localeHint === 'en';
  return {
    id: doc._id.toString(),
    type: doc.type,
    module: doc.module,
    title: preferEn ? doc.titleEn : doc.titleAr,
    titleAr: doc.titleAr,
    titleEn: doc.titleEn,
    body: preferEn ? doc.bodyEn : doc.bodyAr,
    bodyAr: doc.bodyAr,
    bodyEn: doc.bodyEn,
    entityType: doc.entityType,
    entityId: doc.entityId ? String(doc.entityId) : null,
    data: doc.data || {},
    actorName: doc.actorName,
    isRead: Boolean(doc.isRead),
    createdAt: doc.createdAt,
  };
}

export default {
  notifyUsers,
  listNotifications,
  getUnreadCount,
  markAsRead,
  markAllAsRead,
  findManagementRecipientIds,
};

export { mapWithConcurrency };
