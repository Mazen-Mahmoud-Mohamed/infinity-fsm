import mongoose from 'mongoose';

const { Schema } = mongoose;

export const PM_FREQUENCIES = Object.freeze([
  'DAILY',
  'WEEKLY',
  'MONTHLY',
  'QUARTERLY',
  'SEMI_ANNUAL',
  'ANNUAL',
]);

export const PM_TRIGGERS = Object.freeze(['TIME_BASED', 'METER_BASED']);

export const PM_PRIORITIES = Object.freeze(['LOW', 'MEDIUM', 'HIGH', 'CRITICAL']);

export const PM_PLAN_STATUSES = Object.freeze(['ACTIVE', 'INACTIVE']);

const checklistItemSchema = new Schema(
  {
    title: { type: String, required: true, trim: true, maxlength: 300 },
    description: { type: String, trim: true, default: null, maxlength: 2000 },
    requiresPassFail: { type: Boolean, default: true },
    requiresNotes: { type: Boolean, default: false },
    photoRequired: { type: Boolean, default: false },
    sortOrder: { type: Number, default: 0 },
  },
  { _id: true }
);

const maintenancePlanSchema = new Schema(
  {
    companyId: {
      type: Schema.Types.ObjectId,
      ref: 'Company',
      required: true,
      index: true,
    },
    name: {
      type: String,
      required: true,
      trim: true,
      maxlength: 200,
    },
    code: {
      type: String,
      required: true,
      trim: true,
      uppercase: true,
      maxlength: 50,
    },
    description: {
      type: String,
      trim: true,
      default: null,
      maxlength: 5000,
    },
    frequency: {
      type: String,
      enum: PM_FREQUENCIES,
      required: true,
      default: 'MONTHLY',
    },
    trigger: {
      type: String,
      enum: PM_TRIGGERS,
      required: true,
      default: 'TIME_BASED',
    },
    nextDueDate: {
      type: Date,
      default: null,
      index: true,
    },
    priority: {
      type: String,
      enum: PM_PRIORITIES,
      default: 'MEDIUM',
      index: true,
    },
    estimatedDurationMinutes: {
      type: Number,
      min: 0,
      default: 60,
    },
    assignedTeamId: {
      type: Schema.Types.ObjectId,
      ref: 'Team',
      default: null,
      index: true,
    },
    assignedTechnicianId: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      default: null,
      index: true,
    },
    assetId: {
      type: Schema.Types.ObjectId,
      ref: 'Asset',
      default: null,
      index: true,
    },
    meterThreshold: {
      type: Number,
      min: 0,
      default: null,
    },
    currentMeterReading: {
      type: Number,
      min: 0,
      default: null,
    },
    status: {
      type: String,
      enum: PM_PLAN_STATUSES,
      default: 'ACTIVE',
      index: true,
    },
    checklistItems: {
      type: [checklistItemSchema],
      default: [],
    },
    deletedAt: {
      type: Date,
      default: null,
      index: true,
    },
  },
  {
    timestamps: true,
    collection: 'maintenance_plans',
  }
);

maintenancePlanSchema.index(
  { companyId: 1, code: 1 },
  { unique: true, partialFilterExpression: { deletedAt: null } }
);

maintenancePlanSchema.index({ companyId: 1, status: 1, nextDueDate: 1 });
maintenancePlanSchema.index({ companyId: 1, name: 1, deletedAt: 1 });

const MaintenancePlan = mongoose.model('MaintenancePlan', maintenancePlanSchema);

export default MaintenancePlan;
export { checklistItemSchema };
