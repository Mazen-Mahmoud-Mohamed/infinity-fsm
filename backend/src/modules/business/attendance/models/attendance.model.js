import mongoose from 'mongoose';
import { actionRecordSchema } from './shared.schemas.js';

const { Schema } = mongoose;

const attendanceSchema = new Schema(
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
    date: {
      type: String,
      required: true,
    },
    status: {
      type: String,
      enum: ['CLOCKED_IN', 'ON_BREAK', 'CLOCKED_OUT'],
      required: true,
      default: 'CLOCKED_IN',
    },
    clockIn: {
      type: actionRecordSchema,
      required: true,
    },
    clockOut: {
      type: actionRecordSchema,
      default: null,
    },
    activeBreakId: {
      type: Schema.Types.ObjectId,
      ref: 'BreakSession',
      default: null,
    },
    activeBreakStartAt: {
      type: Date,
      default: null,
    },
    breakCount: {
      type: Number,
      default: 0,
    },
    breakMinutes: {
      type: Number,
      default: 0,
    },
    workingMinutes: {
      type: Number,
      default: 0,
    },
  },
  {
    timestamps: true,
    collection: 'attendance_records',
  }
);

attendanceSchema.index({ companyId: 1, userId: 1, date: 1 }, { unique: true });
attendanceSchema.index({ companyId: 1, userId: 1, createdAt: -1 });
// Dashboard admin aggregates filter by companyId + createdAt range.
attendanceSchema.index({ companyId: 1, createdAt: -1 });
// Live "currently working" KPI: companyId + date (+ status).
attendanceSchema.index({ companyId: 1, date: -1, status: 1 });

const Attendance = mongoose.model('Attendance', attendanceSchema);

export default Attendance;
