import crypto from 'node:crypto';
import User from '../organization/models/user.model.js';
import { notifyUsers } from '../../notifications/notifications.service.js';
import { mapWithConcurrency } from '../../../shared/utils/concurrency.util.js';
import logger from '../../../shared/utils/logger.util.js';
import releasesService from './releases.service.js';

/** Bound parallel company fanouts during release notifications. */
export const RELEASE_COMPANY_FANOUT_CONCURRENCY = 3;

/** Max active users processed per company per notifyUsers call. */
export const RELEASE_RECIPIENT_CHUNK_SIZE = 200;

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
 * Distinct company IDs that have at least one active user.
 * Does not materialize every user id in memory.
 */
export async function listActiveCompanyIds() {
  const raw = await User.distinct('companyId', {
    isActive: true,
    deletedAt: null,
    companyId: { $ne: null },
  });

  const ids = [];
  const seen = new Set();
  for (const value of raw || []) {
    const companyId = value?.toString?.() ?? String(value || '');
    if (!companyId || seen.has(companyId)) continue;
    seen.add(companyId);
    ids.push(companyId);
  }
  return ids;
}

/**
 * One bounded page of active user ids for a company, ordered by `_id`.
 */
export async function fetchActiveRecipientPage({
  companyId,
  afterId = null,
  limit = RELEASE_RECIPIENT_CHUNK_SIZE,
}) {
  const filter = {
    companyId,
    isActive: true,
    deletedAt: null,
  };
  if (afterId) {
    filter._id = { $gt: afterId };
  }

  const rows = await User.find(filter)
    .select('_id')
    .sort({ _id: 1 })
    .limit(limit)
    .lean();

  return rows
    .map((row) => row._id)
    .filter((id) => id != null);
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
  const companyIds = await listActiveCompanyIds();

  let notified = 0;
  await mapWithConcurrency(
    companyIds,
    RELEASE_COMPANY_FANOUT_CONCURRENCY,
    async (companyId) => {
      let afterId = null;
      for (;;) {
        let chunk;
        try {
          chunk = await fetchActiveRecipientPage({
            companyId,
            afterId,
            limit: RELEASE_RECIPIENT_CHUNK_SIZE,
          });
        } catch (error) {
          logger.error(
            { err: error, companyId },
            'Failed to load release notification recipient chunk'
          );
          break;
        }

        if (!chunk.length) break;

        const recipientUserIds = chunk.map(
          (id) => id?.toString?.() ?? String(id || '')
        );
        afterId = chunk[chunk.length - 1];

        try {
          const result = await notifyUsers({
            companyId,
            recipientUserIds,
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
        } catch (error) {
          logger.error(
            { err: error, companyId },
            'Release notification chunk failed; continuing with remaining chunks'
          );
        }

        if (chunk.length < RELEASE_RECIPIENT_CHUNK_SIZE) break;
      }
    }
  );

  return { notified, dedupeKey, version, build, channel };
}

export async function handleGithubReleaseWebhook({ payload, io }) {
  if (!isReleaseEvent(payload)) {
    return { handled: false, reason: 'ignored_event' };
  }

  const channel =
    (process.env.APP_RELEASE_CHANNEL || 'stable').trim() || 'stable';
  const release = payload?.release;

  if (!release?.tag_name) {
    logger.warn('GitHub release webhook missing payload.release.tag_name');
    return { handled: true, notified: 0, reason: 'missing_release' };
  }

  // Race-safe: resolve the exact webhook release/tag — never /releases/latest.
  const manifest = await releasesService.resolveManifestForGithubWebhookRelease(
    release,
    channel,
  );
  if (!manifest?.version) {
    return { handled: true, notified: 0, reason: 'no_manifest' };
  }

  const result = await notifyAppUpdateRelease({ manifest, io });

  logger.info('GitHub release webhook processed', {
    tag: release.tag_name,
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
    tag: release.tag_name,
  };
}

export default {
  verifyGithubSignature,
  handleGithubReleaseWebhook,
  notifyAppUpdateRelease,
  buildAppUpdateDedupeKey,
};
