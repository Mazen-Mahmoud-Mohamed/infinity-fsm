import mongoose from 'mongoose';

const { Schema } = mongoose;

const assetCategorySchema = new Schema(
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
      maxlength: 2000,
    },
    icon: {
      type: String,
      trim: true,
      default: null,
      maxlength: 80,
    },
    isActive: {
      type: Boolean,
      default: true,
      index: true,
    },
    deletedAt: {
      type: Date,
      default: null,
      index: true,
    },
  },
  {
    timestamps: true,
    collection: 'asset_categories',
  }
);

assetCategorySchema.index(
  { companyId: 1, code: 1 },
  { unique: true, partialFilterExpression: { deletedAt: null } }
);

assetCategorySchema.index({ companyId: 1, name: 1, deletedAt: 1 });

const AssetCategory = mongoose.model('AssetCategory', assetCategorySchema);

export default AssetCategory;
