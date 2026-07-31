import mongoose from 'mongoose';

const { Schema } = mongoose;

export const SERVICE_REPORT_STATUSES = Object.freeze([
  'DRAFT',
  'GENERATED',
  'DOWNLOADED',
]);

const photoRefSchema = new Schema(
  {
    url: { type: String, required: true },
    publicId: { type: String, default: null },
    fileName: { type: String, default: null },
    mimeType: { type: String, default: null },
    uploadedAt: { type: Date, default: null },
  },
  { _id: false }
);

const workOrderInfoSchema = new Schema(
  {
    workOrderId: { type: Schema.Types.ObjectId, ref: 'WorkOrder', default: null },
    jobNumber: { type: String, trim: true, default: null, maxlength: 100 },
    jobTitle: { type: String, trim: true, default: null, maxlength: 300 },
    customerName: { type: String, trim: true, default: null, maxlength: 200 },
    customerAddress: { type: String, trim: true, default: null, maxlength: 500 },
    description: { type: String, trim: true, default: null, maxlength: 5000 },
    status: { type: String, trim: true, default: null, maxlength: 50 },
  },
  { _id: false }
);

const assetInfoSchema = new Schema(
  {
    assetId: { type: Schema.Types.ObjectId, ref: 'Asset', default: null },
    assetNumber: { type: String, trim: true, default: null, maxlength: 100 },
    name: { type: String, trim: true, default: null, maxlength: 200 },
    serialNumber: { type: String, trim: true, default: null, maxlength: 120 },
    model: { type: String, trim: true, default: null, maxlength: 200 },
    manufacturer: { type: String, trim: true, default: null, maxlength: 200 },
  },
  { _id: false }
);

const technicianInfoSchema = new Schema(
  {
    userId: { type: Schema.Types.ObjectId, ref: 'User', default: null },
    name: { type: String, trim: true, default: null, maxlength: 200 },
    employeeId: { type: String, trim: true, default: null, maxlength: 100 },
  },
  { _id: false }
);

const companyInfoSchema = new Schema(
  {
    companyId: { type: Schema.Types.ObjectId, ref: 'Company', default: null },
    name: { type: String, trim: true, default: null, maxlength: 200 },
    logoUrl: { type: String, trim: true, default: null },
  },
  { _id: false }
);

const signatureSnapshotSchema = new Schema(
  {
    signatureId: {
      type: Schema.Types.ObjectId,
      ref: 'CustomerSignature',
      default: null,
    },
    customerName: { type: String, trim: true, default: null, maxlength: 200 },
    customerPosition: { type: String, trim: true, default: null, maxlength: 200 },
    signatureImageUrl: { type: String, trim: true, default: null },
    signedAt: { type: Date, default: null },
    notes: { type: String, trim: true, default: null, maxlength: 5000 },
  },
  { _id: false }
);

const serviceReportSchema = new Schema(
  {
    companyId: {
      type: Schema.Types.ObjectId,
      ref: 'Company',
      required: true,
      index: true,
    },
    reportNumber: {
      type: String,
      required: true,
      trim: true,
      uppercase: true,
      maxlength: 50,
    },
    status: {
      type: String,
      enum: SERVICE_REPORT_STATUSES,
      default: 'GENERATED',
      index: true,
    },
    company: {
      type: companyInfoSchema,
      default: () => ({}),
    },
    workOrder: {
      type: workOrderInfoSchema,
      default: () => ({}),
    },
    asset: {
      type: assetInfoSchema,
      default: () => ({}),
    },
    technician: {
      type: technicianInfoSchema,
      default: () => ({}),
    },
    startTime: { type: Date, default: null },
    endTime: { type: Date, default: null },
    totalDurationMinutes: { type: Number, default: null, min: 0 },
    beforePhotos: { type: [photoRefSchema], default: [] },
    progressPhotos: { type: [photoRefSchema], default: [] },
    afterPhotos: { type: [photoRefSchema], default: [] },
    technicianNotes: {
      type: String,
      trim: true,
      default: null,
      maxlength: 10000,
    },
    customerNotes: {
      type: String,
      trim: true,
      default: null,
      maxlength: 10000,
    },
    customerSignature: {
      type: signatureSnapshotSchema,
      default: () => ({}),
    },
    reportQrCode: {
      type: String,
      required: true,
      trim: true,
      maxlength: 200,
      index: true,
    },
    generatedAt: {
      type: Date,
      default: Date.now,
      index: true,
    },
    generatedBy: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      default: null,
    },
    downloadCount: {
      type: Number,
      default: 0,
      min: 0,
    },
    lastDownloadedAt: {
      type: Date,
      default: null,
    },
    deletedAt: {
      type: Date,
      default: null,
      index: true,
    },
  },
  {
    timestamps: true,
    collection: 'service_reports',
  }
);

serviceReportSchema.index({ companyId: 1, reportNumber: 1 }, { unique: true });
serviceReportSchema.index({ companyId: 1, generatedAt: -1 });
serviceReportSchema.index({ companyId: 1, 'workOrder.jobNumber': 1 });

const ServiceReport = mongoose.model('ServiceReport', serviceReportSchema);

export default ServiceReport;
