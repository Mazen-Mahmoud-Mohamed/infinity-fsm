import mongoose from 'mongoose';

const { Schema } = mongoose;

const imageSchema = new Schema(
  {
    url: { type: String, required: true },
    publicId: { type: String, default: null },
    fileName: { type: String, default: null },
    mimeType: { type: String, default: null },
    uploadedAt: { type: Date, default: Date.now },
  },
  { _id: false }
);

const sparePartSchema = new Schema(
  {
    companyId: {
      type: Schema.Types.ObjectId,
      ref: 'Company',
      required: true,
      index: true,
    },
    partNumber: {
      type: String,
      required: true,
      trim: true,
      uppercase: true,
      maxlength: 100,
    },
    name: {
      type: String,
      required: true,
      trim: true,
      maxlength: 200,
    },
    category: {
      type: String,
      trim: true,
      default: null,
      maxlength: 120,
      index: true,
    },
    description: {
      type: String,
      trim: true,
      default: null,
      maxlength: 5000,
    },
    unit: {
      type: String,
      required: true,
      trim: true,
      maxlength: 40,
      default: 'pcs',
    },
    currentQuantity: {
      type: Number,
      required: true,
      min: 0,
      default: 0,
    },
    minimumQuantity: {
      type: Number,
      required: true,
      min: 0,
      default: 0,
    },
    image: {
      type: imageSchema,
      default: null,
    },
    barcode: {
      type: String,
      trim: true,
      default: null,
      maxlength: 200,
      index: true,
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
    collection: 'spare_parts',
  }
);

sparePartSchema.index(
  { companyId: 1, partNumber: 1 },
  {
    unique: true,
    partialFilterExpression: { deletedAt: null },
  }
);

sparePartSchema.index({ companyId: 1, name: 1, deletedAt: 1 });
sparePartSchema.index({ companyId: 1, category: 1, deletedAt: 1 });
sparePartSchema.index({ companyId: 1, currentQuantity: 1, minimumQuantity: 1 });

const SparePart = mongoose.model('SparePart', sparePartSchema);

export default SparePart;
