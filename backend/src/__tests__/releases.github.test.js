import { jest } from '@jest/globals';
import {
  parseBuildFromReleaseBody,
  parseSemverTag,
  normalizeReleaseManifest,
} from '../modules/core/releases/releases.manifest.util.js';
import {
  parseGithubReleaseManifestJson,
  synthesizeGithubReleaseManifest,
} from '../modules/core/releases/releases.github.js';

const assets = [
  {
    name: 'app-release.apk',
    browser_download_url:
      'https://github.com/example/infinity-fsm/releases/download/v1.0.2/app-release.apk',
    size: 82000000,
  },
  {
    name: 'INFINITY-Setup-1.0.2.exe',
    browser_download_url:
      'https://github.com/example/infinity-fsm/releases/download/v1.0.2/INFINITY-Setup-1.0.2.exe',
    size: 21000000,
  },
  {
    name: 'release-manifest.json',
    browser_download_url:
      'https://github.com/example/infinity-fsm/releases/download/v1.0.2/release-manifest.json',
    size: 1000,
  },
];

describe('releases.manifest.util', () => {
  it('parses semver tags', () => {
    expect(parseSemverTag('v1.0.2')).toBe('1.0.2');
    expect(parseSemverTag('V1.0.2')).toBe('1.0.2');
    expect(parseSemverTag('1.0.2')).toBeNull();
  });

  it('parses build number from release body', () => {
    expect(parseBuildFromReleaseBody('INFINITY FSM v1.0.1\r\n\r\nBuild: 2\r\n')).toBe(2);
    expect(parseBuildFromReleaseBody('No build here')).toBeNull();
  });

  it('normalizes release manifest', () => {
    const manifest = normalizeReleaseManifest(
      {
        version: '1.0.2',
        build: 3,
        channel: 'stable',
        releaseDate: '2026-09-02T00:00:00.000Z',
        releaseNotes: 'Notes',
        windows: {
          downloadUrl: 'https://github.com/example/INFINITY-Setup-1.0.2.exe',
          sha256: 'a'.repeat(64),
          size: 100,
        },
        android: {
          downloadUrl: 'https://github.com/example/app-release.apk',
          sha256: 'b'.repeat(64),
          size: 200,
        },
      },
      'stable',
    );

    expect(manifest.version).toBe('1.0.2');
    expect(manifest.build).toBe(3);
    expect(manifest.windows.available).toBe(true);
    expect(manifest.android.available).toBe(true);
  });
});

describe('releases.github parsing', () => {
  it('parses release-manifest.json and resolves asset download URLs', () => {
    const manifest = parseGithubReleaseManifestJson(
      {
        version: '1.0.2',
        build: 3,
        channel: 'stable',
        releaseDate: '2026-09-02T00:00:00.000Z',
        releaseNotes: 'Automated release',
        android: {
          assetName: 'app-release.apk',
          sha256: 'a'.repeat(64),
          size: 82000000,
        },
        windows: {
          assetName: 'INFINITY-Setup-1.0.2.exe',
          sha256: 'b'.repeat(64),
          size: 21000000,
        },
      },
      'stable',
      assets,
    );

    expect(manifest.version).toBe('1.0.2');
    expect(manifest.build).toBe(3);
    expect(manifest.android.downloadUrl).toContain('app-release.apk');
    expect(manifest.android.sha256).toBe('a'.repeat(64));
    expect(manifest.windows.downloadUrl).toContain('INFINITY-Setup-1.0.2.exe');
  });

  it('synthesizes manifest from GitHub release metadata and assets', () => {
    const manifest = synthesizeGithubReleaseManifest(
      {
        tag_name: 'v1.0.1',
        name: 'INFINITY FSM v1.0.1',
        body: 'Build: 2\r\nNotes',
        published_at: '2026-09-02T12:27:45Z',
        assets,
      },
      'stable',
    );

    expect(manifest.version).toBe('1.0.1');
    expect(manifest.build).toBe(2);
    expect(manifest.android.available).toBe(true);
    expect(manifest.windows.available).toBe(true);
    expect(manifest.android.sha256).toBeUndefined();
  });

  it('returns null when tag is not semver', () => {
    expect(
      synthesizeGithubReleaseManifest(
        {
          tag_name: 'release-candidate',
          assets: [],
        },
        'stable',
      ),
    ).toBeNull();
  });
});

describe('releases.github fetch', () => {
  const originalEnv = { ...process.env };
  const originalFetch = globalThis.fetch;

  beforeEach(() => {
    jest.resetModules();
    process.env = {
      ...originalEnv,
      APP_RELEASE_GITHUB_ENABLED: 'true',
      APP_RELEASE_GITHUB_OWNER: 'example',
      APP_RELEASE_GITHUB_REPO: 'infinity-fsm',
    };
  });

  afterEach(() => {
    process.env = originalEnv;
    globalThis.fetch = originalFetch;
  });

  afterAll(() => {
    process.env = originalEnv;
    globalThis.fetch = originalFetch;
  });

  it('fetches and prefers release-manifest.json asset', async () => {
    globalThis.fetch = jest.fn(async (url) => {
      if (url.includes('/releases/latest')) {
        return {
          ok: true,
          json: async () => ({
            tag_name: 'v1.0.2',
            draft: false,
            prerelease: false,
            assets,
          }),
        };
      }

      if (url.endsWith('release-manifest.json')) {
        return {
          ok: true,
          json: async () => ({
            version: '1.0.2',
            build: 3,
            channel: 'stable',
            releaseDate: '2026-09-02T00:00:00.000Z',
            releaseNotes: 'Automated release',
            android: {
              assetName: 'app-release.apk',
              sha256: 'a'.repeat(64),
              size: 82000000,
            },
            windows: {
              assetName: 'INFINITY-Setup-1.0.2.exe',
              sha256: 'b'.repeat(64),
              size: 21000000,
            },
          }),
        };
      }

      throw new Error(`Unexpected fetch URL: ${url}`);
    });

    const { fetchLatestGithubReleaseManifest } = await import(
      '../modules/core/releases/releases.github.js'
    );
    const manifest = await fetchLatestGithubReleaseManifest('stable');

    expect(manifest.version).toBe('1.0.2');
    expect(manifest.android.sha256).toBe('a'.repeat(64));
  });

  it('throws when GitHub API fails', async () => {
    globalThis.fetch = jest.fn(async () => ({
      ok: false,
      status: 503,
    }));

    const { fetchLatestGithubReleaseManifest } = await import(
      '../modules/core/releases/releases.github.js'
    );

    await expect(fetchLatestGithubReleaseManifest('stable')).rejects.toThrow(
      'GitHub API request failed (503)',
    );
  });
});
