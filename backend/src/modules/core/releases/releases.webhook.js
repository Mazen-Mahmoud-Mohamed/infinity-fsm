import crypto from 'node:crypto';
import User from '../organization/models/user.model.js';
import { notifyUsers } from '../../notifications/notifications.service.js';
import logger from '../../../shared/utils/logger.util.js';
import releasesService from './releases.service.js';

function readWebhookSecret() {
  return (process.env.GITHUB_RELEASE_WEBHOOK_SECRET || '').trim();
}

export function verifyGithubSignature(rawBody, signatureHeader) {
  const secret = readWebhookSecret();
  if (!secret) {
    return false;
  }

  if (!Buffer.isBuffer(rawBody) && typeof rawBody !== 'string') {
    return false;
  }

  const signature = String(signatureHeader || '').trim();
  if (!signature.startsWith('sha256=')) {
    return false;
  }

  const digest = crypto
    .createHmac('sha256', secret)
    .update(rawBody)
    .digest('hex');

  const expected = `sha256=${digest}`;
  try {
    return crypto.timingSafeEqual(
      Buffer.from(signature),
      Buffer.from(expected)
    );
  } catch {
    return false;
  }
}

function isReleaseEvent(payload) {
  const event = String(payload?.action || '').toLowerCase();
  return event === 'published' || event === 'released' || event === 'created';
}

export function buildAppUpdateDedupeKey(version, build) {
  return `app-update:v${version}:${build}`;
}

/**
 * Active users grouped by company — covers Android FCM token holders and
 * Windows Socket.IO recipients without requiring a Windows push token.
 */
export async function listActiveRecipientsByCompany() {
  const users = await User.find({
    isActive: true,
    deletedAt: null,
  })
    .select('_id companyId')
    .lean();

  const byCompany = new Map();
  for (const user of users) {
    const companyId = user.companyId?.toString?.();
    const userId = user._id?.toString?.();
    if (!companyId || !userId) continue;
    if (!byCompany.has(companyId)) {
      byCompany.set(companyId, new Set());
    }
    byCompany.get(companyId).add(userId);
  }
  return byCompany;
}

function buildNotificationCopy(version) {
  const versionLabel = `v${version}`;
  return {
    titleEn: 'New update available',
    titleAr: 'تحديث جديد متاح',
    bodyEn: `A new INFINITY FSM version is available (${versionLabel}).`,
    bodyAr: `يتوفر الآن إصدار جديد من INFINITY FSM (${versionLabel}).`,
  };
}

/**
 * Persist + deliver one app_update notification per active user via the
 * existing notifyUsers pipeline (Socket.IO + FCM).
 */
export async function notifyAppUpdateRelease({ manifest, io }) {
  if (!manifest?.version) {
    return { notified: 0, reason: 'no_manifest' };
  }

  const version = String(manifest.version);
  const build = Number(manifest.build) || 0;
  const channel = String(manifest.channel || 'stable');
  const dedupeKey = buildAppUpdateDedupeKey(version, build);
  const copy = buildNotificationCopy(version);
  const recipientsByCompany = await listActiveRecipientsByCompany();

  let notified = 0;
  for (const [companyId, userIds] of recipientsByCompany.entries()) {
    const result = await notifyUsers({
      companyId,
      recipientUserIds: [...userIds],
      type: 'app_update',
      module: 'app_update',
      entityType: 'app_update',
      entityId: null,
      titleEn: copy.titleEn,
      titleAr: copy.titleAr,
      bodyEn: copy.bodyEn,
      bodyAr: copy.bodyAr,
      dedupeKey,
      data: {
        type: 'app_update',
        entityType: 'app_update',
        module: 'app_update',
        category: 'app_update',
        route: '/settings/updates',
        version,
        build: String(build),
        channel,
        androidAvailable: Boolean(manifest.android?.available),
        windowsAvailable: Boolean(manifest.windows?.available),
      },
      io,
    });
    notified += result.created?.length ?? 0;
  }

  return { notified, dedupeKey, version, build, channel };
}

export async function handleGithubReleaseWebhook({ payload, io }) {
  if (!isReleaseEvent(payload)) {
    return { handled: false, reason: 'ignored_event' };
  }

  releasesService.clearCache();

  const channel =
    (process.env.APP_RELEASE_CHANNEL || 'stable').trim() || 'stable';
  const manifest = await releasesService.getLatestRelease(channel);
  if (!manifest?.version) {
    return { handled: true, notified: 0, reason: 'no_manifest' };
  }

  const result = await notifyAppUpdateRelease({ manifest, io });

  logger.info('GitHub release webhook processed', {
    version: result.version,
    build: result.build,
    notified: result.notified,
    dedupeKey: result.dedupeKey,
  });

  return {
    handled: true,
    version: result.version,
    build: result.build,
    notified: result.notified,
    dedupeKey: result.dedupeKey,
  };
}

export default {
  verifyGithubSignature,
  handleGithubReleaseWebhook,
  notifyAppUpdateRelease,
  buildAppUpdateDedupeKey,
};
