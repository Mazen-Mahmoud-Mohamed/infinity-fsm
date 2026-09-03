import crypto from 'node:crypto';
import { jest } from '@jest/globals';

describe('releases webhook', () => {
  const originalEnv = { ...process.env };

  beforeEach(() => {
    jest.resetModules();
    process.env = { ...originalEnv };
  });

  afterAll(() => {
    process.env = originalEnv;
  });

  async function loadWebhookModule() {
    return import('../modules/core/releases/releases.webhook.js');
  }

  it('verifyGithubSignature validates HMAC when secret configured', async () => {
    const { verifyGithubSignature } = await loadWebhookModule();
    const secret = 'test-secret';
    const body = Buffer.from('{"action":"published"}');
    const digest = crypto.createHmac('sha256', secret).update(body).digest('hex');
    process.env.GITHUB_RELEASE_WEBHOOK_SECRET = secret;

    expect(verifyGithubSignature(body, `sha256=${digest}`)).toBe(true);
    expect(verifyGithubSignature(body, 'sha256=invalid')).toBe(false);
  });

  it('verifyGithubSignature rejects when secret is missing', async () => {
    delete process.env.GITHUB_RELEASE_WEBHOOK_SECRET;
    const { verifyGithubSignature } = await loadWebhookModule();
    const body = Buffer.from('{"action":"published"}');
    expect(verifyGithubSignature(body, 'sha256=abc')).toBe(false);
  });

  it('handleGithubReleaseWebhook ignores non-release actions', async () => {
    const { handleGithubReleaseWebhook } = await loadWebhookModule();
    const result = await handleGithubReleaseWebhook({
      payload: { action: 'edited' },
      io: null,
    });
    expect(result.handled).toBe(false);
  });

  it('buildAppUpdateDedupeKey is deterministic for version+build', async () => {
    const { buildAppUpdateDedupeKey } = await loadWebhookModule();
    expect(buildAppUpdateDedupeKey('1.0.3', 4)).toBe('app-update:v1.0.3:4');
    expect(buildAppUpdateDedupeKey('1.0.3', 4)).toBe(
      buildAppUpdateDedupeKey('1.0.3', 4)
    );
  });

  it('notifyAppUpdateRelease dispatches app_update with version/build payload', async () => {
    jest.unstable_mockModule(
      '../modules/core/organization/models/user.model.js',
      () => ({
        default: {
          find: jest.fn().mockReturnValue({
            select: jest.fn().mockReturnValue({
              lean: jest.fn().mockResolvedValue([
                { _id: 'user-1', companyId: 'company-1' },
                { _id: 'user-2', companyId: 'company-1' },
              ]),
            }),
          }),
        },
      })
    );

    const notifyUsers = jest.fn().mockResolvedValue({
      created: [{ _id: 'n1' }, { _id: 'n2' }],
      skipped: false,
    });
    jest.unstable_mockModule(
      '../modules/notifications/notifications.service.js',
      () => ({
        notifyUsers,
      })
    );

    jest.unstable_mockModule(
      '../modules/core/releases/releases.service.js',
      () => ({
        default: {
          clearCache: jest.fn(),
          getLatestRelease: jest.fn(),
        },
      })
    );

    const { notifyAppUpdateRelease, buildAppUpdateDedupeKey } =
      await loadWebhookModule();

    const manifest = {
      version: '1.0.3',
      build: 4,
      channel: 'stable',
      android: { available: true },
      windows: { available: true },
    };

    const result = await notifyAppUpdateRelease({
      manifest,
      io: { to: jest.fn() },
    });

    expect(result.notified).toBe(2);
    expect(result.dedupeKey).toBe(buildAppUpdateDedupeKey('1.0.3', 4));
    expect(notifyUsers).toHaveBeenCalledTimes(1);

    const call = notifyUsers.mock.calls[0][0];
    expect(call.type).toBe('app_update');
    expect(call.module).toBe('app_update');
    expect(call.entityType).toBe('app_update');
    expect(call.entityId).toBeNull();
    expect(call.dedupeKey).toBe('app-update:v1.0.3:4');
    expect(call.titleEn).toBe('New update available');
    expect(call.titleAr).toBe('تحديث جديد متاح');
    expect(call.bodyEn).toContain('v1.0.3');
    expect(call.bodyAr).toContain('v1.0.3');
    expect(call.data).toMatchObject({
      type: 'app_update',
      version: '1.0.3',
      build: '4',
      channel: 'stable',
      route: '/settings/updates',
    });
  });

  it('handleGithubReleaseWebhook notifies once per release and is dedupe-safe', async () => {
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
      })
    );

    const notifyUsers = jest
      .fn()
      .mockResolvedValueOnce({ created: [{ _id: 'n1' }], skipped: false })
      .mockResolvedValueOnce({ created: [], skipped: false });

    jest.unstable_mockModule(
      '../modules/notifications/notifications.service.js',
      () => ({
        notifyUsers,
      })
    );

    const getLatestRelease = jest.fn().mockResolvedValue({
      version: '1.0.3',
      build: 4,
      channel: 'stable',
      android: { available: true },
      windows: { available: true },
    });
    const clearCache = jest.fn();

    jest.unstable_mockModule(
      '../modules/core/releases/releases.service.js',
      () => ({
        default: {
          clearCache,
          getLatestRelease,
        },
      })
    );

    const { handleGithubReleaseWebhook } = await loadWebhookModule();

    const first = await handleGithubReleaseWebhook({
      payload: { action: 'published' },
      io: null,
    });
    const second = await handleGithubReleaseWebhook({
      payload: { action: 'published' },
      io: null,
    });

    expect(clearCache).toHaveBeenCalled();
    expect(first.handled).toBe(true);
    expect(first.version).toBe('1.0.3');
    expect(first.build).toBe(4);
    expect(first.notified).toBe(1);
    expect(first.dedupeKey).toBe('app-update:v1.0.3:4');
    expect(second.notified).toBe(0);
    expect(notifyUsers).toHaveBeenCalledTimes(2);
    expect(notifyUsers.mock.calls[0][0].dedupeKey).toBe('app-update:v1.0.3:4');
    expect(notifyUsers.mock.calls[1][0].dedupeKey).toBe('app-update:v1.0.3:4');
  });
});
