import crypto from 'node:crypto';
import { jest } from '@jest/globals';
import express from 'express';
import request from 'supertest';
import {
  GITHUB_RELEASE_WEBHOOK_PATH,
  isGithubReleaseWebhookRequest,
} from '../shared/middleware/githubWebhookBody.middleware.js';

describe('GitHub release webhook HTTP signature + body parsing', () => {
  const originalEnv = { ...process.env };
  const secret = 'test-github-webhook-secret';

  beforeEach(() => {
    jest.resetModules();
    process.env = { ...originalEnv, NODE_ENV: 'test' };
    process.env.GITHUB_RELEASE_WEBHOOK_SECRET = secret;
  });

  afterAll(() => {
    process.env = originalEnv;
  });

  function signBody(rawBody, webhookSecret = secret) {
    const digest = crypto
      .createHmac('sha256', webhookSecret)
      .update(rawBody)
      .digest('hex');
    return `sha256=${digest}`;
  }

  /**
   * Mirrors production body-parser order from app.js:
   * skip JSON for webhook path → express.raw on webhook route.
   */
  async function buildProductionLikeApp() {
    const { githubReleaseWebhook } = await import(
      '../modules/core/releases/releases.webhook.controller.js'
    );

    const jsonBodyParser = express.json({ limit: '10mb' });
    const app = express();

    app.use((req, res, next) => {
      if (isGithubReleaseWebhookRequest(req)) {
        return next();
      }
      return jsonBodyParser(req, res, next);
    });

    app.post(
      GITHUB_RELEASE_WEBHOOK_PATH,
      express.raw({ type: 'application/json', limit: '10mb' }),
      (req, _res, next) => {
        if (Buffer.isBuffer(req.body)) {
          req.rawBody = req.body;
        } else if (typeof req.body === 'string') {
          req.rawBody = Buffer.from(req.body, 'utf8');
        } else {
          req.rawBody = undefined;
        }
        next();
      },
      githubReleaseWebhook
    );

    app.post('/api/v1/echo', (req, res) => {
      res.status(200).json({ success: true, data: req.body });
    });

    return app;
  }

  it('isGithubReleaseWebhookRequest matches only the webhook path', () => {
    expect(
      isGithubReleaseWebhookRequest({
        originalUrl: '/api/v1/releases/webhook/github',
      })
    ).toBe(true);
    expect(
      isGithubReleaseWebhookRequest({
        originalUrl: '/api/v1/releases/webhook/github?delivery=1',
      })
    ).toBe(true);
    expect(
      isGithubReleaseWebhookRequest({
        originalUrl: '/api/v1/releases/latest',
      })
    ).toBe(false);
  });

  it('A: valid GitHub signature + raw JSON body is accepted', async () => {
    const app = await buildProductionLikeApp();
    // Send a string (not a Buffer): SuperAgent treats Buffer as a JSON object.
    const rawText = JSON.stringify({
      zen: 'Keep it logically awesome.',
      hook_id: 1,
    });
    const raw = Buffer.from(rawText, 'utf8');

    const res = await request(app)
      .post(GITHUB_RELEASE_WEBHOOK_PATH)
      .set('Content-Type', 'application/json')
      .set('X-Hub-Signature-256', signBody(raw))
      .set('X-GitHub-Event', 'ping')
      .send(rawText);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data).toMatchObject({
      handled: false,
      reason: 'ignored_event',
    });
  });

  it('B: invalid signature => 401', async () => {
    const app = await buildProductionLikeApp();
    const rawText = '{"zen":"test"}';

    const res = await request(app)
      .post(GITHUB_RELEASE_WEBHOOK_PATH)
      .set('Content-Type', 'application/json')
      .set('X-Hub-Signature-256', 'sha256=deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef')
      .send(rawText);

    expect(res.status).toBe(401);
    expect(res.body.message).toBe('Invalid webhook signature');
  });

  it('C: missing signature => 401', async () => {
    const app = await buildProductionLikeApp();
    const rawText = '{"zen":"test"}';

    const res = await request(app)
      .post(GITHUB_RELEASE_WEBHOOK_PATH)
      .set('Content-Type', 'application/json')
      .send(rawText);

    expect(res.status).toBe(401);
    expect(res.body.message).toBe('Invalid webhook signature');
  });

  it('D: signature computed over different body => 401', async () => {
    const app = await buildProductionLikeApp();
    const rawText = '{"zen":"actual-body"}';
    const other = Buffer.from('{"zen":"tampered"}', 'utf8');

    const res = await request(app)
      .post(GITHUB_RELEASE_WEBHOOK_PATH)
      .set('Content-Type', 'application/json')
      .set('X-Hub-Signature-256', signBody(other))
      .send(rawText);

    expect(res.status).toBe(401);
    expect(res.body.message).toBe('Invalid webhook signature');
  });

  it('E: normal JSON API routes remain unaffected', async () => {
    const app = await buildProductionLikeApp();

    const res = await request(app)
      .post('/api/v1/echo')
      .set('Content-Type', 'application/json')
      .send({ hello: 'world' });

    expect(res.status).toBe(200);
    expect(res.body.data).toEqual({ hello: 'world' });
  });

  it('regression: global express.json() before raw breaks HMAC', async () => {
    const { githubReleaseWebhook } = await import(
      '../modules/core/releases/releases.webhook.controller.js'
    );
    const rawText = '{"zen":"ping"}';
    const raw = Buffer.from(rawText, 'utf8');
    const signature = signBody(raw);

    const brokenApp = express();
    brokenApp.use(express.json({ limit: '10mb' }));
    brokenApp.post(
      GITHUB_RELEASE_WEBHOOK_PATH,
      express.raw({ type: 'application/json' }),
      (req, _res, next) => {
        req.rawBody = req.body;
        next();
      },
      githubReleaseWebhook
    );

    const res = await request(brokenApp)
      .post(GITHUB_RELEASE_WEBHOOK_PATH)
      .set('Content-Type', 'application/json')
      .set('X-Hub-Signature-256', signature)
      .send(rawText);

    // Object body / missing Buffer → 400 or 401; must NOT accept as valid.
    expect(res.status).not.toBe(200);
    expect([400, 401]).toContain(res.status);
  });
});

describe('GitHub release webhook createApp integration', () => {
  const originalEnv = { ...process.env };
  const secret = 'create-app-webhook-secret';

  beforeEach(() => {
    jest.resetModules();
    process.env = { ...originalEnv, NODE_ENV: 'test' };
    process.env.GITHUB_RELEASE_WEBHOOK_SECRET = secret;
  });

  afterAll(() => {
    process.env = originalEnv;
  });

  function signBody(rawBody) {
    const digest = crypto
      .createHmac('sha256', secret)
      .update(rawBody)
      .digest('hex');
    return `sha256=${digest}`;
  }

  it('createApp stack: valid ping accepted; bad/missing signature rejected; health OK', async () => {
    const { createApp } = await import('../app.js');
    const app = createApp();
    const rawText = JSON.stringify({ zen: 'ping', hook_id: 42 });
    const raw = Buffer.from(rawText, 'utf8');

    const ok = await request(app)
      .post('/api/v1/releases/webhook/github')
      .set('Content-Type', 'application/json')
      .set('X-Hub-Signature-256', signBody(raw))
      .set('X-GitHub-Event', 'ping')
      .send(rawText);

    expect(ok.status).toBe(200);
    expect(ok.body.success).toBe(true);
    expect(ok.body.data).toMatchObject({
      handled: false,
      reason: 'ignored_event',
    });

    const bad = await request(app)
      .post('/api/v1/releases/webhook/github')
      .set('Content-Type', 'application/json')
      .set(
        'X-Hub-Signature-256',
        'sha256=0000000000000000000000000000000000000000000000000000000000000000'
      )
      .send(rawText);
    expect(bad.status).toBe(401);

    const missing = await request(app)
      .post('/api/v1/releases/webhook/github')
      .set('Content-Type', 'application/json')
      .send(rawText);
    expect(missing.status).toBe(401);

    const health = await request(app).get('/api/v1/health');
    expect(health.status).toBe(200);
    expect(health.body.success).toBe(true);
  });

  it('F: duplicate GitHub delivery remains idempotent', async () => {
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

    jest.unstable_mockModule(
      '../modules/core/releases/releases.service.js',
      () => ({
        default: {
          resolveManifestForGithubWebhookRelease: jest.fn().mockResolvedValue({
            version: '1.0.10',
            build: 11,
            channel: 'stable',
            android: { available: true },
            windows: { available: true },
          }),
        },
      })
    );

    const { handleGithubReleaseWebhook } = await import(
      '../modules/core/releases/releases.webhook.js'
    );

    const release = { tag_name: 'v1.0.10', assets: [] };
    const first = await handleGithubReleaseWebhook({
      payload: { action: 'published', release },
      io: null,
    });
    const second = await handleGithubReleaseWebhook({
      payload: { action: 'published', release },
      io: null,
    });

    expect(first.notified).toBe(1);
    expect(second.notified).toBe(0);
    expect(notifyUsers).toHaveBeenCalledTimes(2);
    expect(notifyUsers.mock.calls[0][0].dedupeKey).toBe('app-update:v1.0.10:11');
    expect(notifyUsers.mock.calls[1][0].dedupeKey).toBe('app-update:v1.0.10:11');
  });
});
