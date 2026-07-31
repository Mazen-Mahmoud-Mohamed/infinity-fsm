import mongoose from 'mongoose';

const { Schema } = mongoose;

const citySchema = new Schema(
  {
    companyId: {
      type: Schema.Types.ObjectId,
      ref: 'Company',
      required: true,
      index: true,
    },
    branchId: {
      type: Schema.Types.ObjectId,
      ref: 'Branch',
      required: true,
    },
    regionId: {
      type: Schema.Types.ObjectId,
      ref: 'Region',
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
    collection: 'cities',
  }
);

citySchema.index({ regionId: 1, code: 1 }, { unique: true });
citySchema.index({ companyId: 1, regionId: 1 });

const City = mongoose.model('City', citySchema);

export default City;
