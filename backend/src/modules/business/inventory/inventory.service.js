import Warehouse from './models/warehouse.model.js';
import SparePart from './models/sparePart.model.js';
import StockMovement, {
  STOCK_MOVEMENT_TYPES,
} from './models/stockMovement.model.js';
import { uploadSparePartImageBuffer } from './inventory.upload.js';
import PERMISSIONS from '../../../shared/constants/permissions.constants.js';
import AppError, {
  ConflictError,
  ForbiddenError,
  NotFoundError,
} from '../../../shared/errors/AppError.js';
import auditService from '../../core/audit/audit.service.js';

function escapeRegex(value) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function toId(value) {
  return value?.toString?.() ?? value ?? null;
}

function displayUserName(user) {
  if (!user) {
    return null;
  }
  const full = [user.firstName, user.lastName].filter(Boolean).join(' ').trim();
  return full || user.email || user.username || null;
}

function parseOptionalDate(value) {
  if (value === undefined || value === null || value === '') {
    return new Date();
  }
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) {
    throw new AppError('INVALID_DATE', 'movementDate must be a valid ISO date', 422);
  }
  return date;
}

function parseBoolean(value, fallback = undefined) {
  if (value === undefined || value === null || value === '') {
    return fallback;
  }
  if (typeof value === 'boolean') {
    return value;
  }
  const normalized = String(value).toLowerCase();
  if (['true', '1', 'yes'].includes(normalized)) {
    return true;
  }
  if (['false', '0', 'no'].includes(normalized)) {
    return false;
  }
  return fallback;
}

function parseNonNegativeNumber(value, fieldName) {
  const number = Number(value);
  if (!Number.isFinite(number) || number < 0) {
    throw new AppError('INVALID_QUANTITY', `${fieldName} must be a non-negative number`, 422);
  }
  return number;
}

function parsePositiveQuantity(value) {
  const number = Number(value);
  if (!Number.isFinite(number) || number <= 0) {
    throw new AppError('INVALID_QUANTITY', 'quantity must be a positive number', 422);
  }
  return number;
}

function mapImage(image) {
  if (!image?.url) {
    return null;
  }
  return {
    url: image.url,
    publicId: image.publicId || null,
    fileName: image.fileName || null,
    mimeType: image.mimeType || null,
    uploadedAt: image.uploadedAt ? new Date(image.uploadedAt).toISOString() : null,
  };
}

function mapWarehouseRef(doc) {
  if (!doc) {
    return null;
  }
  if (typeof doc === 'string' || doc._bsontype === 'ObjectId') {
    return { id: toId(doc), name: null, code: null };
  }
  return {
    id: toId(doc._id || doc.id),
    name: doc.name || null,
    code: doc.code || null,
  };
}

function mapUserRef(doc) {
  if (!doc) {
    return null;
  }
  if (typeof doc === 'string' || doc._bsontype === 'ObjectId') {
    return { id: toId(doc), name: null };
  }
  return {
    id: toId(doc._id || doc.id),
    name: displayUserName(doc) || doc.userName || null,
  };
}

class InventoryService {
  _assertPermission(auth, permission) {
    if (!auth?.permissions?.includes(permission)) {
      throw new ForbiddenError('You do not have permission to perform this action');
    }
  }

  _assertAnyPermission(auth, permissions) {
    const hasAny = permissions.some((permission) => auth?.permissions?.includes(permission));
    if (!hasAny) {
      throw new ForbiddenError('You do not have permission to perform this action');
    }
  }

  _mapWarehouse(doc) {
    return {
      id: toId(doc._id),
      companyId: toId(doc.companyId),
      name: doc.name,
      code: doc.code,
      address: doc.address || null,
      description: doc.description || null,
      isActive: doc.isActive !== false,
      createdAt: doc.createdAt ? new Date(doc.createdAt).toISOString() : null,
      updatedAt: doc.updatedAt ? new Date(doc.updatedAt).toISOString() : null,
    };
  }

  _mapSparePart(doc) {
    const currentQuantity = Number(doc.currentQuantity) || 0;
    const minimumQuantity = Number(doc.minimumQuantity) || 0;
    let stockStatus = 'IN_STOCK';
    if (currentQuantity <= 0) {
      stockStatus = 'OUT_OF_STOCK';
    } else if (currentQuantity <= minimumQuantity) {
      stockStatus = 'LOW_STOCK';
    }

    return {
      id: toId(doc._id),
      companyId: toId(doc.companyId),
      partNumber: doc.partNumber,
      name: doc.name,
      category: doc.category || null,
      description: doc.description || null,
      unit: doc.unit || 'pcs',
      currentQuantity,
      minimumQuantity,
      stockStatus,
      image: mapImage(doc.image),
      barcode: doc.barcode || null,
      isActive: doc.isActive !== false,
      createdAt: doc.createdAt ? new Date(doc.createdAt).toISOString() : null,
      updatedAt: doc.updatedAt ? new Date(doc.updatedAt).toISOString() : null,
    };
  }

  _mapMovement(doc) {
    const sparePart =
      doc.sparePartId && typeof doc.sparePartId === 'object' && doc.sparePartId.partNumber
        ? {
            id: toId(doc.sparePartId._id),
            partNumber: doc.sparePartId.partNumber,
            name: doc.sparePartId.name,
            unit: doc.sparePartId.unit || 'pcs',
          }
        : {
            id: toId(doc.sparePartId),
            partNumber: null,
            name: null,
            unit: null,
          };

    return {
      id: toId(doc._id),
      companyId: toId(doc.companyId),
      type: doc.type,
      quantity: Number(doc.quantity) || 0,
      quantityDelta: Number(doc.quantityDelta) || 0,
      quantityBefore: Number(doc.quantityBefore) || 0,
      quantityAfter: Number(doc.quantityAfter) || 0,
      sparePart,
      warehouse: mapWarehouseRef(doc.warehouseId),
      fromWarehouse: mapWarehouseRef(doc.fromWarehouseId),
      toWarehouse: mapWarehouseRef(doc.toWarehouseId),
      user: mapUserRef(doc.userId) || {
        id: toId(doc.userId),
        name: doc.userName || null,
      },
      movementDate: doc.movementDate
        ? new Date(doc.movementDate).toISOString()
        : null,
      reason: doc.reason || null,
      notes: doc.notes || null,
      createdAt: doc.createdAt ? new Date(doc.createdAt).toISOString() : null,
    };
  }

  async _getWarehouseOrThrow(companyId, warehouseId) {
    const warehouse = await Warehouse.findOne({
      _id: warehouseId,
      companyId,
      deletedAt: null,
    });
    if (!warehouse) {
      throw new NotFoundError('Warehouse');
    }
    return warehouse;
  }

  async _getSparePartOrThrow(companyId, sparePartId) {
    const part = await SparePart.findOne({
      _id: sparePartId,
      companyId,
      deletedAt: null,
    });
    if (!part) {
      throw new NotFoundError('Spare part');
    }
    return part;
  }

  async _logAudit(user, auth, { action, resourceType, resourceId, metadata }) {
    await auditService.log({
      companyId: user.companyId,
      actorId: auth.userId,
      actorRole: auth.roles?.[0] || null,
      action,
      module: 'inventory',
      resourceType,
      resourceId,
      metadata,
    });
  }

  // ─── Dashboard ────────────────────────────────────────────────────────────

  async getDashboard(user, auth) {
    this._assertPermission(auth, PERMISSIONS.INVENTORY_VIEW);

    const companyId = user.companyId;
    const baseFilter = { companyId, deletedAt: null, isActive: true };

    const [totalParts, lowStock, outOfStock, recentMovements] = await Promise.all([
      SparePart.countDocuments(baseFilter),
      SparePart.countDocuments({
        ...baseFilter,
        $expr: {
          $and: [
            { $gt: ['$currentQuantity', 0] },
            { $lte: ['$currentQuantity', '$minimumQuantity'] },
          ],
        },
      }),
      SparePart.countDocuments({
        ...baseFilter,
        currentQuantity: { $lte: 0 },
      }),
      StockMovement.find({ companyId })
        .populate('sparePartId', 'partNumber name unit')
        .populate('warehouseId', 'name code')
        .populate('fromWarehouseId', 'name code')
        .populate('toWarehouseId', 'name code')
        .populate('userId', 'firstName lastName email')
        .sort({ movementDate: -1, createdAt: -1 })
        .limit(10),
    ]);

    return {
      totalParts,
      lowStock,
      outOfStock,
      recentMovements: recentMovements.map((item) => this._mapMovement(item)),
    };
  }

  // ─── Warehouses ───────────────────────────────────────────────────────────

  async listWarehouses(user, auth, { page = 1, limit = 20, search, isActive } = {}) {
    this._assertPermission(auth, PERMISSIONS.INVENTORY_VIEW);

    const filter = { companyId: user.companyId, deletedAt: null };
    const activeFilter = parseBoolean(isActive);
    if (activeFilter !== undefined) {
      filter.isActive = activeFilter;
    }
    if (search) {
      const regex = new RegExp(escapeRegex(search), 'i');
      filter.$or = [{ name: regex }, { code: regex }, { address: regex }];
    }

    const skip = (page - 1) * limit;
    const [items, total] = await Promise.all([
      Warehouse.find(filter).sort({ name: 1 }).skip(skip).limit(limit),
      Warehouse.countDocuments(filter),
    ]);

    return {
      items: items.map((item) => this._mapWarehouse(item)),
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.max(1, Math.ceil(total / limit)),
      },
    };
  }

  async getWarehouseById(user, auth, id) {
    this._assertPermission(auth, PERMISSIONS.INVENTORY_VIEW);
    const warehouse = await this._getWarehouseOrThrow(user.companyId, id);
    return this._mapWarehouse(warehouse);
  }

  async createWarehouse(user, auth, payload) {
    this._assertPermission(auth, PERMISSIONS.INVENTORY_CREATE);

    const code = String(payload.code || '')
      .trim()
      .toUpperCase();
    const existing = await Warehouse.findOne({
      companyId: user.companyId,
      code,
      deletedAt: null,
    });
    if (existing) {
      throw new ConflictError('A warehouse with this code already exists');
    }

    const warehouse = await Warehouse.create({
      companyId: user.companyId,
      name: String(payload.name).trim(),
      code,
      address: payload.address?.toString?.()?.trim?.() || null,
      description: payload.description?.toString?.()?.trim?.() || null,
      isActive: parseBoolean(payload.isActive, true),
    });

    await this._logAudit(user, auth, {
      action: 'warehouse.create',
      resourceType: 'warehouse',
      resourceId: warehouse._id,
      metadata: { code: warehouse.code, name: warehouse.name },
    });

    return this._mapWarehouse(warehouse);
  }

  async updateWarehouse(user, auth, id, payload) {
    this._assertPermission(auth, PERMISSIONS.INVENTORY_UPDATE);

    const warehouse = await this._getWarehouseOrThrow(user.companyId, id);

    if (payload.code !== undefined && payload.code !== null && payload.code !== '') {
      const code = String(payload.code).trim().toUpperCase();
      if (code !== warehouse.code) {
        const existing = await Warehouse.findOne({
          companyId: user.companyId,
          code,
          deletedAt: null,
          _id: { $ne: warehouse._id },
        });
        if (existing) {
          throw new ConflictError('A warehouse with this code already exists');
        }
        warehouse.code = code;
      }
    }

    if (payload.name !== undefined) {
      warehouse.name = String(payload.name).trim();
    }
    if (payload.address !== undefined) {
      warehouse.address = payload.address?.toString?.()?.trim?.() || null;
    }
    if (payload.description !== undefined) {
      warehouse.description = payload.description?.toString?.()?.trim?.() || null;
    }
    if (payload.isActive !== undefined) {
      warehouse.isActive = parseBoolean(payload.isActive, warehouse.isActive);
    }

    await warehouse.save();

    await this._logAudit(user, auth, {
      action: 'warehouse.update',
      resourceType: 'warehouse',
      resourceId: warehouse._id,
      metadata: { code: warehouse.code },
    });

    return this._mapWarehouse(warehouse);
  }

  async deleteWarehouse(user, auth, id) {
    this._assertPermission(auth, PERMISSIONS.INVENTORY_DELETE);

    const warehouse = await this._getWarehouseOrThrow(user.companyId, id);
    warehouse.deletedAt = new Date();
    warehouse.isActive = false;
    await warehouse.save();

    await this._logAudit(user, auth, {
      action: 'warehouse.delete',
      resourceType: 'warehouse',
      resourceId: warehouse._id,
      metadata: { code: warehouse.code },
    });

    return this._mapWarehouse(warehouse);
  }

  // ─── Spare Parts ──────────────────────────────────────────────────────────

  async listSpareParts(
    user,
    auth,
    { page = 1, limit = 20, search, category, stockStatus, isActive } = {}
  ) {
    this._assertPermission(auth, PERMISSIONS.INVENTORY_VIEW);

    const filter = { companyId: user.companyId, deletedAt: null };
    const activeFilter = parseBoolean(isActive);
    if (activeFilter !== undefined) {
      filter.isActive = activeFilter;
    }
    if (category) {
      filter.category = String(category).trim();
    }
    if (search) {
      const regex = new RegExp(escapeRegex(search), 'i');
      filter.$or = [
        { name: regex },
        { partNumber: regex },
        { barcode: regex },
        { category: regex },
      ];
    }

    const normalizedStatus = stockStatus
      ? String(stockStatus).toUpperCase()
      : null;
    if (normalizedStatus === 'OUT_OF_STOCK') {
      filter.currentQuantity = { $lte: 0 };
    } else if (normalizedStatus === 'LOW_STOCK') {
      filter.$expr = {
        $and: [
          { $gt: ['$currentQuantity', 0] },
          { $lte: ['$currentQuantity', '$minimumQuantity'] },
        ],
      };
    } else if (normalizedStatus === 'IN_STOCK') {
      filter.$expr = {
        $gt: ['$currentQuantity', '$minimumQuantity'],
      };
    }

    const skip = (page - 1) * limit;
    const [items, total] = await Promise.all([
      SparePart.find(filter).sort({ name: 1 }).skip(skip).limit(limit),
      SparePart.countDocuments(filter),
    ]);

    return {
      items: items.map((item) => this._mapSparePart(item)),
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.max(1, Math.ceil(total / limit)),
      },
    };
  }

  async getSparePartById(user, auth, id) {
    this._assertPermission(auth, PERMISSIONS.INVENTORY_VIEW);
    const part = await this._getSparePartOrThrow(user.companyId, id);
    return this._mapSparePart(part);
  }

  async createSparePart(user, auth, payload, file = null) {
    this._assertPermission(auth, PERMISSIONS.INVENTORY_CREATE);

    const partNumber = String(payload.partNumber || '')
      .trim()
      .toUpperCase();
    const existing = await SparePart.findOne({
      companyId: user.companyId,
      partNumber,
      deletedAt: null,
    });
    if (existing) {
      throw new ConflictError('A spare part with this part number already exists');
    }

    let image = null;
    if (file?.buffer) {
      const uploaded = await uploadSparePartImageBuffer(file.buffer, {
        companyId: toId(user.companyId),
        partNumber,
      });
      image = {
        url: uploaded.url,
        publicId: uploaded.publicId,
        fileName: file.originalname || null,
        mimeType: file.mimetype || null,
        uploadedAt: new Date(),
      };
    }

    const part = await SparePart.create({
      companyId: user.companyId,
      partNumber,
      name: String(payload.name).trim(),
      category: payload.category?.toString?.()?.trim?.() || null,
      description: payload.description?.toString?.()?.trim?.() || null,
      unit: payload.unit?.toString?.()?.trim?.() || 'pcs',
      currentQuantity: parseNonNegativeNumber(
        payload.currentQuantity ?? 0,
        'currentQuantity'
      ),
      minimumQuantity: parseNonNegativeNumber(
        payload.minimumQuantity ?? 0,
        'minimumQuantity'
      ),
      barcode: payload.barcode?.toString?.()?.trim?.() || null,
      image,
      isActive: parseBoolean(payload.isActive, true),
    });

    await this._logAudit(user, auth, {
      action: 'spare_part.create',
      resourceType: 'spare_part',
      resourceId: part._id,
      metadata: { partNumber: part.partNumber, name: part.name },
    });

    return this._mapSparePart(part);
  }

  async updateSparePart(user, auth, id, payload, file = null) {
    this._assertPermission(auth, PERMISSIONS.INVENTORY_UPDATE);

    const part = await this._getSparePartOrThrow(user.companyId, id);

    if (
      payload.partNumber !== undefined &&
      payload.partNumber !== null &&
      payload.partNumber !== ''
    ) {
      const partNumber = String(payload.partNumber).trim().toUpperCase();
      if (partNumber !== part.partNumber) {
        const existing = await SparePart.findOne({
          companyId: user.companyId,
          partNumber,
          deletedAt: null,
          _id: { $ne: part._id },
        });
        if (existing) {
          throw new ConflictError(
            'A spare part with this part number already exists'
          );
        }
        part.partNumber = partNumber;
      }
    }

    if (payload.name !== undefined) {
      part.name = String(payload.name).trim();
    }
    if (payload.category !== undefined) {
      part.category = payload.category?.toString?.()?.trim?.() || null;
    }
    if (payload.description !== undefined) {
      part.description = payload.description?.toString?.()?.trim?.() || null;
    }
    if (payload.unit !== undefined) {
      part.unit = payload.unit?.toString?.()?.trim?.() || part.unit;
    }
    if (payload.minimumQuantity !== undefined) {
      part.minimumQuantity = parseNonNegativeNumber(
        payload.minimumQuantity,
        'minimumQuantity'
      );
    }
    if (payload.barcode !== undefined) {
      part.barcode = payload.barcode?.toString?.()?.trim?.() || null;
    }
    if (payload.isActive !== undefined) {
      part.isActive = parseBoolean(payload.isActive, part.isActive);
    }

    // Quantity is managed via stock movements only (except initial create).
    if (payload.currentQuantity !== undefined) {
      throw new AppError(
        'QUANTITY_LOCKED',
        'Use stock movements to change current quantity',
        422
      );
    }

    if (file?.buffer) {
      const uploaded = await uploadSparePartImageBuffer(file.buffer, {
        companyId: toId(user.companyId),
        partNumber: part.partNumber,
      });
      part.image = {
        url: uploaded.url,
        publicId: uploaded.publicId,
        fileName: file.originalname || null,
        mimeType: file.mimetype || null,
        uploadedAt: new Date(),
      };
    } else if (parseBoolean(payload.removeImage, false)) {
      part.image = null;
    }

    await part.save();

    await this._logAudit(user, auth, {
      action: 'spare_part.update',
      resourceType: 'spare_part',
      resourceId: part._id,
      metadata: { partNumber: part.partNumber },
    });

    return this._mapSparePart(part);
  }

  async deleteSparePart(user, auth, id) {
    this._assertPermission(auth, PERMISSIONS.INVENTORY_DELETE);

    const part = await this._getSparePartOrThrow(user.companyId, id);
    part.deletedAt = new Date();
    part.isActive = false;
    await part.save();

    await this._logAudit(user, auth, {
      action: 'spare_part.delete',
      resourceType: 'spare_part',
      resourceId: part._id,
      metadata: { partNumber: part.partNumber },
    });

    return this._mapSparePart(part);
  }

  // ─── Stock Movements ──────────────────────────────────────────────────────

  async listMovements(
    user,
    auth,
    { page = 1, limit = 20, sparePartId, type, warehouseId, search } = {}
  ) {
    this._assertPermission(auth, PERMISSIONS.INVENTORY_VIEW);

    const filter = { companyId: user.companyId };
    if (sparePartId) {
      filter.sparePartId = sparePartId;
    }
    if (type) {
      const normalized = String(type).toUpperCase();
      if (STOCK_MOVEMENT_TYPES.includes(normalized)) {
        filter.type = normalized;
      }
    }
    if (warehouseId) {
      filter.$or = [
        { warehouseId },
        { fromWarehouseId: warehouseId },
        { toWarehouseId: warehouseId },
      ];
    }
    if (search) {
      const regex = new RegExp(escapeRegex(search), 'i');
      filter.$or = [
        ...(filter.$or || []),
        { reason: regex },
        { notes: regex },
        { userName: regex },
      ];
    }

    const skip = (page - 1) * limit;
    const [items, total] = await Promise.all([
      StockMovement.find(filter)
        .populate('sparePartId', 'partNumber name unit')
        .populate('warehouseId', 'name code')
        .populate('fromWarehouseId', 'name code')
        .populate('toWarehouseId', 'name code')
        .populate('userId', 'firstName lastName email')
        .sort({ movementDate: -1, createdAt: -1 })
        .skip(skip)
        .limit(limit),
      StockMovement.countDocuments(filter),
    ]);

    return {
      items: items.map((item) => this._mapMovement(item)),
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.max(1, Math.ceil(total / limit)),
      },
    };
  }

  async _createMovement(user, auth, {
    type,
    sparePartId,
    quantity,
    warehouseId = null,
    fromWarehouseId = null,
    toWarehouseId = null,
    reason = null,
    notes = null,
    movementDate,
    quantityDelta,
  }) {
    this._assertPermission(auth, PERMISSIONS.INVENTORY_STOCK_MANAGE);

    if (!STOCK_MOVEMENT_TYPES.includes(type)) {
      throw new AppError('INVALID_MOVEMENT_TYPE', 'Invalid stock movement type', 422);
    }

    const part = await this._getSparePartOrThrow(user.companyId, sparePartId);
    if (!part.isActive) {
      throw new AppError('PART_INACTIVE', 'Cannot move stock for an inactive part', 422);
    }

    if (warehouseId) {
      await this._getWarehouseOrThrow(user.companyId, warehouseId);
    }
    if (fromWarehouseId) {
      await this._getWarehouseOrThrow(user.companyId, fromWarehouseId);
    }
    if (toWarehouseId) {
      await this._getWarehouseOrThrow(user.companyId, toWarehouseId);
    }

    const qty = parsePositiveQuantity(quantity);
    const before = Number(part.currentQuantity) || 0;
    const delta = Number(quantityDelta);
    const after = before + delta;

    if (after < 0) {
      throw new AppError(
        'INSUFFICIENT_STOCK',
        'Insufficient stock for this movement',
        422,
        { available: before, requested: qty }
      );
    }

    part.currentQuantity = after;
    await part.save();

    const movement = await StockMovement.create({
      companyId: user.companyId,
      sparePartId: part._id,
      type,
      quantity: qty,
      quantityDelta: delta,
      quantityBefore: before,
      quantityAfter: after,
      warehouseId: warehouseId || null,
      fromWarehouseId: fromWarehouseId || null,
      toWarehouseId: toWarehouseId || null,
      userId: auth.userId,
      userName: displayUserName(user),
      movementDate: parseOptionalDate(movementDate),
      reason: reason?.toString?.()?.trim?.() || null,
      notes: notes?.toString?.()?.trim?.() || null,
    });

    await this._logAudit(user, auth, {
      action: `stock.${type.toLowerCase()}`,
      resourceType: 'stock_movement',
      resourceId: movement._id,
      metadata: {
        sparePartId: toId(part._id),
        partNumber: part.partNumber,
        quantity: qty,
        quantityBefore: before,
        quantityAfter: after,
      },
    });

    const populated = await StockMovement.findById(movement._id)
      .populate('sparePartId', 'partNumber name unit')
      .populate('warehouseId', 'name code')
      .populate('fromWarehouseId', 'name code')
      .populate('toWarehouseId', 'name code')
      .populate('userId', 'firstName lastName email');

    return {
      movement: this._mapMovement(populated),
      sparePart: this._mapSparePart(part),
    };
  }

  async stockIn(user, auth, payload) {
    if (!payload.warehouseId) {
      throw new AppError('WAREHOUSE_REQUIRED', 'warehouseId is required for stock in', 422);
    }
    return this._createMovement(user, auth, {
      type: 'STOCK_IN',
      sparePartId: payload.sparePartId,
      quantity: payload.quantity,
      warehouseId: payload.warehouseId,
      reason: payload.reason,
      notes: payload.notes,
      movementDate: payload.movementDate,
      quantityDelta: parsePositiveQuantity(payload.quantity),
    });
  }

  async stockOut(user, auth, payload) {
    if (!payload.warehouseId) {
      throw new AppError('WAREHOUSE_REQUIRED', 'warehouseId is required for stock out', 422);
    }
    const qty = parsePositiveQuantity(payload.quantity);
    return this._createMovement(user, auth, {
      type: 'STOCK_OUT',
      sparePartId: payload.sparePartId,
      quantity: qty,
      warehouseId: payload.warehouseId,
      reason: payload.reason,
      notes: payload.notes,
      movementDate: payload.movementDate,
      quantityDelta: -qty,
    });
  }

  async transfer(user, auth, payload) {
    if (!payload.fromWarehouseId || !payload.toWarehouseId) {
      throw new AppError(
        'WAREHOUSE_REQUIRED',
        'fromWarehouseId and toWarehouseId are required for transfer',
        422
      );
    }
    if (String(payload.fromWarehouseId) === String(payload.toWarehouseId)) {
      throw new AppError(
        'INVALID_TRANSFER',
        'fromWarehouseId and toWarehouseId must be different',
        422
      );
    }
    const qty = parsePositiveQuantity(payload.quantity);
    return this._createMovement(user, auth, {
      type: 'TRANSFER',
      sparePartId: payload.sparePartId,
      quantity: qty,
      fromWarehouseId: payload.fromWarehouseId,
      toWarehouseId: payload.toWarehouseId,
      reason: payload.reason,
      notes: payload.notes,
      movementDate: payload.movementDate,
      quantityDelta: 0,
    });
  }

  async adjustment(user, auth, payload) {
    if (!payload.warehouseId) {
      throw new AppError(
        'WAREHOUSE_REQUIRED',
        'warehouseId is required for adjustment',
        422
      );
    }
    if (!payload.reason?.toString?.()?.trim?.()) {
      throw new AppError('REASON_REQUIRED', 'reason is required for adjustment', 422);
    }

    const qty = parsePositiveQuantity(payload.quantity);
    const direction = String(payload.direction || 'INCREASE').toUpperCase();
    if (!['INCREASE', 'DECREASE'].includes(direction)) {
      throw new AppError(
        'INVALID_DIRECTION',
        'direction must be INCREASE or DECREASE',
        422
      );
    }

    return this._createMovement(user, auth, {
      type: 'ADJUSTMENT',
      sparePartId: payload.sparePartId,
      quantity: qty,
      warehouseId: payload.warehouseId,
      reason: payload.reason,
      notes: payload.notes,
      movementDate: payload.movementDate,
      quantityDelta: direction === 'INCREASE' ? qty : -qty,
    });
  }
}

export default new InventoryService();
