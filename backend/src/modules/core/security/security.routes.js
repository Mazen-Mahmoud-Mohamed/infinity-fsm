import { Router } from 'express';
import { body } from 'express-validator';
import asyncHandler from '../../../shared/utils/asyncHandler.util.js';
import { sendSuccess } from '../../../shared/utils/apiResponse.util.js';
import authenticate from '../../../shared/middleware/authenticate.middleware.js';
import validate from '../../../shared/middleware/validate.middleware.js';
import auditService from '../audit/audit.service.js';

const router = Router();

/**
 * Sync client-side security events (e.g. device clock tampering).
 * POST /api/v1/security/events
 */
router.post(
  '/events',
  authenticate,
  validate([
    body('events').isArray({ min: 1, max: 50 }),
    body('events.*.type').isString().trim().notEmpty(),
    body('events.*.module').optional().isString().trim(),
    body('events.*.detectedAt').optional().isISO8601(),
    body('events.*.metadata').optional().isObject(),
  ]),
  asyncHandler(async (req, res) => {
    const user = req.user;
    const events = req.body.events;

    await Promise.all(
      events.map((event) =>
        auditService.log({
          companyId: user.companyId,
          actorId: user._id,
          actorRole: user.roles?.[0] || null,
          action: event.type,
          module: event.module || 'security',
          resourceType: 'device_security',
          resourceId: null,
          metadata: {
            ...(event.metadata || {}),
            detectedAt: event.detectedAt || null,
            clientDeviceId: event.deviceId || null,
          },
          ipAddress: req.ip,
          userAgent: req.get('user-agent'),
        })
      )
    );

    sendSuccess(res, { accepted: events.length });
  })
);

export default router;
