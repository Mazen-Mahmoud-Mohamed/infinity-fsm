import mongoose from 'mongoose';

const { Schema } = mongoose;

export const ASSET_STATUSES = Object.freeze([
  'ACTIVE',
  'MAINTENANCE',
  'OFFLINE',
  'RETIRED',
]);

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

const gpsSchema = new Schema(
  {
    latitude: { type: Number, default: null },
    longitude: { type: Number, default: null },
    accuracy: { type: Number, default: null },
    address: { type: String, trim: true, default: null, maxlength: 500 },
  },
  { _id: false }
);

const locationSchema = new Schema(
  {
    branchId: { type: Schema.Types.ObjectId, ref: 'Branch', default: null },
    regionId: { type: Schema.Types.ObjectId, ref: 'Region', default: null },
    cityId: { type: Schema.Types.ObjectId, ref: 'City', default: null },
    branchName: { type: String, trim: true, default: null, maxlength: 200 },
    regionName: { type: String, trim: true, default: null, maxlength: 200 },
    cityName: { type: String, trim: true, default: null, maxlength: 200 },
  },
  { _id: false }
);

const assetSchema = new Schema(
  {
    companyId: {
      type: Schema.Types.ObjectId,
      ref: 'Company',
      required: true,
      index: true,
    },
    assetNumber: {
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
    categoryId: {
      type: Schema.Types.ObjectId,
      ref: 'AssetCategory',
      default: null,
      index: true,
    },
    serialNumber: {
      type: String,
      trim: true,
      default: null,
      maxlength: 120,
      index: true,
    },
    manufacturer: {
      type: String,
      trim: true,
      default: null,
      maxlength: 200,
    },
    model: {
      type: String,
      trim: true,
      default: null,
      maxlength: 200,
    },
    installationDate: {
      type: Date,
      default: null,
    },
    warrantyExpiry: {
      type: Date,
      default: null,
      index: true,
    },
    status: {
      type: String,
      enum: ASSET_STATUSES,
      default: 'ACTIVE',
      index: true,
    },
    location: {
      type: locationSchema,
      default: () => ({}),
    },
    gps: {
      type: gpsSchema,
      default: () => ({}),
    },
    qrCode: {
      type: String,
      trim: true,
      default: null,
      maxlength: 200,
      index: true,
    },
    barcode: {
      type: String,
      trim: true,
      default: null,
      maxlength: 200,
      index: true,
    },
    customer: {
      type: String,
      trim: true,
      default: null,
      maxlength: 200,
    },
    notes: {
      type: String,
      trim: true,
      default: null,
      maxlength: 5000,
    },
    image: {
      type: imageSchema,
      default: null,
    },
    deletedAt: {
      type: Date,
      default: null,
      index: true,
    },
  },
  {
    timestamps: true,
    collection: 'assets',
  }
);

assetSchema.index(
  { companyId: 1, assetNumber: 1 },
  { unique: true, partialFilterExpression: { deletedAt: null } }
);

assetSchema.index({ companyId: 1, name: 1, deletedAt: 1 });
assetSchema.index({ companyId: 1, status: 1, deletedAt: 1 });
assetSchema.index({ companyId: 1, 'location.branchId': 1, deletedAt: 1 });

const Asset = mongoose.model('Asset', assetSchema);

export default Asset;
