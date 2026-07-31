import { Router } from 'express';
import * as authController from './auth.controller.js';
import { loginValidator, refreshValidator, logoutValidator } from './auth.validator.js';
import validate from '../../../shared/middleware/validate.middleware.js';
import authenticate from '../../../shared/middleware/authenticate.middleware.js';
import { authRateLimiter } from '../../../shared/middleware/rateLimiter.middleware.js';

const router = Router();

router.post('/login', authRateLimiter, validate(loginValidator), authController.login);
router.post('/refresh', authRateLimiter, validate(refreshValidator), authController.refresh);
router.post('/logout', authenticate, validate(logoutValidator), authController.logout);
router.get('/me', authenticate, authController.getMe);

export default router;
