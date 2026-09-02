const ALLOWED_CHANNELS = new Set(['stable', 'beta']);

function readEnvString(key) {
  const value = process.env[key];
  if (value == null) return '';
  return String(value).trim();
}

function readEnvInt(key) {
  const raw = readEnvString(key);
  if (!raw) return null;
  const parsed = Number.parseInt(raw, 10);
  return Number.isFinite(parsed) && parsed >= 0 ? parsed : null;
}

function parseReleaseDate(raw) {
  if (!raw) return null;
  const date = new Date(raw);
  if (Number.isNaN(date.getTime())) return null;
  return date.toISOString();
}

function normalizeHttpsUrl(raw) {
  if (!raw) return null;
  try {
    const parsed = new URL(raw);
    if (parsed.protocol !== 'https:') return null;
    return parsed.toString();
  } catch {
    return null;
  }
}

function buildPlatformArtifact(prefix) {
  const downloadUrl = normalizeHttpsUrl(readEnvString(`${prefix}_URL`));
  if (!downloadUrl) {
    return { available: false };
  }

  const sha256 = readEnvString(`${prefix}_SHA256`).toLowerCase() || null;
  const size = readEnvInt(`${prefix}_SIZE`);

  return {
    available: true,
    downloadUrl,
    ...(sha256 ? { sha256 } : {}),
    ...(size != null ? { size } : {}),
  };
}

function getReleaseManifest(channel = 'stable') {
  const normalizedChannel = ALLOWED_CHANNELS.has(channel) ? channel : 'stable';
  const version = readEnvString('APP_RELEASE_VERSION');
  const build = readEnvInt('APP_RELEASE_BUILD');

  if (!version || build == null) {
    return null;
  }

  return {
    version,
    build,
    channel: readEnvString('APP_RELEASE_CHANNEL') || normalizedChannel,
    releaseDate: parseReleaseDate(readEnvString('APP_RELEASE_DATE')),
    releaseNotes: readEnvString('APP_RELEASE_NOTES') || null,
    windows: buildPlatformArtifact('APP_RELEASE_WINDOWS'),
    android: buildPlatformArtifact('APP_RELEASE_ANDROID'),
  };
}

export default {
  getLatestRelease(channel) {
    const manifest = getReleaseManifest(channel);
    if (!manifest) {
      return null;
    }
    return manifest;
  },
};
