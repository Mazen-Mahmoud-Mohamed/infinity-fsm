import { Router } from 'express';
import authenticate from '../../../shared/middleware/authenticate.middleware.js';
import * as releasesController from './releases.controller.js';

const router = Router();

router.use(authenticate);

router.get('/latest', releasesController.getLatestRelease);

export default router;
