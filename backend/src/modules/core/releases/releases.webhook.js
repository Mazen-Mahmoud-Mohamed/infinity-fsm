import crypto from 'node:crypto';
import DevicePushToken from '../../notifications/models/devicePushToken.model.js';
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

async function listRecipientUserIdsByPlatform(platform) {
  const tokens = await DevicePushToken.find({
    active: true,
    platform,
  })
    .select('userId companyId')
    .lean();

  const byCompany = new Map();
  for (const token of tokens) {
    const companyId = token.companyId?.toString?.();
    const userId = token.userId?.toString?.();
    if (!companyId || !userId) continue;
    if (!byCompany.has(companyId)) {
      byCompany.set(companyId, new Set());
    }
    byCompany.get(companyId).add(userId);
  }
  return byCompany;
}

async function notifyPlatformUsers({
  manifest,
  platform,
  io,
}) {
  const artifact = manifest?.[platform];
  if (!artifact?.available) {
    return { platform, notified: 0 };
  }

  const recipientsByCompany = await listRecipientUserIdsByPlatform(platform);
  let notified = 0;
  const version = manifest.version;
  const dedupeKey = `update:v${version}:${platform}`;

  for (const [companyId, userIds] of recipientsByCompany.entries()) {
    const result = await notifyUsers({
      companyId,
      recipientUserIds: [...userIds],
      type: 'app_update',
      module: 'app_update',
      entityType: 'app_update',
      entityId: version,
      titleEn: 'INFINITY update available',
      titleAr: 'تحديث جديد لـ INFINITY',
      bodyEn: `Version ${version} is now available.`,
      bodyAr: `الإصدار ${version} متاح الآن.`,
      dedupeKey,
      data: {
        type: 'app_update',
        entityType: 'app_update',
        module: 'app_update',
        route: '/settings/updates',
        version,
        platform,
      },
      io,
    });
    notified += result.created?.length ?? 0;
  }

  return { platform, notified };
}

export async function handleGithubReleaseWebhook({ payload, io }) {
  if (!isReleaseEvent(payload)) {
    return { handled: false, reason: 'ignored_event' };
  }

  releasesService.clearCache();

  const channel = (process.env.APP_RELEASE_CHANNEL || 'stable').trim() || 'stable';
  const manifest = await releasesService.getLatestRelease(channel);
  if (!manifest?.version) {
    return { handled: true, notified: 0, reason: 'no_manifest' };
  }

  const android = await notifyPlatformUsers({
    manifest,
    platform: 'android',
    io,
  });
  const windows = await notifyPlatformUsers({
    manifest,
    platform: 'windows',
    io,
  });

  logger.info('GitHub release webhook processed', {
    version: manifest.version,
    android: android.notified,
    windows: windows.notified,
  });

  return {
    handled: true,
    version: manifest.version,
    notified: android.notified + windows.notified,
  };
}

export default {
  verifyGithubSignature,
  handleGithubReleaseWebhook,
};
