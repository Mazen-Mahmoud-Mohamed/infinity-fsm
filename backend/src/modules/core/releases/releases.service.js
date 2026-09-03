import logger from '../../../shared/utils/logger.util.js';
import { getEnvReleaseManifest } from './releases.env.js';
import {
  fetchLatestGithubReleaseManifest,
  readGithubConfig,
  resolveGithubReleaseManifestForWebhook,
} from './releases.github.js';
import { isReleaseIdentityNewerOrEqual } from './releases.manifest.util.js';

const DEFAULT_CACHE_TTL_MS = 5 * 60 * 1000;

let cache = {
  channel: null,
  manifest: null,
  expiresAt: 0,
};

function readReleaseSourceMode() {
  const mode = (process.env.APP_RELEASE_SOURCE ?? 'auto').trim().toLowerCase();
  if (mode === 'github' || mode === 'env' || mode === 'auto') {
    return mode;
  }
  return 'auto';
}

function readCacheTtlMs() {
  const raw = process.env.APP_RELEASE_GITHUB_CACHE_TTL_MS;
  if (!raw) return DEFAULT_CACHE_TTL_MS;
  const parsed = Number.parseInt(raw, 10);
  return Number.isFinite(parsed) && parsed >= 0 ? parsed : DEFAULT_CACHE_TTL_MS;
}

function getCachedManifest(channel) {
  if (cache.channel === channel && cache.expiresAt > Date.now()) {
    return cache.manifest;
  }
  return undefined;
}

function setCachedManifest(channel, manifest) {
  cache = {
    channel,
    manifest,
    expiresAt: Date.now() + readCacheTtlMs(),
  };
}

/**
 * Update the GitHub latest-release cache only when the candidate is newer
 * or equal to the currently cached identity. Never downgrade on webhook races.
 */
function rememberGithubManifest(channel, manifest) {
  if (!manifest?.version) {
    return false;
  }

  const current =
    cache.channel === channel && cache.expiresAt > Date.now()
      ? cache.manifest
      : null;

  if (current && !isReleaseIdentityNewerOrEqual(manifest, current)) {
    logger.info('Skipped GitHub release cache downgrade', {
      channel,
      cachedVersion: current.version,
      cachedBuild: current.build,
      candidateVersion: manifest.version,
      candidateBuild: manifest.build,
    });
    return false;
  }

  setCachedManifest(channel, manifest);
  return true;
}

async function getGithubReleaseManifest(channel) {
  const cached = getCachedManifest(channel);
  if (cached !== undefined) {
    return cached;
  }

  const manifest = await fetchLatestGithubReleaseManifest(channel);
  if (manifest) {
    setCachedManifest(channel, manifest);
  }
  return manifest;
}

function logResolvedManifest(source, manifest) {
  if (!manifest) return;
  logger.info('Release manifest resolved', {
    source,
    version: manifest.version,
    build: manifest.build,
    androidUrl: manifest.android?.downloadUrl ?? null,
    androidSize: manifest.android?.size ?? null,
  });
}

export default {
  async getLatestRelease(channel = 'stable') {
    const sourceMode = readReleaseSourceMode();
    const github = readGithubConfig();

    if (sourceMode !== 'env') {
      if (github.isConfigured) {
        try {
          const githubManifest = await getGithubReleaseManifest(channel);
          if (githubManifest) {
            logResolvedManifest('github', githubManifest);
            return githubManifest;
          }
        } catch (error) {
          logger.warn('GitHub release lookup failed; attempting APP_RELEASE_* fallback', {
            message: error.message,
          });
        }
      }
    }

    if (sourceMode === 'github') {
      return null;
    }

    const envManifest = getEnvReleaseManifest(channel);
    if (envManifest) {
      logger.warn('Release manifest resolved from APP_RELEASE_* fallback', {
        version: envManifest.version,
        build: envManifest.build,
        androidUrl: envManifest.android?.downloadUrl ?? null,
      });
    }
    return envManifest;
  },

  /**
   * Resolve the exact release from a GitHub webhook payload and safely
   * refresh the latest-release cache (upgrade-only).
   */
  async resolveManifestForGithubWebhookRelease(release, channel = 'stable') {
    const sourceMode = readReleaseSourceMode();
    const github = readGithubConfig();

    if (sourceMode === 'env' || !github.isConfigured) {
      return null;
    }

    const manifest = await resolveGithubReleaseManifestForWebhook(
      release,
      channel,
    );
    if (!manifest) {
      return null;
    }

    rememberGithubManifest(channel, manifest);
    logResolvedManifest('github_webhook', manifest);
    return manifest;
  },

  clearCache() {
    cache = {
      channel: null,
      manifest: null,
      expiresAt: 0,
    };
  },

  /** Test helper: inspect cache identity without exposing TTL internals. */
  getCachedReleaseForTests(channel = 'stable') {
    return getCachedManifest(channel) ?? null;
  },
};
