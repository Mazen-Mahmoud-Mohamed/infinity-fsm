import mongoose from 'mongoose';

const { Schema } = mongoose;

const attendanceSummarySchema = new Schema(
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
    },
    date: {
      type: String,
      required: true,
    },
    status: {
      type: String,
      enum: ['CLOCKED_IN', 'ON_BREAK', 'CLOCKED_OUT'],
      required: true,
    },
    clockInAt: { type: Date, default: null },
    clockOutAt: { type: Date, default: null },
    workingMinutes: { type: Number, default: 0 },
    breakMinutes: { type: Number, default: 0 },
    breakCount: { type: Number, default: 0 },
  },
  {
    timestamps: true,
    collection: 'attendance_summaries',
  }
);

attendanceSummarySchema.index({ companyId: 1, userId: 1, date: 1 }, { unique: true });
attendanceSummarySchema.index({ companyId: 1, userId: 1, date: -1 });

const AttendanceSummary = mongoose.model('AttendanceSummary', attendanceSummarySchema);

export default AttendanceSummary;
