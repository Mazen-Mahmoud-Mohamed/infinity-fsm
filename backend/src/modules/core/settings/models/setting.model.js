import mongoose from 'mongoose';

const { Schema } = mongoose;

const settingSchema = new Schema(
  {
    companyId: {
      type: Schema.Types.ObjectId,
      ref: 'Company',
      required: true,
      index: true,
    },
    key: {
      type: String,
      required: true,
      trim: true,
    },
    value: {
      type: Schema.Types.Mixed,
      required: true,
    },
    group: {
      type: String,
      required: true,
      trim: true,
    },
    dataType: {
      type: String,
      enum: ['string', 'number', 'boolean', 'array', 'object'],
      required: true,
    },
    updatedBy: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
  },
  {
    timestamps: true,
    collection: 'settings',
  }
);

settingSchema.index({ companyId: 1, key: 1 }, { unique: true });
settingSchema.index({ companyId: 1, group: 1 });

const Setting = mongoose.model('Setting', settingSchema);

export default Setting;
