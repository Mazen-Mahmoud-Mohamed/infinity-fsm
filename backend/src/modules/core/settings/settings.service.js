import mongoose from 'mongoose';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import Company from '../organization/models/company.model.js';
import Setting from './models/setting.model.js';
import AppError, {
  ForbiddenError,
  NotFoundError,
} from '../../../shared/errors/AppError.js';
import PERMISSIONS from '../../../shared/constants/permissions.constants.js';
import config from '../../../config/index.js';
import { isCloudinaryReady } from '../../../config/cloudinary.config.js';
import { uploadCompanyLogoBuffer } from './settings.upload.js';
import auditService from '../audit/audit.service.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const WORKING_HOURS_START_KEY = 'working_hours.start';
const WORKING_HOURS_END_KEY = 'working_hours.end';
const WORKING_HOURS_TIMEZONE_KEY = 'working_hours.timezone';

function toId(value) {
  return value?.toString?.() ?? value ?? null;
}

function readBackendVersion() {
  try {
    const pkgPath = path.resolve(__dirname, '../../../../package.json');
    const raw = fs.readFileSync(pkgPath, 'utf8');
    const pkg = JSON.parse(raw);
    return pkg.version || '1.0.0';
  } catch {
    return '1.0.0';
  }
}

class SettingsService {
  _assertPermission(auth, permission) {
    if (!auth?.permissions?.includes(permission)) {
      throw new ForbiddenError('Missing required permissions', {
        requiredPermissions: [permission],
      });
    }
  }

  async _getSettingValue(companyId, key, fallback = null) {
    const doc = await Setting.findOne({ companyId, key }).lean();
    return doc?.value ?? fallback;
  }

  async _upsertSetting({ companyId, key, value, group, dataType, updatedBy }) {
    return Setting.findOneAndUpdate(
      { companyId, key },
      {
        $set: {
          value,
          group,
          dataType,
          updatedBy,
        },
        $setOnInsert: {
          companyId,
          key,
        },
      },
      { upsert: true, new: true }
    );
  }

  _mapOrganization(company, workingHours) {
    return {
      id: toId(company._id),
      name: company.name,
      slug: company.slug,
      logoUrl: company.logoUrl,
      contactEmail: company.contactEmail || null,
      contactPhone: company.contactPhone || null,
      address: {
        line1: company.address?.line1 || null,
        line2: company.address?.line2 || null,
        city: company.address?.city || null,
        governorate: company.address?.governorate || null,
        country: company.address?.country || null,
        postalCode: company.address?.postalCode || null,
      },
      timezone: company.timezone || workingHours.timezone || 'Asia/Baghdad',
      workingHours: {
        start: workingHours.start,
        end: workingHours.end,
        timezone: workingHours.timezone || company.timezone || 'Asia/Baghdad',
      },
      isActive: company.isActive !== false,
      updatedAt: company.updatedAt,
    };
  }

  async getOrganizationSettings(user, auth) {
    this._assertPermission(auth, PERMISSIONS.SETTINGS_VIEW);
    const companyId = user.companyId;
    const company = await Company.findById(companyId);
    if (!company) throw new NotFoundError('Company not found');

    const [start, end, timezone] = await Promise.all([
      this._getSettingValue(companyId, WORKING_HOURS_START_KEY, '09:00'),
      this._getSettingValue(companyId, WORKING_HOURS_END_KEY, '17:00'),
      this._getSettingValue(
        companyId,
        WORKING_HOURS_TIMEZONE_KEY,
        company.timezone || 'Asia/Baghdad'
      ),
    ]);

    return this._mapOrganization(company, { start, end, timezone });
  }

  async updateOrganizationSettings(user, auth, payload = {}) {
    this._assertPermission(auth, PERMISSIONS.SETTINGS_MANAGE);
    const companyId = user.companyId;
    const company = await Company.findById(companyId);
    if (!company) throw new NotFoundError('Company not found');

    if (payload.name !== undefined) {
      const name = String(payload.name).trim();
      if (!name) {
        throw new AppError('VALIDATION_ERROR', 'Company name is required', 422);
      }
      company.name = name;
    }

    if (payload.contactEmail !== undefined) {
      company.contactEmail = payload.contactEmail
        ? String(payload.contactEmail).trim().toLowerCase()
        : null;
    }

    if (payload.contactPhone !== undefined) {
      company.contactPhone = payload.contactPhone
        ? String(payload.contactPhone).trim()
        : null;
    }

    if (payload.timezone !== undefined) {
      company.timezone = String(payload.timezone).trim() || 'Asia/Baghdad';
    }

    if (payload.address !== undefined && payload.address !== null) {
      const address = payload.address;
      company.address = {
        line1: address.line1?.toString?.()?.trim?.() || null,
        line2: address.line2?.toString?.()?.trim?.() || null,
        city: address.city?.toString?.()?.trim?.() || null,
        governorate: address.governorate?.toString?.()?.trim?.() || null,
        country: address.country?.toString?.()?.trim?.() || null,
        postalCode: address.postalCode?.toString?.()?.trim?.() || null,
      };
    }

    await company.save();

    const workingHours = payload.workingHours || {};
    const updates = [];

    if (workingHours.start !== undefined) {
      updates.push(
        this._upsertSetting({
          companyId,
          key: WORKING_HOURS_START_KEY,
          value: String(workingHours.start).trim() || '09:00',
          group: 'working_hours',
          dataType: 'string',
          updatedBy: user._id,
        })
      );
    }
    if (workingHours.end !== undefined) {
      updates.push(
        this._upsertSetting({
          companyId,
          key: WORKING_HOURS_END_KEY,
          value: String(workingHours.end).trim() || '17:00',
          group: 'working_hours',
          dataType: 'string',
          updatedBy: user._id,
        })
      );
    }
    if (workingHours.timezone !== undefined || payload.timezone !== undefined) {
      const tz =
        workingHours.timezone !== undefined
          ? String(workingHours.timezone).trim()
          : company.timezone;
      updates.push(
        this._upsertSetting({
          companyId,
          key: WORKING_HOURS_TIMEZONE_KEY,
          value: tz || 'Asia/Baghdad',
          group: 'working_hours',
          dataType: 'string',
          updatedBy: user._id,
        })
      );
      if (workingHours.timezone !== undefined) {
        company.timezone = tz || company.timezone;
        await company.save();
      }
    }

    if (updates.length) await Promise.all(updates);

    await auditService.log({
      companyId,
      actorId: user._id,
      actorRole: auth.roles?.[0] || null,
      action: 'SETTINGS_ORGANIZATION_UPDATED',
      module: 'settings',
      resourceType: 'Company',
      resourceId: company._id,
    });

    return this.getOrganizationSettings(user, auth);
  }

  async uploadOrganizationLogo(user, auth, file) {
    this._assertPermission(auth, PERMISSIONS.SETTINGS_MANAGE);
    if (!file?.buffer) {
      throw new AppError('VALIDATION_ERROR', 'Logo file is required', 422);
    }

    const companyId = user.companyId;
    const company = await Company.findById(companyId);
    if (!company) throw new NotFoundError('Company not found');

    const uploaded = await uploadCompanyLogoBuffer(file.buffer, { companyId });
    company.logoUrl = uploaded.url;
    company.logoPublicId = uploaded.publicId;
    await company.save();

    await auditService.log({
      companyId,
      actorId: user._id,
      actorRole: auth.roles?.[0] || null,
      action: 'SETTINGS_LOGO_UPDATED',
      module: 'settings',
      resourceType: 'Company',
      resourceId: company._id,
      metadata: { logoUrl: uploaded.url },
    });

    return this.getOrganizationSettings(user, auth);
  }

  async getSystemInfo(user, auth) {
    this._assertPermission(auth, PERMISSIONS.SETTINGS_VIEW);

    const dbState = mongoose.connection.readyState;
    const databaseStatus =
      dbState === 1 ? 'connected' : dbState === 2 ? 'connecting' : 'disconnected';

    let storageUsage = {
      provider: isCloudinaryReady() ? 'cloudinary' : 'unavailable',
      usedBytes: null,
      usedMb: null,
      note: 'Detailed storage metrics require Cloudinary admin API configuration',
    };

    try {
      if (isCloudinaryReady()) {
        // Best-effort: no admin API call in Phase 1; report availability only.
        storageUsage = {
          ...storageUsage,
          usedBytes: null,
          usedMb: null,
          note: 'Cloudinary connected; usage totals not queried in this release',
        };
      }
    } catch {
      // keep default
    }

    return {
      apiStatus: 'ok',
      databaseStatus,
      storageUsage,
      apiVersion: config.server.apiVersion,
      backendVersion: readBackendVersion(),
      environment: config.env,
      uptimeSeconds: Math.floor(process.uptime()),
      timestamp: new Date().toISOString(),
    };
  }
}

const settingsService = new SettingsService();
export default settingsService;
