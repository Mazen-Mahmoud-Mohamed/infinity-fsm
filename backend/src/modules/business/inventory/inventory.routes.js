import { Router } from 'express';
import authenticate from '../../../shared/middleware/authenticate.middleware.js';
import {
  requirePermission,
} from '../../../shared/middleware/authorize.middleware.js';
import { validate } from '../../../shared/middleware/validate.middleware.js';
import { upload } from '../../../config/multer.config.js';
import PERMISSIONS from '../../../shared/constants/permissions.constants.js';
import * as inventoryController from './inventory.controller.js';
import {
  listWarehousesValidator,
  listSparePartsValidator,
  listMovementsValidator,
  warehouseIdValidator,
  sparePartIdValidator,
  createWarehouseValidator,
  updateWarehouseValidator,
  createSparePartValidator,
  updateSparePartValidator,
  stockInValidator,
  stockOutValidator,
  transferValidator,
  adjustmentValidator,
} from './inventory.validator.js';

const router = Router();

router.use(authenticate);

router.get(
  '/dashboard',
  requirePermission(PERMISSIONS.INVENTORY_VIEW),
  inventoryController.getDashboard
);

// Warehouses
router.get(
  '/warehouses',
  requirePermission(PERMISSIONS.INVENTORY_VIEW),
  validate(listWarehousesValidator),
  inventoryController.listWarehouses
);

router.post(
  '/warehouses',
  requirePermission(PERMISSIONS.INVENTORY_CREATE),
  validate(createWarehouseValidator),
  inventoryController.createWarehouse
);

router.get(
  '/warehouses/:id',
  requirePermission(PERMISSIONS.INVENTORY_VIEW),
  validate(warehouseIdValidator),
  inventoryController.getWarehouse
);

router.put(
  '/warehouses/:id',
  requirePermission(PERMISSIONS.INVENTORY_UPDATE),
  validate(updateWarehouseValidator),
  inventoryController.updateWarehouse
);

router.delete(
  '/warehouses/:id',
  requirePermission(PERMISSIONS.INVENTORY_DELETE),
  validate(warehouseIdValidator),
  inventoryController.deleteWarehouse
);

// Spare parts
router.get(
  '/parts',
  requirePermission(PERMISSIONS.INVENTORY_VIEW),
  validate(listSparePartsValidator),
  inventoryController.listSpareParts
);

router.post(
  '/parts',
  requirePermission(PERMISSIONS.INVENTORY_CREATE),
  upload.single('image'),
  validate(createSparePartValidator),
  inventoryController.createSparePart
);

router.get(
  '/parts/:id',
  requirePermission(PERMISSIONS.INVENTORY_VIEW),
  validate(sparePartIdValidator),
  inventoryController.getSparePart
);

router.put(
  '/parts/:id',
  requirePermission(PERMISSIONS.INVENTORY_UPDATE),
  upload.single('image'),
  validate(updateSparePartValidator),
  inventoryController.updateSparePart
);

router.delete(
  '/parts/:id',
  requirePermission(PERMISSIONS.INVENTORY_DELETE),
  validate(sparePartIdValidator),
  inventoryController.deleteSparePart
);

// Stock movements
router.get(
  '/movements',
  requirePermission(PERMISSIONS.INVENTORY_VIEW),
  validate(listMovementsValidator),
  inventoryController.listMovements
);

router.post(
  '/movements/stock-in',
  requirePermission(PERMISSIONS.INVENTORY_STOCK_MANAGE),
  validate(stockInValidator),
  inventoryController.stockIn
);

router.post(
  '/movements/stock-out',
  requirePermission(PERMISSIONS.INVENTORY_STOCK_MANAGE),
  validate(stockOutValidator),
  inventoryController.stockOut
);

router.post(
  '/movements/transfer',
  requirePermission(PERMISSIONS.INVENTORY_STOCK_MANAGE),
  validate(transferValidator),
  inventoryController.transfer
);

router.post(
  '/movements/adjustment',
  requirePermission(PERMISSIONS.INVENTORY_STOCK_MANAGE),
  validate(adjustmentValidator),
  inventoryController.adjustment
);

export default router;
