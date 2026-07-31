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
overtimeRecordSchema.index({ companyId: 1, userId: 1, clientRequestId: 1 }, { unique: true });
overtimeRecordSchema.index({ companyId: 1, userId: 1, createdAt: -1 });
overtimeRecordSchema.index({ companyId: 1, status: 1, createdAt: -1 });

const OvertimeRecord = mongoose.model('OvertimeRecord', overtimeRecordSchema);

export default OvertimeRecord;
