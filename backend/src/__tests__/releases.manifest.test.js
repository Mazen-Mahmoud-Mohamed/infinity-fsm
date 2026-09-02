import { jest } from '@jest/globals';

describe('releases.env manifest', () => {
  const originalEnv = { ...process.env };

  beforeEach(() => {
    jest.resetModules();
    process.env = { ...originalEnv };
  });

  afterAll(() => {
    process.env = originalEnv;
  });

  async function loadEnvModule() {
    return import('../modules/core/releases/releases.env.js');
  }

  it('returns null when version or build is not configured', async () => {
    delete process.env.APP_RELEASE_VERSION;
    delete process.env.APP_RELEASE_BUILD;
    const { getEnvReleaseManifest } = await loadEnvModule();
    expect(getEnvReleaseManifest('stable')).toBeNull();
  });

  it('builds a manifest from environment variables', async () => {
    process.env.APP_RELEASE_VERSION = '1.0.1';
    process.env.APP_RELEASE_BUILD = '2';
    process.env.APP_RELEASE_CHANNEL = 'stable';
    process.env.APP_RELEASE_DATE = '2026-09-02T00:00:00.000Z';
    process.env.APP_RELEASE_NOTES = 'Bug fixes and desktop improvements.';
    process.env.APP_RELEASE_WINDOWS_URL =
      'https://cdn.example.com/infinity/INFINITY-FSM-Setup-v1.0.1.exe';
    process.env.APP_RELEASE_WINDOWS_SHA256 = 'a'.repeat(64);
    process.env.APP_RELEASE_WINDOWS_SIZE = '123456789';
    process.env.APP_RELEASE_ANDROID_URL =
      'https://cdn.example.com/infinity/app-release-v1.0.1.apk';
    process.env.APP_RELEASE_ANDROID_SHA256 = 'b'.repeat(64);
    process.env.APP_RELEASE_ANDROID_SIZE = '987654321';

    const { getEnvReleaseManifest } = await loadEnvModule();
    const manifest = getEnvReleaseManifest('stable');

    expect(manifest).toEqual({
      version: '1.0.1',
      build: 2,
      channel: 'stable',
      releaseDate: '2026-09-02T00:00:00.000Z',
      releaseNotes: 'Bug fixes and desktop improvements.',
      windows: {
        available: true,
        downloadUrl:
          'https://cdn.example.com/infinity/INFINITY-FSM-Setup-v1.0.1.exe',
        sha256: 'a'.repeat(64),
        size: 123456789,
      },
      android: {
        available: true,
        downloadUrl:
          'https://cdn.example.com/infinity/app-release-v1.0.1.apk',
        sha256: 'b'.repeat(64),
        size: 987654321,
      },
    });
  });

  it('marks platforms unavailable when download URLs are absent', async () => {
    process.env.APP_RELEASE_VERSION = '1.0.0';
    process.env.APP_RELEASE_BUILD = '1';
    delete process.env.APP_RELEASE_WINDOWS_URL;
    delete process.env.APP_RELEASE_ANDROID_URL;

    const { getEnvReleaseManifest } = await loadEnvModule();
    const manifest = getEnvReleaseManifest('stable');

    expect(manifest.windows).toEqual({ available: false });
    expect(manifest.android).toEqual({ available: false });
  });
});

describe('releases.service orchestration', () => {
  const originalEnv = { ...process.env };
  const originalFetch = globalThis.fetch;

  beforeEach(() => {
    jest.resetModules();
    process.env = {
      ...originalEnv,
      APP_RELEASE_SOURCE: 'auto',
      APP_RELEASE_GITHUB_ENABLED: 'true',
      APP_RELEASE_GITHUB_OWNER: 'example',
      APP_RELEASE_GITHUB_REPO: 'infinity-fsm',
      APP_RELEASE_GITHUB_CACHE_TTL_MS: '60000',
      APP_RELEASE_VERSION: '1.0.0',
      APP_RELEASE_BUILD: '1',
      APP_RELEASE_ANDROID_URL:
        'https://cdn.example.com/infinity/app-release-v1.0.0.apk',
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

  it('uses GitHub as primary source when available', async () => {
    globalThis.fetch = jest.fn(async (url) => {
      if (url.includes('/releases/latest')) {
        return {
          ok: true,
          json: async () => ({
            tag_name: 'v1.0.2',
            draft: false,
            prerelease: false,
            body: 'Build: 3',
            published_at: '2026-09-02T00:00:00.000Z',
            assets: [
              {
                name: 'app-release.apk',
                browser_download_url: 'https://github.com/example/app-release.apk',
                size: 100,
              },
              {
                name: 'INFINITY-Setup-1.0.2.exe',
                browser_download_url: 'https://github.com/example/setup.exe',
                size: 200,
              },
            ],
          }),
        };
      }
      throw new Error(`Unexpected fetch URL: ${url}`);
    });

    const service = (await import('../modules/core/releases/releases.service.js')).default;
    service.clearCache();
    const manifest = await service.getLatestRelease('stable');

    expect(manifest.version).toBe('1.0.2');
    expect(manifest.build).toBe(3);
  });

  it('falls back to APP_RELEASE_* when GitHub fails', async () => {
    process.env.APP_RELEASE_VERSION = '1.0.1';
    process.env.APP_RELEASE_BUILD = '2';
    process.env.APP_RELEASE_ANDROID_URL =
      'https://cdn.example.com/infinity/app-release-v1.0.1.apk';

    globalThis.fetch = jest.fn(async () => ({
      ok: false,
      status: 503,
    }));

    const service = (await import('../modules/core/releases/releases.service.js')).default;
    service.clearCache();
    const manifest = await service.getLatestRelease('stable');

    expect(manifest.version).toBe('1.0.1');
    expect(manifest.build).toBe(2);
  });

  it('returns null in github-only mode when GitHub fails', async () => {
    process.env.APP_RELEASE_SOURCE = 'github';

    globalThis.fetch = jest.fn(async () => ({
      ok: false,
      status: 503,
    }));

    const service = (await import('../modules/core/releases/releases.service.js')).default;
    service.clearCache();
    const manifest = await service.getLatestRelease('stable');

    expect(manifest).toBeNull();
  });
});
