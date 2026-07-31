import { Router } from 'express';
import asyncHandler from '../../../shared/utils/asyncHandler.util.js';
import { sendSuccess } from '../../../shared/utils/apiResponse.util.js';
import authenticate from '../../../shared/middleware/authenticate.middleware.js';
import config from '../../../config/index.js';

const router = Router();

/**
 * Authenticated server time — source of truth for device clock validation.
 * GET /api/v1/time
 */
router.get(
  '/',
  authenticate,
  asyncHandler(async (_req, res) => {
    const now = new Date();
    sendSuccess(res, {
      utcNow: now.toISOString(),
      unixMs: now.getTime(),
      timezoneOffsetMinutes: 0,
      maxSkewSeconds: config.security?.maxDeviceClockSkewSeconds ?? 120,
    });
  })
);

export default router;
