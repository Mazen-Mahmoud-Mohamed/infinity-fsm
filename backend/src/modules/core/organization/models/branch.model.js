import mongoose from 'mongoose';

const { Schema } = mongoose;

const branchSchema = new Schema(
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
    address: {
      street: { type: String, trim: true },
      city: { type: String, trim: true },
      governorate: { type: String, trim: true },
      country: { type: String, trim: true, default: 'Iraq' },
    },
    isActive: {
      type: Boolean,
      default: true,
    },
    deletedAt: {
      type: Date,
      default: null,
    },
  },
  {
    timestamps: true,
    collection: 'branches',
  }
);

branchSchema.index({ companyId: 1, code: 1 }, { unique: true });
branchSchema.index({ companyId: 1, isActive: 1 });

const Branch = mongoose.model('Branch', branchSchema);

export default Branch;
