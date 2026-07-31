import { Router } from 'express';
import authenticate from '../../../shared/middleware/authenticate.middleware.js';
import { requirePermission } from '../../../shared/middleware/authorize.middleware.js';
import { validate } from '../../../shared/middleware/validate.middleware.js';
import { upload } from '../../../config/multer.config.js';
import PERMISSIONS from '../../../shared/constants/permissions.constants.js';
import * as assetsController from './assets.controller.js';
import {
  listCategoriesValidator,
  listAssetsValidator,
  listHistoryValidator,
  idValidator,
  createCategoryValidator,
  updateCategoryValidator,
  createAssetValidator,
  updateAssetValidator,
  createHistoryValidator,
} from './assets.validator.js';

const router = Router();

router.use(authenticate);

router.get(
  '/dashboard',
  requirePermission(PERMISSIONS.ASSETS_VIEW),
  assetsController.getDashboard
);

// Categories
router.get(
  '/categories',
  requirePermission(PERMISSIONS.ASSETS_VIEW),
  validate(listCategoriesValidator),
  assetsController.listCategories
);

router.post(
  '/categories',
  requirePermission(PERMISSIONS.ASSETS_CREATE),
  validate(createCategoryValidator),
  assetsController.createCategory
);

router.get(
  '/categories/:id',
  requirePermission(PERMISSIONS.ASSETS_VIEW),
  validate(idValidator),
  assetsController.getCategory
);

router.put(
  '/categories/:id',
  requirePermission(PERMISSIONS.ASSETS_UPDATE),
  validate(updateCategoryValidator),
  assetsController.updateCategory
);

router.delete(
  '/categories/:id',
  requirePermission(PERMISSIONS.ASSETS_DELETE),
  validate(idValidator),
  assetsController.deleteCategory
);

// History (before /:id style asset routes)
router.get(
  '/history',
  requirePermission(PERMISSIONS.ASSETS_VIEW),
  validate(listHistoryValidator),
  assetsController.listHistory
);

router.post(
  '/history',
  requirePermission(PERMISSIONS.ASSETS_UPDATE),
  validate(createHistoryValidator),
  assetsController.addHistory
);

// Assets
router.get(
  '/',
  requirePermission(PERMISSIONS.ASSETS_VIEW),
  validate(listAssetsValidator),
  assetsController.listAssets
);

router.post(
  '/',
  requirePermission(PERMISSIONS.ASSETS_CREATE),
  upload.single('image'),
  validate(createAssetValidator),
  assetsController.createAsset
);

router.get(
  '/:id',
  requirePermission(PERMISSIONS.ASSETS_VIEW),
  validate(idValidator),
  assetsController.getAsset
);

router.put(
  '/:id',
  requirePermission(PERMISSIONS.ASSETS_UPDATE),
  upload.single('image'),
  validate(updateAssetValidator),
  assetsController.updateAsset
);

router.delete(
  '/:id',
  requirePermission(PERMISSIONS.ASSETS_DELETE),
  validate(idValidator),
  assetsController.deleteAsset
);

export default router;
