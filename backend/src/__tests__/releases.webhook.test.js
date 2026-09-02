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

  it('handleGithubReleaseWebhook ignores non-release actions', async () => {
    const { handleGithubReleaseWebhook } = await loadWebhookModule();
    const result = await handleGithubReleaseWebhook({
      payload: { action: 'edited' },
      io: null,
    });
    expect(result.handled).toBe(false);
  });
});
