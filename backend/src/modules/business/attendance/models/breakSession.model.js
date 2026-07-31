import mongoose from 'mongoose';
import { gpsSchema } from './shared.schemas.js';

const { Schema } = mongoose;

const breakSessionSchema = new Schema(
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
    attendanceId: {
      type: Schema.Types.ObjectId,
      ref: 'Attendance',
      required: true,
      index: true,
    },
    status: {
      type: String,
      enum: ['ACTIVE', 'COMPLETED'],
      default: 'ACTIVE',
    },
    startAt: { type: Date, required: true },
    startGps: { type: gpsSchema, required: true },
    startClientEventId: { type: String, required: true },
    endAt: { type: Date, default: null },
    endGps: { type: gpsSchema, default: null },
    endClientEventId: { type: String, default: null },
    durationMinutes: { type: Number, default: 0 },
  },
  {
    timestamps: true,
    collection: 'attendance_break_sessions',
  }
);

breakSessionSchema.index({ attendanceId: 1, status: 1 });
breakSessionSchema.index({ companyId: 1, userId: 1, startAt: -1 });

const BreakSession = mongoose.model('BreakSession', breakSessionSchema);

export default BreakSession;
