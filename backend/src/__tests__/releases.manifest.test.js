import { jest } from '@jest/globals';

describe('releases.service manifest', () => {
  const originalEnv = { ...process.env };

  beforeEach(() => {
    jest.resetModules();
    process.env = { ...originalEnv };
  });

  afterAll(() => {
    process.env = originalEnv;
  });

  async function loadService() {
    const mod = await import('../modules/core/releases/releases.service.js');
    return mod.default;
  }

  it('returns null when version or build is not configured', async () => {
    delete process.env.APP_RELEASE_VERSION;
    delete process.env.APP_RELEASE_BUILD;
    const service = await loadService();
    expect(service.getLatestRelease('stable')).toBeNull();
  });

  it('builds a manifest from environment variables', async () => {
    process.env.APP_RELEASE_VERSION = '1.0.1';
    process.env.APP_RELEASE_BUILD = '2';
    process.env.APP_RELEASE_CHANNEL = 'stable';
    process.env.APP_RELEASE_DATE = '2026-09-02T00:00:00.000Z';
    process.env.APP_RELEASE_NOTES = 'Bug fixes and desktop improvements.';
    process.env.APP_RELEASE_WINDOWS_URL =
      'https://cdn.example.com/infinity/INFINITY-FSM-Setup-v1.0.1.exe';
    process.env.APP_RELEASE_WINDOWS_SHA256 = 'abc123';
    process.env.APP_RELEASE_WINDOWS_SIZE = '123456789';
    process.env.APP_RELEASE_ANDROID_URL =
      'https://cdn.example.com/infinity/app-release-v1.0.1.apk';
    process.env.APP_RELEASE_ANDROID_SHA256 = 'def456';
    process.env.APP_RELEASE_ANDROID_SIZE = '987654321';

    const service = await loadService();
    const manifest = service.getLatestRelease('stable');

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
        sha256: 'abc123',
        size: 123456789,
      },
      android: {
        available: true,
        downloadUrl:
          'https://cdn.example.com/infinity/app-release-v1.0.1.apk',
        sha256: 'def456',
        size: 987654321,
      },
    });
  });

  it('marks platforms unavailable when download URLs are absent', async () => {
    process.env.APP_RELEASE_VERSION = '1.0.0';
    process.env.APP_RELEASE_BUILD = '1';
    delete process.env.APP_RELEASE_WINDOWS_URL;
    delete process.env.APP_RELEASE_ANDROID_URL;

    const service = await loadService();
    const manifest = service.getLatestRelease('stable');

    expect(manifest.windows).toEqual({ available: false });
    expect(manifest.android).toEqual({ available: false });
  });
});
