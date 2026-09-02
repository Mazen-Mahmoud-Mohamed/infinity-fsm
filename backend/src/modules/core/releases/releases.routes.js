import { Router } from 'express';
import express from 'express';
import authenticate from '../../../shared/middleware/authenticate.middleware.js';
import * as releasesController from './releases.controller.js';
import * as releasesWebhookController from './releases.webhook.controller.js';

const router = Router();

router.post(
  '/webhook/github',
  express.raw({ type: 'application/json' }),
  (req, _res, next) => {
    req.rawBody = req.body;
    next();
  },
  releasesWebhookController.githubReleaseWebhook,
);

router.use(authenticate);

router.get('/latest', releasesController.getLatestRelease);

export default router;
