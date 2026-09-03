const ALLOWED_CHANNELS = new Set(['stable', 'beta']);

export function normalizeChannel(channel = 'stable') {
  return ALLOWED_CHANNELS.has(channel) ? channel : 'stable';
}

export function parseReleaseDate(raw) {
  if (!raw) return null;
  const date = new Date(raw);
  if (Number.isNaN(date.getTime())) return null;
  return date.toISOString();
}

export function normalizeHttpsUrl(raw) {
  if (!raw) return null;
  try {
    const parsed = new URL(raw);
    if (parsed.protocol !== 'https:') return null;
    return parsed.toString();
  } catch {
    return null;
  }
}

export function normalizeSha256(raw) {
  if (!raw) return null;
  const value = String(raw).trim().toLowerCase();
  return /^[a-f0-9]{64}$/.test(value) ? value : null;
}

export function buildPlatformArtifact({
  downloadUrl,
  sha256 = null,
  size = null,
}) {
  const normalizedUrl = normalizeHttpsUrl(downloadUrl);
  if (!normalizedUrl) {
    return { available: false };
  }

  const normalizedSize =
    size != null && Number.isFinite(Number(size)) && Number(size) > 0
      ? Number(size)
      : null;
  const normalizedSha256 = normalizeSha256(sha256);

  return {
    available: true,
    downloadUrl: normalizedUrl,
    ...(normalizedSha256 ? { sha256: normalizedSha256 } : {}),
    ...(normalizedSize != null ? { size: normalizedSize } : {}),
  };
}

export function normalizeReleaseManifest(raw, channel = 'stable') {
  if (!raw || typeof raw !== 'object') {
    return null;
  }

  const version = raw.version?.toString().trim() ?? '';
  const buildRaw = raw.build;
  const build =
    typeof buildRaw === 'number'
      ? buildRaw
      : Number.parseInt(buildRaw?.toString() ?? '', 10);

  if (!version || !Number.isFinite(build) || build < 0) {
    return null;
  }

  const normalizedChannel = normalizeChannel(raw.channel || channel);

  return {
    version,
    build,
    channel: normalizedChannel,
    releaseDate: parseReleaseDate(raw.releaseDate),
    releaseNotes:
      typeof raw.releaseNotes === 'string' && raw.releaseNotes.trim()
        ? raw.releaseNotes.trim()
        : null,
    windows: normalizePlatformArtifact(raw.windows),
    android: normalizePlatformArtifact(raw.android),
  };
}

function normalizePlatformArtifact(raw) {
  if (!raw || typeof raw !== 'object') {
    return { available: false };
  }

  if (raw.available === false) {
    return { available: false };
  }

  return buildPlatformArtifact({
    downloadUrl: raw.downloadUrl,
    sha256: raw.sha256,
    size: raw.size,
  });
}

export function parseSemverTag(tagName) {
  if (!tagName) return null;
  const trimmed = String(tagName).trim();
  const match = trimmed.match(/^v(\d+\.\d+\.\d+)$/i);
  return match ? match[1] : null;
}

export function parseBuildFromReleaseBody(body) {
  if (!body) return null;
  const match = String(body).match(/(?:^|\n)\s*build\s*:\s*(\d+)\s*(?:\n|$)/i);
  if (!match) return null;
  const parsed = Number.parseInt(match[1], 10);
  return Number.isFinite(parsed) && parsed >= 0 ? parsed : null;
}

/**
 * Compare two release identities (version + build).
 * @returns {number} negative if left < right, 0 if equal, positive if left > right
 */
export function compareReleaseIdentities(left, right) {
  if (!left?.version || !right?.version) {
    return 0;
  }

  const versionCmp = compareSemverParts(left.version, right.version);
  if (versionCmp !== 0) {
    return versionCmp;
  }

  const leftBuild = Number(left.build) || 0;
  const rightBuild = Number(right.build) || 0;
  return leftBuild - rightBuild;
}

export function isReleaseIdentityNewerOrEqual(candidate, current) {
  if (!candidate?.version) return false;
  if (!current?.version) return true;
  return compareReleaseIdentities(candidate, current) >= 0;
}

function compareSemverParts(left, right) {
  const leftParts = parseSemverParts(left);
  const rightParts = parseSemverParts(right);
  for (let i = 0; i < 3; i += 1) {
    if (leftParts[i] < rightParts[i]) return -1;
    if (leftParts[i] > rightParts[i]) return 1;
  }
  return 0;
}

function parseSemverParts(raw) {
  const cleaned = String(raw || '')
    .trim()
    .split('+')[0]
    .split('-')[0];
  const parts = cleaned.split('.');
  const values = [];
  for (let i = 0; i < 3; i += 1) {
    if (i >= parts.length) {
      values.push(0);
      continue;
    }
    const parsed = Number.parseInt(String(parts[i]).replace(/[^0-9]/g, ''), 10);
    values.push(Number.isFinite(parsed) ? parsed : 0);
  }
  return values;
}
