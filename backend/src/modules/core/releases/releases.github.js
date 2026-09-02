import logger from '../../../shared/utils/logger.util.js';
import {
  buildPlatformArtifact,
  normalizeReleaseManifest,
  normalizeChannel,
  parseBuildFromReleaseBody,
  parseSemverTag,
  parseReleaseDate,
} from './releases.manifest.util.js';

const MANIFEST_ASSET_NAME = 'release-manifest.json';
const ANDROID_ASSET_PATTERNS = [
  /^app-release\.apk$/i,
  /^INFINITY-FSM-[\d.]+-android\.apk$/i,
  /android.*\.apk$/i,
];
const WINDOWS_ASSET_PATTERNS = [
  /^INFINITY-Setup-[\d.]+\.exe$/i,
  /^INFINITY-FSM-Setup-v[\d.]+\.exe$/i,
  /setup.*\.exe$/i,
];

function readGithubConfig() {
  const enabled =
    (process.env.APP_RELEASE_GITHUB_ENABLED ?? 'true').toLowerCase() !== 'false';
  const owner = (process.env.APP_RELEASE_GITHUB_OWNER ?? '').trim();
  const repo = (process.env.APP_RELEASE_GITHUB_REPO ?? '').trim();
  const token = (process.env.GITHUB_RELEASE_TOKEN ?? '').trim();

  return {
    enabled,
    owner,
    repo,
    token,
    isConfigured: Boolean(enabled && owner && repo),
  };
}

function githubHeaders(token) {
  const headers = {
    Accept: 'application/vnd.github+json',
    'User-Agent': 'infinity-fsm-releases',
    'X-GitHub-Api-Version': '2022-11-28',
  };
  if (token) {
    headers.Authorization = `Bearer ${token}`;
  }
  return headers;
}

async function fetchJson(url, token) {
  const response = await globalThis.fetch(url, {
    headers: githubHeaders(token),
  });

  if (!response.ok) {
    const error = new Error(`GitHub API request failed (${response.status})`);
    error.status = response.status;
    throw error;
  }

  return response.json();
}

function findAsset(assets, patterns) {
  if (!Array.isArray(assets)) return null;
  for (const pattern of patterns) {
    const match = assets.find((asset) => pattern.test(asset.name));
    if (match) return match;
  }
  return null;
}

function manifestArtifactFromAsset(asset) {
  if (!asset?.browser_download_url) {
    return { available: false };
  }

  return buildPlatformArtifact({
    downloadUrl: asset.browser_download_url,
    size: asset.size,
  });
}

function manifestArtifactFromJson(raw, assets) {
  if (!raw || typeof raw !== 'object') {
    return { available: false };
  }

  if (raw.available === false) {
    return { available: false };
  }

  let downloadUrl = raw.downloadUrl;
  if (!downloadUrl && raw.assetName && Array.isArray(assets)) {
    const asset = assets.find((item) => item.name === raw.assetName);
    downloadUrl = asset?.browser_download_url ?? null;
  }

  return buildPlatformArtifact({
    downloadUrl,
    sha256: raw.sha256,
    size: raw.size,
  });
}

export function parseGithubReleaseManifestJson(json, channel = 'stable', assets = []) {
  if (!json || typeof json !== 'object') {
    return null;
  }

  return normalizeReleaseManifest(
    {
      version: json.version,
      build: json.build,
      channel: json.channel || channel,
      releaseDate: json.releaseDate,
      releaseNotes: json.releaseNotes,
      windows: manifestArtifactFromJson(json.windows, assets),
      android: manifestArtifactFromJson(json.android, assets),
    },
    channel,
  );
}

export function synthesizeGithubReleaseManifest(release, channel = 'stable') {
  if (!release || typeof release !== 'object') {
    return null;
  }

  const version = parseSemverTag(release.tag_name);
  if (!version) {
    return null;
  }

  const build = parseBuildFromReleaseBody(release.body) ?? 1;
  const assets = release.assets ?? [];
  const androidAsset = findAsset(assets, ANDROID_ASSET_PATTERNS);
  const windowsAsset = findAsset(assets, WINDOWS_ASSET_PATTERNS);

  return normalizeReleaseManifest(
    {
      version,
      build,
      channel,
      releaseDate: parseReleaseDate(release.published_at),
      releaseNotes: release.body?.trim() || release.name?.trim() || null,
      android: manifestArtifactFromAsset(androidAsset),
      windows: manifestArtifactFromAsset(windowsAsset),
    },
    channel,
  );
}

export async function fetchLatestGithubReleaseManifest(channel = 'stable') {
  const github = readGithubConfig();
  if (!github.isConfigured) {
    return null;
  }

  const normalizedChannel = normalizeChannel(channel);
  const latestUrl = `https://api.github.com/repos/${github.owner}/${github.repo}/releases/latest`;

  let release;
  try {
    release = await fetchJson(latestUrl, github.token);
  } catch (error) {
    logger.warn('Failed to fetch latest GitHub release', {
      owner: github.owner,
      repo: github.repo,
      status: error.status,
      message: error.message,
    });
    throw error;
  }

  if (!release || release.draft || release.prerelease) {
    return null;
  }

  const manifestAsset = Array.isArray(release.assets)
    ? release.assets.find((asset) => asset.name === MANIFEST_ASSET_NAME)
    : null;

  if (manifestAsset?.browser_download_url) {
    try {
      const response = await globalThis.fetch(manifestAsset.browser_download_url, {
        headers: githubHeaders(github.token),
      });
      if (!response.ok) {
        throw new Error(`Failed to download ${MANIFEST_ASSET_NAME} (${response.status})`);
      }
      const json = await response.json();
      const parsed = parseGithubReleaseManifestJson(json, normalizedChannel, release.assets);
      if (parsed) {
        return parsed;
      }
    } catch (error) {
      logger.warn('Failed to parse GitHub release-manifest.json; falling back to asset synthesis', {
        message: error.message,
      });
    }
  }

  return synthesizeGithubReleaseManifest(release, normalizedChannel);
}

export { readGithubConfig };
