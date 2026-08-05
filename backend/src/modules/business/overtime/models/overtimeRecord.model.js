import mongoose from 'mongoose';
import { gpsSchema } from '../../attendance/models/shared.schemas.js';

const { Schema } = mongoose;

const photoRefSchema = new Schema(
  {
    url: { type: String, required: true },
    publicId: { type: String, default: null },
  },
  { _id: false }
);

/** Optional per-stage voice note metadata (Cloudinary; no binary in MongoDB). */
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

/** Single journey checkpoint capture (additive 4-stage workflow). */
const checkpointSchema = new Schema(
  {
    at: { type: Date, required: true },
    gps: { type: gpsSchema, required: true },
    photo: { type: photoRefSchema, required: true },
    voiceNote: { type: voiceNoteSchema, default: undefined },
    address: { type: String, default: null },
    deviceId: { type: String, required: true },
    /** Client-generated id for idempotent retries (double-tap / offline sync). */
    clientRequestId: { type: String, default: null, trim: true },
    batteryLevel: {
      type: Number,
      min: 0,
      max: 100,
      default: null,
    },
    networkStatus: {
      type: String,
      trim: true,
      default: null,
      maxlength: 40,
    },
    notes: {
      type: String,
      trim: true,
      default: null,
      maxlength: 1000,
    },
  },
  { _id: false }
);

const checkpointsSchema = new Schema(
  {
    startJourney: { type: checkpointSchema, default: undefined },
    arrivedAtWorkSite: { type: checkpointSchema, default: undefined },
    finishedWork: { type: checkpointSchema, default: undefined },
    endJourney: { type: checkpointSchema, default: undefined },
  },
  { _id: false }
);

const overtimeRecordSchema = new Schema(
  {
    companyId: {
      type: Schema.Types.ObjectId,
      ref: 'Company',
      required: true,
      index: true,
    },
    userId: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    branchId: {
      type: Schema.Types.ObjectId,
      ref: 'Branch',
      default: null,
    },
    departmentId: {
      type: Schema.Types.ObjectId,
      ref: 'Department',
      default: null,
    },
    type: {
      type: String,
      enum: ['NORMAL', 'TRAVEL'],
      required: true,
    },
    status: {
      type: String,
      enum: ['RUNNING', 'PENDING_REVIEW', 'APPROVED', 'REJECTED', 'CANCELLED'],
      default: 'RUNNING',
      required: true,
      index: true,
    },
    /**
     * v1 = legacy start/end only (historical + unfinished pre-upgrade sessions).
     * v2 = four-stage journey workflow (new sessions).
     */
    workflowVersion: {
      type: String,
      enum: ['v1', 'v2'],
      default: 'v1',
      index: true,
    },
    checkpoints: {
      type: checkpointsSchema,
      default: undefined,
    },
    // Legacy start/end — still authoritative for duration calculation.
    startAt: { type: Date, required: true },
    startGps: { type: gpsSchema, required: true },
    startPhoto: { type: photoRefSchema, required: true },
    startAddress: { type: String, default: null },
    startDeviceId: { type: String, required: true },
    endAt: { type: Date, default: null },
    endGps: { type: gpsSchema, default: null },
    endPhoto: { type: photoRefSchema, default: null },
    endAddress: { type: String, default: null },
    endDeviceId: { type: String, default: null },
    totalDurationMinutes: { type: Number, default: null },
    workingDurationMinutes: { type: Number, default: null },
    eligibleOvertimeMinutes: { type: Number, default: null },
    calculationVersion: { type: String, default: null },
    calculatedAt: { type: Date, default: null },
    approvedBy: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      default: null,
    },
    approvedAt: { type: Date, default: null },
    rejectedBy: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      default: null,
    },
    rejectedAt: { type: Date, default: null },
    rejectionReason: {
      type: String,
      trim: true,
      default: null,
      maxlength: 1000,
    },
    /**
     * True when session duration exceeded company soft policy
     * (maxSessionHours) and needs elevated admin attention.
     */
    requiresManualReview: {
      type: Boolean,
      default: false,
      index: true,
    },
    reviewReason: {
      type: String,
      trim: true,
      default: null,
      maxlength: 500,
    },
    /** Admin free-text notes on approve/reject (does not alter checkpoints). */
    reviewNotes: {
      type: String,
      trim: true,
      default: null,
      maxlength: 2000,
    },
    clientRequestId: { type: String, required: true },
  },
  {
    timestamps: true,
    collection: 'overtime_records',
  }
);

overtimeRecordSchema.index(
  { companyId: 1, userId: 1, status: 1 },
  { unique: true, partialFilterExpression: { status: 'RUNNING' } }
);
overtimeRecordSchema.index(
  { companyId: 1, userId: 1, clientRequestId: 1 },
  { unique: true }
);
overtimeRecordSchema.index({ companyId: 1, userId: 1, createdAt: -1 });
overtimeRecordSchema.index({ companyId: 1, status: 1, createdAt: -1 });

const OvertimeRecord = mongoose.model('OvertimeRecord', overtimeRecordSchema);

export default OvertimeRecord;
