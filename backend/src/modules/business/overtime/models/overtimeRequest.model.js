import mongoose from 'mongoose';

const { Schema } = mongoose;

const overtimeRequestSchema = new Schema(
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
    createdBy: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: true,
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
    date: {
      type: String,
      required: true,
    },
    requestedHours: {
      type: Number,
      required: true,
      min: 0,
    },
    calculatedHours: {
      type: Number,
      required: true,
      min: 0,
    },
    reason: {
      type: String,
      required: true,
      trim: true,
      maxlength: 1000,
    },
    status: {
      type: String,
      enum: ['PENDING', 'APPROVED', 'REJECTED', 'CANCELLED'],
      default: 'PENDING',
      required: true,
    },
    managerNotes: {
      type: String,
      trim: true,
      default: null,
      maxlength: 1000,
    },
    reviewedBy: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      default: null,
    },
    reviewedAt: {
      type: Date,
      default: null,
    },
  },
  {
    timestamps: true,
    collection: 'overtime_requests',
  }
);

overtimeRequestSchema.index({ companyId: 1, userId: 1, createdAt: -1 });
overtimeRequestSchema.index({ companyId: 1, departmentId: 1, status: 1 });
overtimeRequestSchema.index({ companyId: 1, status: 1, createdAt: -1 });

const OvertimeRequest = mongoose.model('OvertimeRequest', overtimeRequestSchema);

export default OvertimeRequest;
