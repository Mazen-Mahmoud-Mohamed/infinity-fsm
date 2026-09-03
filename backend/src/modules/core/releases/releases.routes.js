import { Router } from 'express';
import express from 'express';
import authenticate from '../../../shared/middleware/authenticate.middleware.js';
import * as releasesController from './releases.controller.js';
import * as releasesWebhookController from './releases.webhook.controller.js';

const router = Router();

router.post(
  '/webhook/github',
  express.raw({ type: 'application/json', limit: '10mb' }),
  (req, _res, next) => {
    // After global JSON exclusion, express.raw provides the original Buffer.
    if (Buffer.isBuffer(req.body)) {
      req.rawBody = req.body;
    } else if (typeof req.body === 'string') {
      req.rawBody = Buffer.from(req.body, 'utf8');
    } else {
      req.rawBody = undefined;
    }
    next();
  },
  releasesWebhookController.githubReleaseWebhook,
);

router.use(authenticate);

router.get('/latest', releasesController.getLatestRelease);

export default router;
