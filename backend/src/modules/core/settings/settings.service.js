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
import {
  TECHNICIAN_INTERFACE_KEY,
  normalizeTechnicianInterface,
} from './technician-interface.config.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const WORKING_HOURS_START_KEY = 'working_hours.start';
const WORKING_HOURS_END_KEY = 'working_hours.end';
const WORKING_HOURS_TIMEZONE_KEY = 'working_hours.timezone';
const OVERTIME_VOICE_MAX_DURATION_SECONDS_KEY =
  'overtime.voice_max_duration_seconds';
const OVERTIME_VOICE_MAX_DURATION_MINUTES_KEY =
  'overtime.voice_max_duration_minutes';
const OVERTIME_VOICE_DURATION_OPTIONS_SECONDS = Object.freeze([
  120, 300, 600, 900, 1200,
]);
const OVERTIME_VOICE_DURATION_DEFAULT_SECONDS = 300;

const OVERTIME_VOICE_RECORDING_QUALITY_KEY =
  'overtime.voice_recording_quality';
const OVERTIME_VOICE_QUALITY_OPTIONS = Object.freeze(['high', 'medium', 'low']);
const OVERTIME_VOICE_QUALITY_DEFAULT = 'medium';

const OVERTIME_MAX_PHOTO_SIZE_KEY = 'overtime.max_photo_size_mb';
const OVERTIME_MAX_PHOTO_SIZE_OPTIONS = Object.freeze([1, 2, 5, 'original']);
const OVERTIME_MAX_PHOTO_SIZE_DEFAULT = 2;

const OVERTIME_UPLOAD_POLICY_KEY = 'overtime.upload_policy';
const OVERTIME_UPLOAD_POLICY_OPTIONS = Object.freeze([
  'immediately',
  'wifi_preferred',
  'wifi_only',
  'manual',
  'ask_every_time',
]);
const OVERTIME_UPLOAD_POLICY_DEFAULT = 'immediately';

const OVERTIME_CONFIGURATION_PRESET_KEY = 'overtime.configuration_preset';
const OVERTIME_CONFIGURATION_PRESET_OPTIONS = Object.freeze([
  'office',
  'field_service',
  'heavy_maintenance',
  'custom',
]);

const OVERTIME_VOICE_DURATION_OPTIONS = Object.freeze([2, 5, 10, 15, 20]);
const OVERTIME_VOICE_DURATION_DEFAULT_MINUTES = 5;

function normalizeVoiceMaxDurationMinutes(value) {
  const n = Number(value);
  if (OVERTIME_VOICE_DURATION_OPTIONS.includes(n)) {
    return n;
  }
  return OVERTIME_VOICE_DURATION_DEFAULT_MINUTES;
}

function normalizeVoiceMaxDurationSeconds(value) {
  const n = Number(value);
  if (OVERTIME_VOICE_DURATION_OPTIONS_SECONDS.includes(n)) {
    return n;
  }
  return OVERTIME_VOICE_DURATION_DEFAULT_SECONDS;
}

function normalizeVoiceRecordingQuality(value) {
  const normalized = String(value ?? '').trim().toLowerCase();
  if (OVERTIME_VOICE_QUALITY_OPTIONS.includes(normalized)) {
    return normalized;
  }
  return OVERTIME_VOICE_QUALITY_DEFAULT;
}

function normalizeMaxPhotoSize(value) {
  if (value === 'original' || value === null || value === undefined) {
    return 'original';
  }
  const n = Number(value);
  if (OVERTIME_MAX_PHOTO_SIZE_OPTIONS.includes(n)) {
    return n;
  }
  return OVERTIME_MAX_PHOTO_SIZE_DEFAULT;
}

function normalizeUploadPolicy(value) {
  const normalized = String(value ?? '').trim().toLowerCase();
  if (OVERTIME_UPLOAD_POLICY_OPTIONS.includes(normalized)) {
    return normalized;
  }
  return OVERTIME_UPLOAD_POLICY_DEFAULT;
}

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
      timezone: company.timezone || workingHours.timezone || 'Africa/Cairo',
      workingHours: {
        start: workingHours.start,
        end: workingHours.end,
        timezone: workingHours.timezone || company.timezone || 'Africa/Cairo',
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
        company.timezone || 'Africa/Cairo'
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
      company.timezone = String(payload.timezone).trim() || 'Africa/Cairo';
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
          value: tz || 'Africa/Cairo',
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

  async resolveVoiceMaxDurationSeconds(companyId) {
    const secondsRaw = await this._getSettingValue(
      companyId,
      OVERTIME_VOICE_MAX_DURATION_SECONDS_KEY,
      null
    );
    if (secondsRaw !== null && secondsRaw !== undefined) {
      return normalizeVoiceMaxDurationSeconds(secondsRaw);
    }

    const minutesRaw = await this._getSettingValue(
      companyId,
      OVERTIME_VOICE_MAX_DURATION_MINUTES_KEY,
      null
    );
    if (minutesRaw !== null && minutesRaw !== undefined) {
      const migratedSeconds =
        normalizeVoiceMaxDurationMinutes(minutesRaw) * 60;
      await this._upsertSetting({
        companyId,
        key: OVERTIME_VOICE_MAX_DURATION_SECONDS_KEY,
        value: migratedSeconds,
        group: 'overtime',
        dataType: 'number',
        updatedBy: null,
      });
      return migratedSeconds;
    }

    return OVERTIME_VOICE_DURATION_DEFAULT_SECONDS;
  }

  async resolveVoiceRecordingQuality(companyId) {
    const raw = await this._getSettingValue(
      companyId,
      OVERTIME_VOICE_RECORDING_QUALITY_KEY,
      OVERTIME_VOICE_QUALITY_DEFAULT
    );
    return normalizeVoiceRecordingQuality(raw);
  }

  async resolveMaxPhotoSize(companyId) {
    const raw = await this._getSettingValue(
      companyId,
      OVERTIME_MAX_PHOTO_SIZE_KEY,
      OVERTIME_MAX_PHOTO_SIZE_DEFAULT
    );
    return normalizeMaxPhotoSize(raw);
  }

  async resolveUploadPolicy(companyId) {
    const raw = await this._getSettingValue(
      companyId,
      OVERTIME_UPLOAD_POLICY_KEY,
      OVERTIME_UPLOAD_POLICY_DEFAULT
    );
    return normalizeUploadPolicy(raw);
  }

  async resolveConfigurationPreset(companyId) {
    const raw = await this._getSettingValue(
      companyId,
      OVERTIME_CONFIGURATION_PRESET_KEY,
      'custom'
    );
    const normalized = String(raw ?? 'custom').trim().toLowerCase();
    return OVERTIME_CONFIGURATION_PRESET_OPTIONS.includes(normalized)
      ? normalized
      : 'custom';
  }

  async _logOvertimeAuditChange({
    companyId,
    user,
    auth,
    action,
    field,
    before,
    after,
  }) {
    if (before === after) {
      return;
    }
    await auditService.log({
      companyId,
      actorId: user._id,
      actorRole: auth.roles?.[0] || null,
      action,
      module: 'settings',
      resourceType: 'Setting',
      resourceId: null,
      metadata: { field, before, after },
    });
  }

  async getOvertimeSettings(user, auth) {
    this._assertPermission(auth, PERMISSIONS.SETTINGS_VIEW);
    const companyId = user.companyId;
    const [
      voiceMaxDurationSeconds,
      voiceRecordingQuality,
      maxPhotoSize,
      uploadPolicy,
      configurationPreset,
    ] = await Promise.all([
      this.resolveVoiceMaxDurationSeconds(companyId),
      this.resolveVoiceRecordingQuality(companyId),
      this.resolveMaxPhotoSize(companyId),
      this.resolveUploadPolicy(companyId),
      this.resolveConfigurationPreset(companyId),
    ]);
    return {
      voiceMaxDurationSeconds,
      voiceDurationOptionsSeconds: [...OVERTIME_VOICE_DURATION_OPTIONS_SECONDS],
      voiceRecordingQuality,
      voiceQualityOptions: [...OVERTIME_VOICE_QUALITY_OPTIONS],
      maxPhotoSize,
      maxPhotoSizeOptions: [...OVERTIME_MAX_PHOTO_SIZE_OPTIONS],
      uploadPolicy,
      uploadPolicyOptions: [...OVERTIME_UPLOAD_POLICY_OPTIONS],
      configurationPreset,
    };
  }

  async updateOvertimeSettings(user, auth, payload = {}) {
    this._assertPermission(auth, PERMISSIONS.SETTINGS_MANAGE);
    const companyId = user.companyId;

    const before = {
      voiceMaxDurationSeconds: await this.resolveVoiceMaxDurationSeconds(
        companyId
      ),
      voiceRecordingQuality: await this.resolveVoiceRecordingQuality(
        companyId
      ),
      maxPhotoSize: await this.resolveMaxPhotoSize(companyId),
      uploadPolicy: await this.resolveUploadPolicy(companyId),
      configurationPreset: await this.resolveConfigurationPreset(companyId),
    };

    if (payload.restoreDefaults === true) {
      payload.voiceMaxDurationSeconds = OVERTIME_VOICE_DURATION_DEFAULT_SECONDS;
      payload.voiceRecordingQuality = OVERTIME_VOICE_QUALITY_DEFAULT;
      payload.maxPhotoSize = OVERTIME_MAX_PHOTO_SIZE_DEFAULT;
      payload.uploadPolicy = OVERTIME_UPLOAD_POLICY_DEFAULT;
      payload.configurationPreset = 'custom';
    }

    if (payload.voiceMaxDurationSeconds !== undefined) {
      const seconds = normalizeVoiceMaxDurationSeconds(
        payload.voiceMaxDurationSeconds
      );
      await this._upsertSetting({
        companyId,
        key: OVERTIME_VOICE_MAX_DURATION_SECONDS_KEY,
        value: seconds,
        group: 'overtime',
        dataType: 'number',
        updatedBy: user._id,
      });
    }

    if (payload.voiceRecordingQuality !== undefined) {
      const quality = normalizeVoiceRecordingQuality(
        payload.voiceRecordingQuality
      );
      await this._upsertSetting({
        companyId,
        key: OVERTIME_VOICE_RECORDING_QUALITY_KEY,
        value: quality,
        group: 'overtime',
        dataType: 'string',
        updatedBy: user._id,
      });
    }

    if (payload.maxPhotoSize !== undefined) {
      const maxPhotoSize = normalizeMaxPhotoSize(payload.maxPhotoSize);
      await this._upsertSetting({
        companyId,
        key: OVERTIME_MAX_PHOTO_SIZE_KEY,
        value: maxPhotoSize,
        group: 'overtime',
        dataType: maxPhotoSize === 'original' ? 'string' : 'number',
        updatedBy: user._id,
      });
    }

    if (payload.uploadPolicy !== undefined) {
      const uploadPolicy = normalizeUploadPolicy(payload.uploadPolicy);
      await this._upsertSetting({
        companyId,
        key: OVERTIME_UPLOAD_POLICY_KEY,
        value: uploadPolicy,
        group: 'overtime',
        dataType: 'string',
        updatedBy: user._id,
      });
    }

    if (payload.configurationPreset !== undefined) {
      const preset = String(payload.configurationPreset).trim().toLowerCase();
      const normalized = OVERTIME_CONFIGURATION_PRESET_OPTIONS.includes(preset)
        ? preset
        : 'custom';
      await this._upsertSetting({
        companyId,
        key: OVERTIME_CONFIGURATION_PRESET_KEY,
        value: normalized,
        group: 'overtime',
        dataType: 'string',
        updatedBy: user._id,
      });
    }

    const after = {
      voiceMaxDurationSeconds: await this.resolveVoiceMaxDurationSeconds(
        companyId
      ),
      voiceRecordingQuality: await this.resolveVoiceRecordingQuality(
        companyId
      ),
      maxPhotoSize: await this.resolveMaxPhotoSize(companyId),
      uploadPolicy: await this.resolveUploadPolicy(companyId),
      configurationPreset: await this.resolveConfigurationPreset(companyId),
    };

    if (payload.restoreDefaults === true) {
      await this._logOvertimeAuditChange({
        companyId,
        user,
        auth,
        action: 'SETTINGS_OVERTIME_RESTORED_DEFAULTS',
        field: 'all',
        before,
        after,
      });
    } else if (
      payload.configurationPreset &&
      payload.configurationPreset !== 'custom' &&
      before.configurationPreset !== after.configurationPreset
    ) {
      await this._logOvertimeAuditChange({
        companyId,
        user,
        auth,
        action: 'SETTINGS_OVERTIME_PRESET_APPLIED',
        field: 'configurationPreset',
        before: before.configurationPreset,
        after: after.configurationPreset,
      });
    }

    await this._logOvertimeAuditChange({
      companyId,
      user,
      auth,
      action: 'SETTINGS_OVERTIME_VOICE_DURATION_CHANGED',
      field: 'voiceMaxDurationSeconds',
      before: before.voiceMaxDurationSeconds,
      after: after.voiceMaxDurationSeconds,
    });
    await this._logOvertimeAuditChange({
      companyId,
      user,
      auth,
      action: 'SETTINGS_OVERTIME_VOICE_QUALITY_CHANGED',
      field: 'voiceRecordingQuality',
      before: before.voiceRecordingQuality,
      after: after.voiceRecordingQuality,
    });
    await this._logOvertimeAuditChange({
      companyId,
      user,
      auth,
      action: 'SETTINGS_OVERTIME_MAX_PHOTO_SIZE_CHANGED',
      field: 'maxPhotoSize',
      before: before.maxPhotoSize,
      after: after.maxPhotoSize,
    });
    await this._logOvertimeAuditChange({
      companyId,
      user,
      auth,
      action: 'SETTINGS_OVERTIME_UPLOAD_POLICY_CHANGED',
      field: 'uploadPolicy',
      before: before.uploadPolicy,
      after: after.uploadPolicy,
    });

    return this.getOvertimeSettings(user, auth);
  }

  /** Lightweight overtime media config for all authenticated users. */
  async getOvertimeMediaConfig(user) {
    const companyId = user.companyId;
    const [
      voiceMaxDurationSeconds,
      voiceRecordingQuality,
      maxPhotoSize,
      uploadPolicy,
    ] = await Promise.all([
      this.resolveVoiceMaxDurationSeconds(companyId),
      this.resolveVoiceRecordingQuality(companyId),
      this.resolveMaxPhotoSize(companyId),
      this.resolveUploadPolicy(companyId),
    ]);
    return {
      voiceMaxDurationSeconds,
      voiceRecordingQuality,
      maxPhotoSize,
      uploadPolicy,
    };
  }

  /** @deprecated Use getOvertimeMediaConfig — kept for backward compatibility. */
  async getOvertimeVoiceDurationConfig(user) {
    const config = await this.getOvertimeMediaConfig(user);
    return {
      voiceMaxDurationSeconds: config.voiceMaxDurationSeconds,
      voiceMaxDurationMinutes: config.voiceMaxDurationSeconds / 60,
    };
  }

  async resolveTechnicianInterface(companyId) {
    const raw = await this._getSettingValue(companyId, TECHNICIAN_INTERFACE_KEY);
    return normalizeTechnicianInterface(raw);
  }

  /** Admin-only read of technician interface configuration. */
  async getTechnicianInterfaceSettings(user, auth) {
    this._assertPermission(auth, PERMISSIONS.SETTINGS_MANAGE);
    return this.resolveTechnicianInterface(user.companyId);
  }

  /** Admin-only update of technician interface configuration. */
  async updateTechnicianInterfaceSettings(user, auth, payload = {}) {
    this._assertPermission(auth, PERMISSIONS.SETTINGS_MANAGE);
    const companyId = user.companyId;

    const before = await this.resolveTechnicianInterface(companyId);
    const after = normalizeTechnicianInterface({
      ...before,
      ...payload,
    });

    await this._upsertSetting({
      companyId,
      key: TECHNICIAN_INTERFACE_KEY,
      value: after,
      group: 'technician_interface',
      dataType: 'object',
      updatedBy: user._id,
    });

    await this._logOvertimeAuditChange({
      companyId,
      user,
      auth,
      action: 'SETTINGS_TECHNICIAN_INTERFACE_UPDATED',
      field: TECHNICIAN_INTERFACE_KEY,
      before,
      after,
    });

    return after;
  }

  /** Effective technician interface flags for authenticated users. */
  async getTechnicianInterfaceConfig(user) {
    return this.resolveTechnicianInterface(user.companyId);
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
