import AppNotification from './models/appNotification.model.js';
import User from '../core/organization/models/user.model.js';
import { listActiveTokensForUsers } from './deviceToken.service.js';
import { sendFcmToTokens } from './fcm.service.js';
import logger from '../../shared/utils/logger.util.js';

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

  const created = [];

  for (const recipientUserId of recipients) {
    const recipientDedupe = `${dedupeKey}:${recipientUserId}`;
    try {
      const existing = await AppNotification.findOne({
        companyId,
        recipientUserId,
        dedupeKey: recipientDedupe,
      }).lean();

      if (existing) {
        continue;
      }

      const doc = await AppNotification.create({
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
        data: {
          ...data,
          type: data.type || entityType || module,
          entityId: data.entityId || (entityId ? String(entityId) : ''),
          event: data.event || type,
        },
        actorId,
        actorName,
        isRead: false,
        dedupeKey: recipientDedupe,
      });

      created.push(doc.toObject());
    } catch (error) {
      if (error?.code === 11000) {
        // Concurrent duplicate insert — treat as already delivered.
        continue;
      }
      logger.error({ err: error }, 'Failed to persist notification');
    }
  }

  for (const doc of created) {
    deliverSideEffects(doc, io).catch((error) => {
      logger.error({ err: error }, 'Notification delivery side effect failed');
    });
  }

  return { created, skipped: false };
}

async function deliverSideEffects(doc, io) {
  const payload = mapNotification(doc, 'ar');

  try {
    if (io) {
      io.to(`user:${doc.recipientUserId.toString()}`).emit('notification:new', {
        ...payload,
        titleAr: doc.titleAr,
        titleEn: doc.titleEn,
        bodyAr: doc.bodyAr,
        bodyEn: doc.bodyEn,
      });
    }
  } catch (error) {
    logger.warn({ err: error }, 'Socket notification emit failed');
  }

  try {
    const tokens = await listActiveTokensForUsers([doc.recipientUserId]);
    if (!tokens.length) return;

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
