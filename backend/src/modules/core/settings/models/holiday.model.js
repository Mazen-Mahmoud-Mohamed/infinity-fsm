import mongoose from 'mongoose';

const { Schema } = mongoose;

/**
 * Company-scoped official holiday calendar dates.
 * `date` is a Gregorian Africa/Cairo calendar key: YYYY-MM-DD (no time).
 */
const holidaySchema = new Schema(
  {
    companyId: {
      type: Schema.Types.ObjectId,
      ref: 'Company',
      required: true,
      index: true,
    },
    date: {
      type: String,
      required: true,
      trim: true,
      match: /^\d{4}-\d{2}-\d{2}$/,
    },
    name: {
      type: String,
      trim: true,
      maxlength: 200,
      default: null,
    },
    createdBy: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
  },
  {
    timestamps: true,
    collection: 'holidays',
  }
);

holidaySchema.index({ companyId: 1, date: 1 }, { unique: true });

const Holiday = mongoose.model('Holiday', holidaySchema);

export default Holiday;
