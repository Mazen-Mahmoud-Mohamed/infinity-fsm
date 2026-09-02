import {
  buildPlatformArtifact,
  normalizeReleaseManifest,
  parseReleaseDate,
} from './releases.manifest.util.js';

function readEnvStringLocal(key) {
  const value = process.env[key];
  if (value == null) return '';
  return String(value).trim();
}

function readEnvIntLocal(key) {
  const raw = readEnvStringLocal(key);
  if (!raw) return null;
  const parsed = Number.parseInt(raw, 10);
  return Number.isFinite(parsed) && parsed >= 0 ? parsed : null;
}

function buildEnvPlatformArtifact(prefix) {
  return buildPlatformArtifact({
    downloadUrl: readEnvStringLocal(`${prefix}_URL`),
    sha256: readEnvStringLocal(`${prefix}_SHA256`),
    size: readEnvIntLocal(`${prefix}_SIZE`),
  });
}

export function getEnvReleaseManifest(channel = 'stable') {
  const version = readEnvStringLocal('APP_RELEASE_VERSION');
  const build = readEnvIntLocal('APP_RELEASE_BUILD');

  if (!version || build == null) {
    return null;
  }

  return normalizeReleaseManifest(
    {
      version,
      build,
      channel: readEnvStringLocal('APP_RELEASE_CHANNEL') || channel,
      releaseDate: parseReleaseDate(readEnvStringLocal('APP_RELEASE_DATE')),
      releaseNotes: readEnvStringLocal('APP_RELEASE_NOTES') || null,
      windows: buildEnvPlatformArtifact('APP_RELEASE_WINDOWS'),
      android: buildEnvPlatformArtifact('APP_RELEASE_ANDROID'),
    },
    channel,
  );
}
