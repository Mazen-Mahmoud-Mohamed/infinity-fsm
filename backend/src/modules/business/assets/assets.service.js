import AssetCategory from './models/assetCategory.model.js';
import Asset, { ASSET_STATUSES } from './models/asset.model.js';
import AssetHistory, {
  ASSET_HISTORY_TYPES,
} from './models/assetHistory.model.js';
import Branch from '../../core/organization/models/branch.model.js';
import { uploadAssetImageBuffer } from './assets.upload.js';
import PERMISSIONS from '../../../shared/constants/permissions.constants.js';
import AppError, {
  ConflictError,
  ForbiddenError,
  NotFoundError,
} from '../../../shared/errors/AppError.js';
import auditService from '../../core/audit/audit.service.js';

const WARRANTY_SOON_DAYS = 30;

function escapeRegex(value) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function toId(value) {
  return value?.toString?.() ?? value ?? null;
}

function displayUserName(user) {
  if (!user) return null;
  const full = [user.firstName, user.lastName].filter(Boolean).join(' ').trim();
  return full || user.email || user.username || null;
}

function parseBoolean(value, fallback = undefined) {
  if (value === undefined || value === null || value === '') return fallback;
  if (typeof value === 'boolean') return value;
  const normalized = String(value).toLowerCase();
  if (['true', '1', 'yes'].includes(normalized)) return true;
  if (['false', '0', 'no'].includes(normalized)) return false;
  return fallback;
}

function parseOptionalDate(value, fieldName) {
  if (value === undefined || value === null || value === '') return null;
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) {
    throw new AppError('INVALID_DATE', `${fieldName} must be a valid ISO date`, 422);
  }
  return date;
}

function parseOptionalObjectId(value) {
  if (value === undefined || value === null || value === '') return null;
  return String(value);
}

function parseGps(raw) {
  if (raw === undefined || raw === null || raw === '') {
    return { latitude: null, longitude: null, accuracy: null, address: null };
  }
  let value = raw;
  if (typeof raw === 'string') {
    try {
      value = JSON.parse(raw);
    } catch {
      return {
        latitude: null,
        longitude: null,
        accuracy: null,
        address: raw.trim() || null,
      };
    }
  }
  if (typeof value !== 'object') {
    return { latitude: null, longitude: null, accuracy: null, address: null };
  }
  return {
    latitude:
      value.latitude !== undefined && value.latitude !== ''
        ? Number(value.latitude)
        : null,
    longitude:
      value.longitude !== undefined && value.longitude !== ''
        ? Number(value.longitude)
        : null,
    accuracy:
      value.accuracy !== undefined && value.accuracy !== ''
        ? Number(value.accuracy)
        : null,
    address: value.address?.toString?.()?.trim?.() || null,
  };
}

function parseLocation(raw) {
  if (raw === undefined || raw === null || raw === '') {
    return {
      branchId: null,
      regionId: null,
      cityId: null,
      branchName: null,
      regionName: null,
      cityName: null,
    };
  }
  let value = raw;
  if (typeof raw === 'string') {
    try {
      value = JSON.parse(raw);
    } catch {
      return {
        branchId: null,
        regionId: null,
        cityId: null,
        branchName: null,
        regionName: null,
        cityName: null,
      };
    }
  }
  if (typeof value !== 'object') {
    return {
      branchId: null,
      regionId: null,
      cityId: null,
      branchName: null,
      regionName: null,
      cityName: null,
    };
  }
  return {
    branchId: parseOptionalObjectId(value.branchId),
    regionId: parseOptionalObjectId(value.regionId),
    cityId: parseOptionalObjectId(value.cityId),
    branchName: value.branchName?.toString?.()?.trim?.() || null,
    regionName: value.regionName?.toString?.()?.trim?.() || null,
    cityName: value.cityName?.toString?.()?.trim?.() || null,
  };
}

function normalizeStatus(status, { required = false } = {}) {
  if (status === undefined || status === null || status === '') {
    if (required) {
      throw new AppError('INVALID_STATUS', 'status is required', 422);
    }
    return null;
  }
  const normalized = String(status).toUpperCase();
  if (!ASSET_STATUSES.includes(normalized)) {
    throw new AppError(
      'INVALID_STATUS',
      `status must be one of: ${ASSET_STATUSES.join(', ')}`,
      422
    );
  }
  return normalized;
}

function mapImage(image) {
  if (!image?.url) return null;
  return {
    url: image.url,
    publicId: image.publicId || null,
    fileName: image.fileName || null,
    mimeType: image.mimeType || null,
    uploadedAt: image.uploadedAt ? new Date(image.uploadedAt).toISOString() : null,
  };
}

class AssetsService {
  _assertPermission(auth, permission) {
    if (!auth?.permissions?.includes(permission)) {
      throw new ForbiddenError('You do not have permission to perform this action');
    }
  }

  _mapCategory(doc) {
    return {
      id: toId(doc._id),
      companyId: toId(doc.companyId),
      name: doc.name,
      code: doc.code,
      description: doc.description || null,
      icon: doc.icon || null,
      isActive: doc.isActive !== false,
      createdAt: doc.createdAt ? new Date(doc.createdAt).toISOString() : null,
      updatedAt: doc.updatedAt ? new Date(doc.updatedAt).toISOString() : null,
    };
  }

  _mapAsset(doc) {
    const category =
      doc.categoryId && typeof doc.categoryId === 'object' && doc.categoryId.name
        ? {
            id: toId(doc.categoryId._id),
            name: doc.categoryId.name,
            code: doc.categoryId.code,
            icon: doc.categoryId.icon || null,
          }
        : doc.categoryId
          ? { id: toId(doc.categoryId), name: null, code: null, icon: null }
          : null;

    const location = doc.location || {};
    return {
      id: toId(doc._id),
      companyId: toId(doc.companyId),
      assetNumber: doc.assetNumber,
      name: doc.name,
      category,
      serialNumber: doc.serialNumber || null,
      manufacturer: doc.manufacturer || null,
      model: doc.model || null,
      installationDate: doc.installationDate
        ? new Date(doc.installationDate).toISOString()
        : null,
      warrantyExpiry: doc.warrantyExpiry
        ? new Date(doc.warrantyExpiry).toISOString()
        : null,
      status: doc.status || 'ACTIVE',
      location: {
        branchId: toId(location.branchId),
        regionId: toId(location.regionId),
        cityId: toId(location.cityId),
        branchName: location.branchName || null,
        regionName: location.regionName || null,
        cityName: location.cityName || null,
      },
      gps: {
        latitude: doc.gps?.latitude ?? null,
        longitude: doc.gps?.longitude ?? null,
        accuracy: doc.gps?.accuracy ?? null,
        address: doc.gps?.address || null,
      },
      qrCode: doc.qrCode || null,
      barcode: doc.barcode || null,
      customer: doc.customer || null,
      notes: doc.notes || null,
      image: mapImage(doc.image),
      createdAt: doc.createdAt ? new Date(doc.createdAt).toISOString() : null,
      updatedAt: doc.updatedAt ? new Date(doc.updatedAt).toISOString() : null,
    };
  }

  _mapHistory(doc) {
    return {
      id: toId(doc._id),
      companyId: toId(doc.companyId),
      assetId: toId(doc.assetId),
      type: doc.type,
      title: doc.title || null,
      description: doc.description || null,
      fromStatus: doc.fromStatus || null,
      toStatus: doc.toStatus || null,
      eventDate: doc.eventDate ? new Date(doc.eventDate).toISOString() : null,
      user: {
        id: toId(doc.userId?._id || doc.userId),
        name:
          displayUserName(doc.userId) ||
          doc.userName ||
          null,
      },
      metadata: doc.metadata || null,
      createdAt: doc.createdAt ? new Date(doc.createdAt).toISOString() : null,
    };
  }

  async _getCategoryOrThrow(companyId, id) {
    const category = await AssetCategory.findOne({
      _id: id,
      companyId,
      deletedAt: null,
    });
    if (!category) throw new NotFoundError('Asset category');
    return category;
  }

  async _getAssetOrThrow(companyId, id) {
    const asset = await Asset.findOne({
      _id: id,
      companyId,
      deletedAt: null,
    }).populate('categoryId', 'name code icon');
    if (!asset) throw new NotFoundError('Asset');
    return asset;
  }

  async _resolveLocation(companyId, locationInput) {
    const location = { ...locationInput };
    if (location.branchId) {
      const branch = await Branch.findOne({
        _id: location.branchId,
        companyId,
        deletedAt: null,
      });
      if (!branch) {
        throw new AppError('INVALID_BRANCH', 'branchId is invalid', 422);
      }
      if (!location.branchName) {
        location.branchName = branch.name;
      }
    }
    return location;
  }

  async _logAudit(user, auth, { action, resourceType, resourceId, metadata }) {
    await auditService.log({
      companyId: user.companyId,
      actorId: auth.userId,
      actorRole: auth.roles?.[0] || null,
      action,
      module: 'assets',
      resourceType,
      resourceId,
      metadata,
    });
  }

  async _addHistory(user, auth, {
    assetId,
    type,
    title = null,
    description = null,
    fromStatus = null,
    toStatus = null,
    eventDate = null,
    metadata = null,
  }) {
    return AssetHistory.create({
      companyId: user.companyId,
      assetId,
      type,
      title,
      description,
      fromStatus,
      toStatus,
      eventDate: eventDate ? new Date(eventDate) : new Date(),
      userId: auth.userId,
      userName: displayUserName(user),
      metadata,
    });
  }

  // ─── Dashboard ────────────────────────────────────────────────────────────

  async getDashboard(user, auth) {
    this._assertPermission(auth, PERMISSIONS.ASSETS_VIEW);

    const companyId = user.companyId;
    const base = { companyId, deletedAt: null };
    const soon = new Date();
    soon.setDate(soon.getDate() + WARRANTY_SOON_DAYS);
    const now = new Date();

    const [totalAssets, active, underMaintenance, retired, warrantyExpiringSoon] =
      await Promise.all([
        Asset.countDocuments(base),
        Asset.countDocuments({ ...base, status: 'ACTIVE' }),
        Asset.countDocuments({ ...base, status: 'MAINTENANCE' }),
        Asset.countDocuments({ ...base, status: 'RETIRED' }),
        Asset.countDocuments({
          ...base,
          warrantyExpiry: { $gte: now, $lte: soon },
          status: { $ne: 'RETIRED' },
        }),
      ]);

    return {
      totalAssets,
      active,
      underMaintenance,
      retired,
      warrantyExpiringSoon,
    };
  }

  // ─── Categories ───────────────────────────────────────────────────────────

  async listCategories(user, auth, { page = 1, limit = 20, search, isActive } = {}) {
    this._assertPermission(auth, PERMISSIONS.ASSETS_VIEW);

    const filter = { companyId: user.companyId, deletedAt: null };
    const activeFilter = parseBoolean(isActive);
    if (activeFilter !== undefined) filter.isActive = activeFilter;
    if (search) {
      const regex = new RegExp(escapeRegex(search), 'i');
      filter.$or = [{ name: regex }, { code: regex }, { description: regex }];
    }

    const skip = (page - 1) * limit;
    const [items, total] = await Promise.all([
      AssetCategory.find(filter).sort({ name: 1 }).skip(skip).limit(limit),
      AssetCategory.countDocuments(filter),
    ]);

    return {
      items: items.map((item) => this._mapCategory(item)),
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.max(1, Math.ceil(total / limit)),
      },
    };
  }

  async getCategoryById(user, auth, id) {
    this._assertPermission(auth, PERMISSIONS.ASSETS_VIEW);
    return this._mapCategory(await this._getCategoryOrThrow(user.companyId, id));
  }

  async createCategory(user, auth, payload) {
    this._assertPermission(auth, PERMISSIONS.ASSETS_CREATE);

    const code = String(payload.code || '').trim().toUpperCase();
    const existing = await AssetCategory.findOne({
      companyId: user.companyId,
      code,
      deletedAt: null,
    });
    if (existing) {
      throw new ConflictError('An asset category with this code already exists');
    }

    const category = await AssetCategory.create({
      companyId: user.companyId,
      name: String(payload.name).trim(),
      code,
      description: payload.description?.toString?.()?.trim?.() || null,
      icon: payload.icon?.toString?.()?.trim?.() || null,
      isActive: parseBoolean(payload.isActive, true),
    });

    await this._logAudit(user, auth, {
      action: 'asset_category.create',
      resourceType: 'asset_category',
      resourceId: category._id,
      metadata: { code: category.code },
    });

    return this._mapCategory(category);
  }

  async updateCategory(user, auth, id, payload) {
    this._assertPermission(auth, PERMISSIONS.ASSETS_UPDATE);
    const category = await this._getCategoryOrThrow(user.companyId, id);

    if (payload.code !== undefined && payload.code !== null && payload.code !== '') {
      const code = String(payload.code).trim().toUpperCase();
      if (code !== category.code) {
        const existing = await AssetCategory.findOne({
          companyId: user.companyId,
          code,
          deletedAt: null,
          _id: { $ne: category._id },
        });
        if (existing) {
          throw new ConflictError('An asset category with this code already exists');
        }
        category.code = code;
      }
    }

    if (payload.name !== undefined) category.name = String(payload.name).trim();
    if (payload.description !== undefined) {
      category.description = payload.description?.toString?.()?.trim?.() || null;
    }
    if (payload.icon !== undefined) {
      category.icon = payload.icon?.toString?.()?.trim?.() || null;
    }
    if (payload.isActive !== undefined) {
      category.isActive = parseBoolean(payload.isActive, category.isActive);
    }

    await category.save();
    await this._logAudit(user, auth, {
      action: 'asset_category.update',
      resourceType: 'asset_category',
      resourceId: category._id,
      metadata: { code: category.code },
    });
    return this._mapCategory(category);
  }

  async deleteCategory(user, auth, id) {
    this._assertPermission(auth, PERMISSIONS.ASSETS_DELETE);
    const category = await this._getCategoryOrThrow(user.companyId, id);

    const inUse = await Asset.countDocuments({
      companyId: user.companyId,
      categoryId: category._id,
      deletedAt: null,
    });
    if (inUse > 0) {
      throw new ConflictError('Cannot delete a category that is assigned to assets');
    }

    category.deletedAt = new Date();
    category.isActive = false;
    await category.save();

    await this._logAudit(user, auth, {
      action: 'asset_category.delete',
      resourceType: 'asset_category',
      resourceId: category._id,
      metadata: { code: category.code },
    });
    return this._mapCategory(category);
  }

  // ─── Assets ───────────────────────────────────────────────────────────────

  async listAssets(
    user,
    auth,
    { page = 1, limit = 20, search, status, categoryId, branchId } = {}
  ) {
    this._assertPermission(auth, PERMISSIONS.ASSETS_VIEW);

    const filter = { companyId: user.companyId, deletedAt: null };
    const normalizedStatus = normalizeStatus(status);
    if (normalizedStatus) filter.status = normalizedStatus;
    if (categoryId) filter.categoryId = categoryId;
    if (branchId) filter['location.branchId'] = branchId;
    if (search) {
      const regex = new RegExp(escapeRegex(search), 'i');
      filter.$or = [
        { name: regex },
        { assetNumber: regex },
        { serialNumber: regex },
        { barcode: regex },
        { qrCode: regex },
        { customer: regex },
        { manufacturer: regex },
        { model: regex },
      ];
    }

    const skip = (page - 1) * limit;
    const [items, total] = await Promise.all([
      Asset.find(filter)
        .populate('categoryId', 'name code icon')
        .sort({ updatedAt: -1 })
        .skip(skip)
        .limit(limit),
      Asset.countDocuments(filter),
    ]);

    return {
      items: items.map((item) => this._mapAsset(item)),
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.max(1, Math.ceil(total / limit)),
      },
    };
  }

  async getAssetById(user, auth, id) {
    this._assertPermission(auth, PERMISSIONS.ASSETS_VIEW);
    return this._mapAsset(await this._getAssetOrThrow(user.companyId, id));
  }

  async createAsset(user, auth, payload, file = null) {
    this._assertPermission(auth, PERMISSIONS.ASSETS_CREATE);

    const assetNumber = String(payload.assetNumber || '').trim().toUpperCase();
    const existing = await Asset.findOne({
      companyId: user.companyId,
      assetNumber,
      deletedAt: null,
    });
    if (existing) {
      throw new ConflictError('An asset with this asset number already exists');
    }

    const categoryId = parseOptionalObjectId(payload.categoryId);
    if (categoryId) {
      await this._getCategoryOrThrow(user.companyId, categoryId);
    }

    const location = await this._resolveLocation(
      user.companyId,
      parseLocation(payload.location)
    );

    // Also accept flat location fields from multipart forms.
    if (!location.branchId && payload.branchId) {
      location.branchId = parseOptionalObjectId(payload.branchId);
    }
    if (!location.regionName && payload.regionName) {
      location.regionName = String(payload.regionName).trim();
    }
    if (!location.cityName && payload.cityName) {
      location.cityName = String(payload.cityName).trim();
    }
    if (location.branchId && !location.branchName) {
      Object.assign(
        location,
        await this._resolveLocation(user.companyId, location)
      );
    }

    let image = null;
    if (file?.buffer) {
      const uploaded = await uploadAssetImageBuffer(file.buffer, {
        companyId: toId(user.companyId),
        assetNumber,
      });
      image = {
        url: uploaded.url,
        publicId: uploaded.publicId,
        fileName: file.originalname || null,
        mimeType: file.mimetype || null,
        uploadedAt: new Date(),
      };
    }

    const status = normalizeStatus(payload.status) || 'ACTIVE';
    const asset = await Asset.create({
      companyId: user.companyId,
      assetNumber,
      name: String(payload.name).trim(),
      categoryId,
      serialNumber: payload.serialNumber?.toString?.()?.trim?.() || null,
      manufacturer: payload.manufacturer?.toString?.()?.trim?.() || null,
      model: payload.model?.toString?.()?.trim?.() || null,
      installationDate: parseOptionalDate(payload.installationDate, 'installationDate'),
      warrantyExpiry: parseOptionalDate(payload.warrantyExpiry, 'warrantyExpiry'),
      status,
      location,
      gps: parseGps(payload.gps),
      qrCode: payload.qrCode?.toString?.()?.trim?.() || null,
      barcode: payload.barcode?.toString?.()?.trim?.() || null,
      customer: payload.customer?.toString?.()?.trim?.() || null,
      notes: payload.notes?.toString?.()?.trim?.() || null,
      image,
    });

    await this._addHistory(user, auth, {
      assetId: asset._id,
      type: 'CREATED',
      title: 'Asset created',
      toStatus: status,
      eventDate: asset.installationDate || new Date(),
    });

    if (asset.installationDate) {
      await this._addHistory(user, auth, {
        assetId: asset._id,
        type: 'INSTALLATION',
        title: 'Asset installed',
        eventDate: asset.installationDate,
      });
    }

    await this._logAudit(user, auth, {
      action: 'asset.create',
      resourceType: 'asset',
      resourceId: asset._id,
      metadata: { assetNumber: asset.assetNumber },
    });

    const populated = await Asset.findById(asset._id).populate(
      'categoryId',
      'name code icon'
    );
    return this._mapAsset(populated);
  }

  async updateAsset(user, auth, id, payload, file = null) {
    this._assertPermission(auth, PERMISSIONS.ASSETS_UPDATE);
    const asset = await this._getAssetOrThrow(user.companyId, id);
    const previousStatus = asset.status;

    if (
      payload.assetNumber !== undefined &&
      payload.assetNumber !== null &&
      payload.assetNumber !== ''
    ) {
      const assetNumber = String(payload.assetNumber).trim().toUpperCase();
      if (assetNumber !== asset.assetNumber) {
        const existing = await Asset.findOne({
          companyId: user.companyId,
          assetNumber,
          deletedAt: null,
          _id: { $ne: asset._id },
        });
        if (existing) {
          throw new ConflictError('An asset with this asset number already exists');
        }
        asset.assetNumber = assetNumber;
      }
    }

    if (payload.name !== undefined) asset.name = String(payload.name).trim();
    if (payload.categoryId !== undefined) {
      const categoryId = parseOptionalObjectId(payload.categoryId);
      if (categoryId) {
        await this._getCategoryOrThrow(user.companyId, categoryId);
      }
      asset.categoryId = categoryId;
    }
    if (payload.serialNumber !== undefined) {
      asset.serialNumber = payload.serialNumber?.toString?.()?.trim?.() || null;
    }
    if (payload.manufacturer !== undefined) {
      asset.manufacturer = payload.manufacturer?.toString?.()?.trim?.() || null;
    }
    if (payload.model !== undefined) {
      asset.model = payload.model?.toString?.()?.trim?.() || null;
    }
    if (payload.installationDate !== undefined) {
      asset.installationDate = parseOptionalDate(
        payload.installationDate,
        'installationDate'
      );
    }
    if (payload.warrantyExpiry !== undefined) {
      asset.warrantyExpiry = parseOptionalDate(
        payload.warrantyExpiry,
        'warrantyExpiry'
      );
    }

    const nextStatus = normalizeStatus(payload.status);
    if (nextStatus) asset.status = nextStatus;

    if (
      payload.location !== undefined ||
      payload.branchId !== undefined ||
      payload.regionName !== undefined ||
      payload.cityName !== undefined
    ) {
      const location = parseLocation(payload.location || asset.location);
      if (payload.branchId !== undefined) {
        location.branchId = parseOptionalObjectId(payload.branchId);
      }
      if (payload.regionName !== undefined) {
        location.regionName = payload.regionName?.toString?.()?.trim?.() || null;
      }
      if (payload.cityName !== undefined) {
        location.cityName = payload.cityName?.toString?.()?.trim?.() || null;
      }
      asset.location = await this._resolveLocation(user.companyId, location);
    }

    if (payload.gps !== undefined) {
      asset.gps = parseGps(payload.gps);
    }
    if (payload.qrCode !== undefined) {
      asset.qrCode = payload.qrCode?.toString?.()?.trim?.() || null;
    }
    if (payload.barcode !== undefined) {
      asset.barcode = payload.barcode?.toString?.()?.trim?.() || null;
    }
    if (payload.customer !== undefined) {
      asset.customer = payload.customer?.toString?.()?.trim?.() || null;
    }
    if (payload.notes !== undefined) {
      asset.notes = payload.notes?.toString?.()?.trim?.() || null;
    }

    if (file?.buffer) {
      const uploaded = await uploadAssetImageBuffer(file.buffer, {
        companyId: toId(user.companyId),
        assetNumber: asset.assetNumber,
      });
      asset.image = {
        url: uploaded.url,
        publicId: uploaded.publicId,
        fileName: file.originalname || null,
        mimeType: file.mimetype || null,
        uploadedAt: new Date(),
      };
    } else if (parseBoolean(payload.removeImage, false)) {
      asset.image = null;
    }

    await asset.save();

    if (nextStatus && nextStatus !== previousStatus) {
      await this._addHistory(user, auth, {
        assetId: asset._id,
        type: 'STATUS_CHANGE',
        title: `Status changed to ${nextStatus}`,
        fromStatus: previousStatus,
        toStatus: nextStatus,
      });
    } else {
      await this._addHistory(user, auth, {
        assetId: asset._id,
        type: 'UPDATED',
        title: 'Asset updated',
      });
    }

    await this._logAudit(user, auth, {
      action: 'asset.update',
      resourceType: 'asset',
      resourceId: asset._id,
      metadata: { assetNumber: asset.assetNumber },
    });

    const populated = await Asset.findById(asset._id).populate(
      'categoryId',
      'name code icon'
    );
    return this._mapAsset(populated);
  }

  async deleteAsset(user, auth, id) {
    this._assertPermission(auth, PERMISSIONS.ASSETS_DELETE);
    const asset = await this._getAssetOrThrow(user.companyId, id);
    asset.deletedAt = new Date();
    if (asset.status !== 'RETIRED') {
      const previous = asset.status;
      asset.status = 'RETIRED';
      await this._addHistory(user, auth, {
        assetId: asset._id,
        type: 'STATUS_CHANGE',
        title: 'Asset deleted / retired',
        fromStatus: previous,
        toStatus: 'RETIRED',
      });
    }
    await asset.save();

    await this._logAudit(user, auth, {
      action: 'asset.delete',
      resourceType: 'asset',
      resourceId: asset._id,
      metadata: { assetNumber: asset.assetNumber },
    });

    return this._mapAsset(asset);
  }

  // ─── History ──────────────────────────────────────────────────────────────

  async listHistory(
    user,
    auth,
    { page = 1, limit = 20, assetId, type, search } = {}
  ) {
    this._assertPermission(auth, PERMISSIONS.ASSETS_VIEW);

    const filter = { companyId: user.companyId };
    if (assetId) filter.assetId = assetId;
    if (type) {
      const normalized = String(type).toUpperCase();
      if (ASSET_HISTORY_TYPES.includes(normalized)) {
        filter.type = normalized;
      }
    }
    if (search) {
      const regex = new RegExp(escapeRegex(search), 'i');
      filter.$or = [{ title: regex }, { description: regex }, { userName: regex }];
    }

    const skip = (page - 1) * limit;
    const [items, total] = await Promise.all([
      AssetHistory.find(filter)
        .populate('userId', 'firstName lastName email')
        .sort({ eventDate: -1, createdAt: -1 })
        .skip(skip)
        .limit(limit),
      AssetHistory.countDocuments(filter),
    ]);

    return {
      items: items.map((item) => this._mapHistory(item)),
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.max(1, Math.ceil(total / limit)),
      },
    };
  }

  async addHistoryEvent(user, auth, payload) {
    this._assertPermission(auth, PERMISSIONS.ASSETS_UPDATE);

    const type = String(payload.type || '').toUpperCase();
    if (!ASSET_HISTORY_TYPES.includes(type)) {
      throw new AppError('INVALID_HISTORY_TYPE', 'Invalid asset history type', 422);
    }

    const asset = await this._getAssetOrThrow(user.companyId, payload.assetId);
    const previousStatus = asset.status;
    let toStatus = normalizeStatus(payload.toStatus);

    if (type === 'STATUS_CHANGE') {
      if (!toStatus) {
        throw new AppError('INVALID_STATUS', 'toStatus is required for status changes', 422);
      }
      asset.status = toStatus;
      await asset.save();
    } else if (type === 'MAINTENANCE' && payload.setStatus !== false) {
      toStatus = 'MAINTENANCE';
      asset.status = 'MAINTENANCE';
      await asset.save();
    }

    const history = await this._addHistory(user, auth, {
      assetId: asset._id,
      type,
      title: payload.title?.toString?.()?.trim?.() || type,
      description: payload.description?.toString?.()?.trim?.() || null,
      fromStatus: type === 'STATUS_CHANGE' || toStatus ? previousStatus : null,
      toStatus: toStatus || null,
      eventDate: parseOptionalDate(payload.eventDate, 'eventDate') || new Date(),
      metadata: payload.metadata || null,
    });

    if (toStatus && toStatus !== previousStatus && type !== 'STATUS_CHANGE') {
      await this._addHistory(user, auth, {
        assetId: asset._id,
        type: 'STATUS_CHANGE',
        title: `Status changed to ${toStatus}`,
        fromStatus: previousStatus,
        toStatus,
      });
    }

    await this._logAudit(user, auth, {
      action: 'asset.history.create',
      resourceType: 'asset_history',
      resourceId: history._id,
      metadata: { assetId: toId(asset._id), type },
    });

    const populated = await AssetHistory.findById(history._id).populate(
      'userId',
      'firstName lastName email'
    );

    return {
      history: this._mapHistory(populated),
      asset: this._mapAsset(await this._getAssetOrThrow(user.companyId, asset._id)),
    };
  }
}

export default new AssetsService();
