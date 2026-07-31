import mongoose from 'mongoose';
import { gpsSchema } from './shared.schemas.js';

const { Schema } = mongoose;

const attendanceEventSchema = new Schema(
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
    type: {
      type: String,
      enum: ['CLOCK_IN', 'CLOCK_OUT', 'BREAK_START', 'BREAK_END'],
      required: true,
    },
    at: {
      type: Date,
      required: true,
    },
    clientEventId: {
      type: String,
      required: true,
    },
    clientRecordedAt: {
      type: Date,
      default: null,
    },
    gps: {
      type: gpsSchema,
      required: true,
    },
    selfieUrl: {
      type: String,
      default: null,
    },
    deviceId: {
      type: String,
      required: true,
    },
    source: {
      type: String,
      enum: ['ONLINE', 'OFFLINE_SYNC'],
      default: 'ONLINE',
    },
  },
  {
    timestamps: { createdAt: true, updatedAt: false },
    collection: 'attendance_events',
  }
);

attendanceEventSchema.index(
  { companyId: 1, userId: 1, clientEventId: 1 },
  { unique: true }
);
attendanceEventSchema.index({ attendanceId: 1, at: 1 });

attendanceEventSchema.pre('findOneAndUpdate', function blockUpdate() {
  throw new Error('Attendance events are immutable and cannot be updated');
});

attendanceEventSchema.pre('deleteOne', function blockDelete() {
  throw new Error('Attendance events are immutable and cannot be deleted');
});

const AttendanceEvent = mongoose.model('AttendanceEvent', attendanceEventSchema);

export default AttendanceEvent;
