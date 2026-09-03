import { jest } from '@jest/globals';

function buildReleaseAssets(version) {
  return [
    {
      name: 'app-release.apk',
      browser_download_url: `https://github.com/example/infinity-fsm/releases/download/v${version}/app-release.apk`,
      size: 82000000,
    },
    {
      name: `INFINITY-Setup-${version}.exe`,
      browser_download_url: `https://github.com/example/infinity-fsm/releases/download/v${version}/INFINITY-Setup-${version}.exe`,
      size: 21000000,
    },
    {
      name: 'release-manifest.json',
      browser_download_url: `https://github.com/example/infinity-fsm/releases/download/v${version}/release-manifest.json`,
      size: 600,
    },
  ];
}

function buildManifestJson(version, build) {
  return {
    version,
    build,
    channel: 'stable',
    releaseDate: '2026-09-03T11:38:11.748Z',
    releaseNotes: `INFINITY FSM v${version} automated release. Build: ${build}.`,
    android: {
      assetName: 'app-release.apk',
      downloadUrl: null,
      sha256: 'a'.repeat(64),
      size: 82000000,
      available: true,
    },
    windows: {
      assetName: `INFINITY-Setup-${version}.exe`,
      downloadUrl: null,
      sha256: 'b'.repeat(64),
      size: 21000000,
      available: true,
    },
  };
}

describe('GitHub release webhook race safety', () => {
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
      APP_RELEASE_CHANNEL: 'stable',
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

  function mockGithubFetch({
    latestVersion = '1.0.9',
    latestBuild = 10,
    taggedVersion = '1.0.10',
    taggedBuild = 11,
  } = {}) {
    const latestAssets = buildReleaseAssets(latestVersion);
    const taggedAssets = buildReleaseAssets(taggedVersion);

    globalThis.fetch = jest.fn(async (url) => {
      const href = String(url);

      if (href.includes('/releases/latest')) {
        return {
          ok: true,
          json: async () => ({
            tag_name: `v${latestVersion}`,
            draft: false,
            prerelease: false,
            body: `Build: ${latestBuild}`,
            published_at: '2026-09-03T10:00:00.000Z',
            assets: latestAssets,
          }),
        };
      }

      if (href.includes(`/releases/tags/v${taggedVersion}`)) {
        return {
          ok: true,
          json: async () => ({
            tag_name: `v${taggedVersion}`,
            draft: false,
            prerelease: false,
            body: `Build: ${taggedBuild}`,
            published_at: '2026-09-03T11:38:17.000Z',
            assets: taggedAssets,
          }),
        };
      }

      if (href.endsWith(`/v${latestVersion}/release-manifest.json`)) {
        return {
          ok: true,
          json: async () => buildManifestJson(latestVersion, latestBuild),
        };
      }

      if (href.endsWith(`/v${taggedVersion}/release-manifest.json`)) {
        return {
          ok: true,
          json: async () => buildManifestJson(taggedVersion, taggedBuild),
        };
      }

      throw new Error(`Unexpected fetch URL: ${href}`);
    });
  }

  async function loadRaceModules() {
    jest.unstable_mockModule(
      '../modules/core/organization/models/user.model.js',
      () => ({
        default: {
          find: jest.fn().mockReturnValue({
            select: jest.fn().mockReturnValue({
              lean: jest.fn().mockResolvedValue([
                { _id: 'user-1', companyId: 'company-1' },
              ]),
            }),
          }),
        },
      }),
    );

    const notifyUsers = jest.fn().mockResolvedValue({
      created: [{ _id: 'n1' }],
      skipped: false,
    });
    jest.unstable_mockModule(
      '../modules/notifications/notifications.service.js',
      () => ({
        notifyUsers,
      }),
    );

    const releasesService = (
      await import('../modules/core/releases/releases.service.js')
    ).default;
    const { handleGithubReleaseWebhook, buildAppUpdateDedupeKey } = await import(
      '../modules/core/releases/releases.webhook.js'
    );

    return {
      releasesService,
      handleGithubReleaseWebhook,
      buildAppUpdateDedupeKey,
      notifyUsers,
    };
  }

  it('A/B/C: webhook for v1.0.10 notifies 1.0.10 even when /releases/latest is v1.0.9', async () => {
    mockGithubFetch();
    const {
      releasesService,
      handleGithubReleaseWebhook,
      buildAppUpdateDedupeKey,
      notifyUsers,
    } = await loadRaceModules();

    releasesService.clearCache();

    // Seed stale latest discovery path (would return 1.0.9 if webhook used it).
    const staleLatest = await releasesService.getLatestRelease('stable');
    expect(staleLatest.version).toBe('1.0.9');
    expect(staleLatest.build).toBe(10);

    const release = {
      tag_name: 'v1.0.10',
      draft: false,
      prerelease: false,
      body: 'Build: 11',
      published_at: '2026-09-03T11:38:17.000Z',
      assets: buildReleaseAssets('1.0.10'),
    };

    const result = await handleGithubReleaseWebhook({
      payload: { action: 'published', release },
      io: null,
    });

    expect(result.handled).toBe(true);
    expect(result.version).toBe('1.0.10');
    expect(result.build).toBe(11);
    expect(result.dedupeKey).toBe(buildAppUpdateDedupeKey('1.0.10', 11));
    expect(result.dedupeKey).toBe('app-update:v1.0.10:11');
    expect(notifyUsers).toHaveBeenCalledTimes(1);
    expect(notifyUsers.mock.calls[0][0].data).toMatchObject({
      version: '1.0.10',
      build: '11',
    });

    // Must not have used /releases/latest for the webhook identity.
    const latestCalls = globalThis.fetch.mock.calls.filter(([url]) =>
      String(url).includes('/releases/latest'),
    );
    // Only the pre-seed getLatestRelease call — webhook itself uses payload/tag.
    expect(latestCalls.length).toBe(1);
  });

  it('D: webhook cache upgrade does not keep stale v1.0.9 over v1.0.10', async () => {
    mockGithubFetch();
    const { releasesService, handleGithubReleaseWebhook } =
      await loadRaceModules();

    releasesService.clearCache();
    await releasesService.getLatestRelease('stable');
    expect(releasesService.getCachedReleaseForTests('stable').version).toBe(
      '1.0.9',
    );

    await handleGithubReleaseWebhook({
      payload: {
        action: 'published',
        release: {
          tag_name: 'v1.0.10',
          draft: false,
          prerelease: false,
          body: 'Build: 11',
          assets: buildReleaseAssets('1.0.10'),
        },
      },
      io: null,
    });

    const cached = releasesService.getCachedReleaseForTests('stable');
    expect(cached.version).toBe('1.0.10');
    expect(cached.build).toBe(11);

    // Subsequent latest reads must not silently revert to stale 1.0.9 while cached.
    const latest = await releasesService.getLatestRelease('stable');
    expect(latest.version).toBe('1.0.10');
    expect(latest.build).toBe(11);
  });

  it('D2: older webhook resolution must not downgrade a newer cache', async () => {
    mockGithubFetch({
      latestVersion: '1.0.10',
      latestBuild: 11,
      taggedVersion: '1.0.9',
      taggedBuild: 10,
    });
    const { releasesService } = await loadRaceModules();
    releasesService.clearCache();

    await releasesService.getLatestRelease('stable');
    expect(releasesService.getCachedReleaseForTests('stable').version).toBe(
      '1.0.10',
    );

    const older = await releasesService.resolveManifestForGithubWebhookRelease(
      {
        tag_name: 'v1.0.9',
        draft: false,
        prerelease: false,
        body: 'Build: 10',
        assets: buildReleaseAssets('1.0.9'),
      },
      'stable',
    );

    expect(older.version).toBe('1.0.9');
    expect(releasesService.getCachedReleaseForTests('stable').version).toBe(
      '1.0.10',
    );
  });

  it('E: duplicate v1.0.10 webhook remains idempotent', async () => {
    mockGithubFetch();
    const notifyUsers = jest
      .fn()
      .mockResolvedValueOnce({ created: [{ _id: 'n1' }], skipped: false })
      .mockResolvedValueOnce({ created: [], skipped: false });

    jest.unstable_mockModule(
      '../modules/core/organization/models/user.model.js',
      () => ({
        default: {
          find: jest.fn().mockReturnValue({
            select: jest.fn().mockReturnValue({
              lean: jest.fn().mockResolvedValue([
                { _id: 'user-1', companyId: 'company-1' },
              ]),
            }),
          }),
        },
      }),
    );
    jest.unstable_mockModule(
      '../modules/notifications/notifications.service.js',
      () => ({
        notifyUsers,
      }),
    );

    const { handleGithubReleaseWebhook } = await import(
      '../modules/core/releases/releases.webhook.js'
    );
    const release = {
      tag_name: 'v1.0.10',
      draft: false,
      prerelease: false,
      body: 'Build: 11',
      assets: buildReleaseAssets('1.0.10'),
    };

    const first = await handleGithubReleaseWebhook({
      payload: { action: 'published', release },
      io: null,
    });
    const second = await handleGithubReleaseWebhook({
      payload: { action: 'published', release },
      io: null,
    });

    expect(first.dedupeKey).toBe('app-update:v1.0.10:11');
    expect(first.notified).toBe(1);
    expect(second.notified).toBe(0);
    expect(notifyUsers).toHaveBeenCalledTimes(2);
  });

  it('uses exact tag endpoint when payload lacks release-manifest.json', async () => {
    mockGithubFetch();
    const { releasesService } = await loadRaceModules();
    releasesService.clearCache();

    const manifest = await releasesService.resolveManifestForGithubWebhookRelease(
      {
        tag_name: 'v1.0.10',
        draft: false,
        prerelease: false,
        body: 'Build: 11',
        // Payload arrives before manifest asset is attached.
        assets: buildReleaseAssets('1.0.10').filter(
          (asset) => asset.name !== 'release-manifest.json',
        ),
      },
      'stable',
    );

    expect(manifest.version).toBe('1.0.10');
    expect(manifest.build).toBe(11);
    expect(manifest.android.sha256).toBe('a'.repeat(64));

    const tagCalls = globalThis.fetch.mock.calls.filter(([url]) =>
      String(url).includes('/releases/tags/v1.0.10'),
    );
    expect(tagCalls.length).toBeGreaterThanOrEqual(1);
  });
});
