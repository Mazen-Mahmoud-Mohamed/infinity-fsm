import mongoose from 'mongoose';

const { Schema } = mongoose;

export const PM_SCHEDULE_STATUSES = Object.freeze([
  'SCHEDULED',
  'COMPLETED',
  'CANCELLED',
  'OVERDUE',
]);

const checklistResultSchema = new Schema(
  {
    checklistItemId: { type: Schema.Types.ObjectId, required: true },
    title: { type: String, trim: true, default: null },
    result: {
      type: String,
      enum: ['PASS', 'FAIL', 'NA', null],
      default: null,
    },
    notes: { type: String, trim: true, default: null, maxlength: 2000 },
    photoUrl: { type: String, default: null },
  },
  { _id: false }
);

const maintenanceScheduleSchema = new Schema(
  {
    companyId: {
      type: Schema.Types.ObjectId,
      ref: 'Company',
      required: true,
      index: true,
    },
    planId: {
      type: Schema.Types.ObjectId,
      ref: 'MaintenancePlan',
      required: true,
      index: true,
    },
    scheduledDate: {
      type: Date,
      required: true,
      index: true,
    },
    status: {
      type: String,
      enum: PM_SCHEDULE_STATUSES,
      default: 'SCHEDULED',
      index: true,
    },
    completedDate: {
      type: Date,
      default: null,
    },
    cancelledDate: {
      type: Date,
      default: null,
    },
    notes: {
      type: String,
      trim: true,
      default: null,
      maxlength: 2000,
    },
    checklistResults: {
      type: [checklistResultSchema],
      default: [],
    },
    // Reserved for future Work Order integration
    workOrderId: {
      type: Schema.Types.ObjectId,
      ref: 'WorkOrder',
      default: null,
      index: true,
    },
    completedById: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      default: null,
    },
    completedByName: {
      type: String,
      trim: true,
      default: null,
    },
  },
  {
    timestamps: true,
    collection: 'maintenance_schedules',
  }
);

maintenanceScheduleSchema.index({ companyId: 1, scheduledDate: 1, status: 1 });
maintenanceScheduleSchema.index({ companyId: 1, planId: 1, scheduledDate: 1 });
maintenanceScheduleSchema.index(
  { companyId: 1, planId: 1, scheduledDate: 1 },
  {
    unique: true,
    partialFilterExpression: { status: { $in: ['SCHEDULED', 'OVERDUE'] } },
  }
);

const MaintenanceSchedule = mongoose.model(
  'MaintenanceSchedule',
  maintenanceScheduleSchema
);

export default MaintenanceSchedule;
