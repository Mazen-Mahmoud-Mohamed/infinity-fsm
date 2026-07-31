import crypto from 'crypto';
import CustomerSignature from './models/customerSignature.model.js';
import ServiceReport, {
  SERVICE_REPORT_STATUSES,
} from './models/serviceReport.model.js';
import Company from '../../core/organization/models/company.model.js';
import { uploadSignatureImageBuffer } from './reports.upload.js';
import AppError, { NotFoundError } from '../../../shared/errors/AppError.js';
import auditService from '../../core/audit/audit.service.js';

function escapeRegex(value) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function toId(value) {
  return value?.toString?.() ?? value ?? null;
}

function parseOptionalDate(value, fieldName) {
  if (value === undefined || value === null || value === '') return null;
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) {
    throw new AppError('INVALID_DATE', `${fieldName} must be a valid ISO date`, 422);
  }
  return date;
}

function parsePhotos(raw) {
  if (raw === undefined || raw === null || raw === '') return [];
  let items = raw;
  if (typeof raw === 'string') {
    try {
      items = JSON.parse(raw);
    } catch {
      throw new AppError('INVALID_PHOTOS', 'photos must be valid JSON', 422);
    }
  }
  if (!Array.isArray(items)) {
    throw new AppError('INVALID_PHOTOS', 'photos must be an array', 422);
  }
  return items
    .map((item) => {
      if (typeof item === 'string') {
        return { url: item.trim(), publicId: null, fileName: null, mimeType: null };
      }
      if (!item?.url) return null;
      return {
        url: String(item.url).trim(),
        publicId: item.publicId?.toString?.() || null,
        fileName: item.fileName?.toString?.() || null,
        mimeType: item.mimeType?.toString?.() || null,
        uploadedAt: item.uploadedAt ? new Date(item.uploadedAt) : null,
      };
    })
    .filter(Boolean);
}

function computeDurationMinutes(startTime, endTime, provided) {
  if (provided !== undefined && provided !== null && provided !== '') {
    const n = Number(provided);
    if (!Number.isFinite(n) || n < 0) {
      throw new AppError(
        'INVALID_DURATION',
        'totalDurationMinutes must be a non-negative number',
        422
      );
    }
    return Math.round(n);
  }
  if (startTime && endTime) {
    const ms = endTime.getTime() - startTime.getTime();
    if (ms < 0) return 0;
    return Math.round(ms / 60000);
  }
  return null;
}

function generateReportNumber() {
  const stamp = new Date().toISOString().slice(0, 10).replace(/-/g, '');
  const rand = crypto.randomBytes(3).toString('hex').toUpperCase();
  return `SR-${stamp}-${rand}`;
}

function generateReportQrCode(reportNumber) {
  return `INFINITY-SR:${reportNumber}`;
}

class ServiceReportsService {
  _mapSignature(doc) {
    if (!doc) return null;
    return {
      id: toId(doc._id),
      companyId: toId(doc.companyId),
      workOrderId: toId(doc.workOrderId),
      workOrderNumber: doc.workOrderNumber || null,
      customerName: doc.customerName,
      customerPosition: doc.customerPosition || null,
      signatureImage: doc.signatureImage
        ? {
            url: doc.signatureImage.url,
            publicId: doc.signatureImage.publicId || null,
            fileName: doc.signatureImage.fileName || null,
            mimeType: doc.signatureImage.mimeType || null,
            uploadedAt: doc.signatureImage.uploadedAt || null,
          }
        : null,
      signedAt: doc.signedAt || null,
      notes: doc.notes || null,
      createdBy: toId(doc.createdBy),
      createdAt: doc.createdAt || null,
      updatedAt: doc.updatedAt || null,
    };
  }

  _mapReport(doc) {
    if (!doc) return null;
    const sig = doc.customerSignature || {};
    return {
      id: toId(doc._id),
      companyId: toId(doc.companyId),
      reportNumber: doc.reportNumber,
      status: doc.status,
      company: {
        companyId: toId(doc.company?.companyId),
        name: doc.company?.name || null,
        logoUrl: doc.company?.logoUrl || null,
      },
      workOrder: {
        workOrderId: toId(doc.workOrder?.workOrderId),
        jobNumber: doc.workOrder?.jobNumber || null,
        jobTitle: doc.workOrder?.jobTitle || null,
        customerName: doc.workOrder?.customerName || null,
        customerAddress: doc.workOrder?.customerAddress || null,
        description: doc.workOrder?.description || null,
        status: doc.workOrder?.status || null,
      },
      asset: {
        assetId: toId(doc.asset?.assetId),
        assetNumber: doc.asset?.assetNumber || null,
        name: doc.asset?.name || null,
        serialNumber: doc.asset?.serialNumber || null,
        model: doc.asset?.model || null,
        manufacturer: doc.asset?.manufacturer || null,
      },
      technician: {
        userId: toId(doc.technician?.userId),
        name: doc.technician?.name || null,
        employeeId: doc.technician?.employeeId || null,
      },
      startTime: doc.startTime || null,
      endTime: doc.endTime || null,
      totalDurationMinutes: doc.totalDurationMinutes ?? null,
      beforePhotos: doc.beforePhotos || [],
      progressPhotos: doc.progressPhotos || [],
      afterPhotos: doc.afterPhotos || [],
      technicianNotes: doc.technicianNotes || null,
      customerNotes: doc.customerNotes || null,
      customerSignature: {
        signatureId: toId(sig.signatureId),
        customerName: sig.customerName || null,
        customerPosition: sig.customerPosition || null,
        signatureImageUrl: sig.signatureImageUrl || null,
        signedAt: sig.signedAt || null,
        notes: sig.notes || null,
      },
      reportQrCode: doc.reportQrCode,
      generatedAt: doc.generatedAt || null,
      generatedBy: toId(doc.generatedBy),
      downloadCount: doc.downloadCount || 0,
      lastDownloadedAt: doc.lastDownloadedAt || null,
      createdAt: doc.createdAt || null,
      updatedAt: doc.updatedAt || null,
    };
  }

  async _logAudit(user, auth, { action, resourceType, resourceId, metadata }) {
    await auditService.log({
      companyId: user.companyId,
      actorId: auth.userId,
      actorRole: auth.roles?.[0] || null,
      action,
      module: 'service_reports',
      resourceType,
      resourceId,
      metadata,
    });
  }

  async _getSignatureOrThrow(companyId, id) {
    const doc = await CustomerSignature.findOne({
      _id: id,
      companyId,
      deletedAt: null,
    });
    if (!doc) throw new NotFoundError('Customer signature not found');
    return doc;
  }

  async _getReportOrThrow(companyId, id) {
    const doc = await ServiceReport.findOne({
      _id: id,
      companyId,
      deletedAt: null,
    });
    if (!doc) throw new NotFoundError('Service report not found');
    return doc;
  }

  async getDashboard(user) {
    const companyId = user.companyId;
    const base = { companyId, deletedAt: null };
    const [
      totalReports,
      generated,
      downloaded,
      totalSignatures,
      recentReports,
    ] = await Promise.all([
      ServiceReport.countDocuments(base),
      ServiceReport.countDocuments({ ...base, status: 'GENERATED' }),
      ServiceReport.countDocuments({ ...base, status: 'DOWNLOADED' }),
      CustomerSignature.countDocuments(base),
      ServiceReport.find(base).sort({ generatedAt: -1 }).limit(5).lean(),
    ]);

    return {
      totalReports,
      generated,
      downloaded,
      totalSignatures,
      recentReports: recentReports.map((d) => this._mapReport(d)),
    };
  }

  async listSignatures(user, { page = 1, limit = 20, search } = {}) {
    const filter = { companyId: user.companyId, deletedAt: null };
    if (search?.trim()) {
      const regex = new RegExp(escapeRegex(search.trim()), 'i');
      filter.$or = [
        { customerName: regex },
        { customerPosition: regex },
        { workOrderNumber: regex },
        { notes: regex },
      ];
    }

    const skip = (Number(page) - 1) * Number(limit);
    const [items, total] = await Promise.all([
      CustomerSignature.find(filter)
        .sort({ signedAt: -1 })
        .skip(skip)
        .limit(Number(limit))
        .lean(),
      CustomerSignature.countDocuments(filter),
    ]);

    return {
      items: items.map((d) => this._mapSignature(d)),
      pagination: {
        page: Number(page),
        limit: Number(limit),
        total,
        totalPages: Math.max(1, Math.ceil(total / Number(limit))),
      },
    };
  }

  async getSignatureById(user, id) {
    return this._mapSignature(await this._getSignatureOrThrow(user.companyId, id));
  }

  async createSignature(user, auth, payload, file) {
    if (!file?.buffer) {
      throw new AppError('SIGNATURE_REQUIRED', 'Signature image is required', 422);
    }

    const customerName = payload.customerName?.toString?.()?.trim?.();
    if (!customerName) {
      throw new AppError('CUSTOMER_NAME_REQUIRED', 'Customer name is required', 422);
    }

    const uploaded = await uploadSignatureImageBuffer(file.buffer, {
      companyId: user.companyId,
    });

    const signedAt =
      parseOptionalDate(payload.signedAt, 'signedAt') || new Date();

    const doc = await CustomerSignature.create({
      companyId: user.companyId,
      workOrderId: payload.workOrderId || null,
      workOrderNumber: payload.workOrderNumber?.toString?.()?.trim?.() || null,
      customerName,
      customerPosition: payload.customerPosition?.toString?.()?.trim?.() || null,
      signatureImage: {
        url: uploaded.url,
        publicId: uploaded.publicId,
        fileName: file.originalname || 'signature.png',
        mimeType: file.mimetype || 'image/png',
        uploadedAt: new Date(),
      },
      signedAt,
      notes: payload.notes?.toString?.()?.trim?.() || null,
      createdBy: auth.userId,
    });

    await this._logAudit(user, auth, {
      action: 'service_reports.signature.create',
      resourceType: 'CustomerSignature',
      resourceId: doc._id,
      metadata: { customerName },
    });

    return this._mapSignature(doc.toObject());
  }

  async deleteSignature(user, auth, id) {
    const doc = await this._getSignatureOrThrow(user.companyId, id);
    doc.deletedAt = new Date();
    await doc.save();

    await this._logAudit(user, auth, {
      action: 'service_reports.signature.delete',
      resourceType: 'CustomerSignature',
      resourceId: doc._id,
      metadata: {},
    });

    return this._mapSignature(doc.toObject());
  }

  async listReports(user, { page = 1, limit = 20, search, status } = {}) {
    const filter = { companyId: user.companyId, deletedAt: null };
    if (status && String(status).toUpperCase() !== 'ALL') {
      const normalized = String(status).toUpperCase();
      if (!SERVICE_REPORT_STATUSES.includes(normalized)) {
        throw new AppError('INVALID_STATUS', 'Invalid report status', 422);
      }
      filter.status = normalized;
    }
    if (search?.trim()) {
      const regex = new RegExp(escapeRegex(search.trim()), 'i');
      filter.$or = [
        { reportNumber: regex },
        { reportQrCode: regex },
        { 'workOrder.jobNumber': regex },
        { 'workOrder.jobTitle': regex },
        { 'workOrder.customerName': regex },
        { 'technician.name': regex },
        { 'asset.name': regex },
        { 'asset.assetNumber': regex },
      ];
    }

    const skip = (Number(page) - 1) * Number(limit);
    const [items, total] = await Promise.all([
      ServiceReport.find(filter)
        .sort({ generatedAt: -1 })
        .skip(skip)
        .limit(Number(limit))
        .lean(),
      ServiceReport.countDocuments(filter),
    ]);

    return {
      items: items.map((d) => this._mapReport(d)),
      pagination: {
        page: Number(page),
        limit: Number(limit),
        total,
        totalPages: Math.max(1, Math.ceil(total / Number(limit))),
      },
    };
  }

  async getReportById(user, id) {
    return this._mapReport(await this._getReportOrThrow(user.companyId, id));
  }

  async generateReport(user, auth, payload) {
    const company = await Company.findById(user.companyId).lean();
    const startTime = parseOptionalDate(payload.startTime, 'startTime');
    const endTime = parseOptionalDate(payload.endTime, 'endTime');
    const totalDurationMinutes = computeDurationMinutes(
      startTime,
      endTime,
      payload.totalDurationMinutes
    );

    let signatureSnapshot = {
      signatureId: null,
      customerName: null,
      customerPosition: null,
      signatureImageUrl: null,
      signedAt: null,
      notes: null,
    };

    if (payload.signatureId) {
      const signature = await this._getSignatureOrThrow(
        user.companyId,
        payload.signatureId
      );
      signatureSnapshot = {
        signatureId: signature._id,
        customerName: signature.customerName,
        customerPosition: signature.customerPosition || null,
        signatureImageUrl: signature.signatureImage?.url || null,
        signedAt: signature.signedAt || null,
        notes: signature.notes || null,
      };
    } else if (payload.customerSignature) {
      const cs = payload.customerSignature;
      signatureSnapshot = {
        signatureId: cs.signatureId || null,
        customerName: cs.customerName?.toString?.()?.trim?.() || null,
        customerPosition: cs.customerPosition?.toString?.()?.trim?.() || null,
        signatureImageUrl: cs.signatureImageUrl?.toString?.()?.trim?.() || null,
        signedAt: parseOptionalDate(cs.signedAt, 'customerSignature.signedAt'),
        notes: cs.notes?.toString?.()?.trim?.() || null,
      };
    }

    const reportNumber = generateReportNumber();
    const reportQrCode = generateReportQrCode(reportNumber);

    const wo = payload.workOrder || {};
    const asset = payload.asset || {};
    const technician = payload.technician || {};

    const doc = await ServiceReport.create({
      companyId: user.companyId,
      reportNumber,
      status: 'GENERATED',
      company: {
        companyId: user.companyId,
        name:
          payload.companyName?.toString?.()?.trim?.() ||
          company?.name ||
          null,
        logoUrl:
          payload.companyLogoUrl?.toString?.()?.trim?.() ||
          company?.logoUrl ||
          null,
      },
      workOrder: {
        workOrderId: wo.workOrderId || payload.workOrderId || null,
        jobNumber: wo.jobNumber?.toString?.()?.trim?.() || null,
        jobTitle: wo.jobTitle?.toString?.()?.trim?.() || null,
        customerName: wo.customerName?.toString?.()?.trim?.() || null,
        customerAddress: wo.customerAddress?.toString?.()?.trim?.() || null,
        description: wo.description?.toString?.()?.trim?.() || null,
        status: wo.status?.toString?.()?.trim?.() || null,
      },
      asset: {
        assetId: asset.assetId || null,
        assetNumber: asset.assetNumber?.toString?.()?.trim?.() || null,
        name: asset.name?.toString?.()?.trim?.() || null,
        serialNumber: asset.serialNumber?.toString?.()?.trim?.() || null,
        model: asset.model?.toString?.()?.trim?.() || null,
        manufacturer: asset.manufacturer?.toString?.()?.trim?.() || null,
      },
      technician: {
        userId: technician.userId || auth.userId || null,
        name:
          technician.name?.toString?.()?.trim?.() ||
          [user.firstName, user.lastName].filter(Boolean).join(' ').trim() ||
          user.email ||
          null,
        employeeId: technician.employeeId?.toString?.()?.trim?.() || null,
      },
      startTime,
      endTime,
      totalDurationMinutes,
      beforePhotos: parsePhotos(payload.beforePhotos),
      progressPhotos: parsePhotos(payload.progressPhotos),
      afterPhotos: parsePhotos(payload.afterPhotos),
      technicianNotes: payload.technicianNotes?.toString?.()?.trim?.() || null,
      customerNotes: payload.customerNotes?.toString?.()?.trim?.() || null,
      customerSignature: signatureSnapshot,
      reportQrCode,
      generatedAt: new Date(),
      generatedBy: auth.userId,
    });

    await this._logAudit(user, auth, {
      action: 'service_reports.generate',
      resourceType: 'ServiceReport',
      resourceId: doc._id,
      metadata: { reportNumber },
    });

    return this._mapReport(doc.toObject());
  }

  async downloadReport(user, auth, id) {
    const doc = await this._getReportOrThrow(user.companyId, id);
    doc.downloadCount = (doc.downloadCount || 0) + 1;
    doc.lastDownloadedAt = new Date();
    doc.status = 'DOWNLOADED';
    await doc.save();

    await this._logAudit(user, auth, {
      action: 'service_reports.download',
      resourceType: 'ServiceReport',
      resourceId: doc._id,
      metadata: { downloadCount: doc.downloadCount },
    });

    const report = this._mapReport(doc.toObject());
    return {
      report,
      fileName: `${doc.reportNumber}.json`,
      mimeType: 'application/json',
      content: report,
      downloadedAt: doc.lastDownloadedAt,
    };
  }
}

export default new ServiceReportsService();
