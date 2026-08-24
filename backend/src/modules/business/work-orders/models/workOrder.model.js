import mongoose from 'mongoose';

const { Schema } = mongoose;

export const WORK_ORDER_STATUSES = Object.freeze([
  'PENDING',
  'ASSIGNED',
  'ACCEPTED',
  'REJECTED',
  'IN_PROGRESS',
  'COMPLETED',
  'CANCELLED',
]);

export const WORK_ORDER_PRIORITIES = Object.freeze([
  'LOW',
  'MEDIUM',
  'HIGH',
  'CRITICAL',
]);

export const WORK_ORDER_TIMELINE_TYPES = Object.freeze([
  'CREATED',
  'ASSIGNED',
  'ACCEPTED',
  'REJECTED',
  'STARTED',
  'COMPLETED',
  'CANCELLED',
]);

const customerAddressSchema = new Schema(
  {
    street: { type: String, trim: true, default: null },
    city: { type: String, trim: true, default: null },
    governorate: { type: String, trim: true, default: null },
    lat: { type: Number, default: null },
    lng: { type: Number, default: null },
  },
  { _id: false }
);

const attachmentSchema = new Schema(
  {
    url: { type: String, required: true },
    publicId: { type: String, default: null },
    fileName: { type: String, default: null },
    mimeType: { type: String, default: null },
    uploadedAt: { type: Date, default: Date.now },
  },
  { _id: false }
);

const photoRefSchema = new Schema(
  {
    url: { type: String, required: true },
    publicId: { type: String, default: null },
    fileName: { type: String, default: null },
    mimeType: { type: String, default: null },
    uploadedAt: { type: Date, default: Date.now },
    uploadedBy: { type: Schema.Types.ObjectId, ref: 'User', default: null },
  },
  { _id: false }
);

const fieldLocationSchema = new Schema(
  {
    latitude: { type: Number, required: true },
    longitude: { type: Number, required: true },
    accuracy: { type: Number, default: null },
    address: { type: String, trim: true, default: null },
    recordedAt: { type: Date, required: true },
  },
  { _id: false }
);

const progressNoteSchema = new Schema(
  {
    text: { type: String, required: true, trim: true, maxlength: 2000 },
    createdAt: { type: Date, default: Date.now },
    createdBy: { type: Schema.Types.ObjectId, ref: 'User', required: true },
    createdByName: { type: String, trim: true, default: null },
  },
  { _id: true }
);

const timelineEventSchema = new Schema(
  {
    type: {
      type: String,
      enum: WORK_ORDER_TIMELINE_TYPES,
      required: true,
    },
    at: { type: Date, required: true },
    userId: { type: Schema.Types.ObjectId, ref: 'User', default: null },
    userName: { type: String, trim: true, default: null },
    note: { type: String, trim: true, default: null, maxlength: 1000 },
  },
  { _id: false }
);

const organizationSnapshotSchema = new Schema(
  {
    companyId: { type: Schema.Types.ObjectId, required: true },
    branchId: { type: Schema.Types.ObjectId, default: null },
    regionId: { type: Schema.Types.ObjectId, default: null },
    cityId: { type: Schema.Types.ObjectId, default: null },
    departmentId: { type: Schema.Types.ObjectId, default: null },
    teamId: { type: Schema.Types.ObjectId, default: null },
  },
  { _id: false }
);

/** Optional admin voice note (Cloudinary; no binary in MongoDB). */
const voiceNoteSchema = new Schema(
  {
    url: { type: String, required: true },
    publicId: { type: String, default: null },
    duration: { type: Number, default: null, min: 0 },
    size: { type: Number, default: null, min: 0 },
    format: { type: String, default: null, trim: true, maxlength: 20 },
    uploadedAt: { type: Date, default: null },
  },
  { _id: false }
);

const workOrderSchema = new Schema(
  {
    companyId: {
      type: Schema.Types.ObjectId,
      ref: 'Company',
      required: true,
      index: true,
    },
    jobNumber: {
      type: String,
      required: true,
      trim: true,
    },
    jobTitle: {
      type: String,
      required: true,
      trim: true,
      maxlength: 200,
    },
    customerId: {
      type: Schema.Types.ObjectId,
      default: null,
    },
    customerName: {
      type: String,
      trim: true,
      default: null,
      maxlength: 200,
    },
    /** Optional customer contact numbers (international-friendly; additive). */
    customerPhoneNumbers: {
      type: [
        {
          type: String,
          trim: true,
          maxlength: 40,
        },
      ],
      default: [],
    },
    customerAddress: {
      type: customerAddressSchema,
      default: null,
    },
    locationLabel: {
      type: String,
      trim: true,
      default: null,
      maxlength: 300,
    },
    /** External map / location link (Google Maps, etc.). Additive; keeps locationLabel. */
    locationUrl: {
      type: String,
      trim: true,
      default: null,
      maxlength: 2000,
    },
    assignedTechnicianId: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      default: null,
      index: true,
    },
    assignedTechnicianName: {
      type: String,
      trim: true,
      default: null,
    },
    /** Multi-assignee support. Primary remains assignedTechnicianId (first entry). */
    assignedTechnicianIds: {
      type: [{ type: Schema.Types.ObjectId, ref: 'User' }],
      default: [],
    },
    assignedTechnicianNames: {
      type: [String],
      default: [],
    },
    supervisorId: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      default: null,
    },
    createdBy: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    organizationSnapshot: {
      type: organizationSnapshotSchema,
      required: true,
    },
    priority: {
      type: String,
      enum: WORK_ORDER_PRIORITIES,
      default: 'MEDIUM',
      required: true,
    },
    status: {
      type: String,
      enum: WORK_ORDER_STATUSES,
      default: 'PENDING',
      required: true,
      index: true,
    },
    description: {
      type: String,
      trim: true,
      default: null,
      maxlength: 5000,
    },
    notes: {
      type: String,
      trim: true,
      default: null,
      maxlength: 5000,
    },
    /** Optional admin voice note attached to work-order notes (Cloudinary). */
    voiceNote: {
      type: voiceNoteSchema,
      default: undefined,
    },
    scheduledAt: {
      type: Date,
      default: null,
      index: true,
    },
    attachments: {
      type: [attachmentSchema],
      default: [],
    },
    // Phase 2 — Field execution
    beforePhotos: {
      type: [photoRefSchema],
      default: [],
    },
    afterPhotos: {
      type: [photoRefSchema],
      default: [],
    },
    progressPhotos: {
      type: [photoRefSchema],
      default: [],
    },
    beforeNotes: {
      type: String,
      trim: true,
      default: null,
      maxlength: 5000,
    },
    progressNotes: {
      type: [progressNoteSchema],
      default: [],
    },
    completionNotes: {
      type: String,
      trim: true,
      default: null,
      maxlength: 5000,
    },
    startedLocation: {
      type: fieldLocationSchema,
      default: null,
    },
    completedLocation: {
      type: fieldLocationSchema,
      default: null,
    },
    timeline: {
      type: [timelineEventSchema],
      default: [],
    },
    estimatedDurationMinutes: {
      type: Number,
      default: null,
    },
    actualDurationMinutes: {
      type: Number,
      default: null,
    },
    startedAt: {
      type: Date,
      default: null,
    },
    completedAt: {
      type: Date,
      default: null,
    },
    cancelledAt: {
      type: Date,
      default: null,
    },
    cancelledBy: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      default: null,
    },
    cancellationReason: {
      type: String,
      trim: true,
      default: null,
      maxlength: 1000,
    },
    rejectedAt: {
      type: Date,
      default: null,
    },
    rejectionReason: {
      type: String,
      trim: true,
      default: null,
      maxlength: 1000,
    },
    acceptedAt: {
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
    collection: 'work_orders',
  }
);

workOrderSchema.index({ companyId: 1, jobNumber: 1 }, { unique: true });
workOrderSchema.index({ companyId: 1, status: 1, createdAt: -1 });
workOrderSchema.index({ companyId: 1, assignedTechnicianId: 1, status: 1 });
workOrderSchema.index({ companyId: 1, assignedTechnicianIds: 1, status: 1 });
workOrderSchema.index({ companyId: 1, scheduledAt: 1 });
// Soft-delete list / dashboard WO match: companyId + deletedAt + createdAt.
workOrderSchema.index({ companyId: 1, deletedAt: 1, createdAt: -1 });

const WorkOrder = mongoose.model('WorkOrder', workOrderSchema);

export default WorkOrder;
