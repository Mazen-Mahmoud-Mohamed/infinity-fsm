import mongoose from 'mongoose';

const { Schema } = mongoose;

export const ASSET_HISTORY_TYPES = Object.freeze([
  'INSTALLATION',
  'MAINTENANCE',
  'REPAIR',
  'INSPECTION',
  'STATUS_CHANGE',
  'CREATED',
  'UPDATED',
]);

const assetHistorySchema = new Schema(
  {
    companyId: {
      type: Schema.Types.ObjectId,
      ref: 'Company',
      required: true,
      index: true,
    },
    assetId: {
      type: Schema.Types.ObjectId,
      ref: 'Asset',
      required: true,
      index: true,
    },
    type: {
      type: String,
      enum: ASSET_HISTORY_TYPES,
      required: true,
      index: true,
    },
    title: {
      type: String,
      trim: true,
      default: null,
      maxlength: 200,
    },
    description: {
      type: String,
      trim: true,
      default: null,
      maxlength: 2000,
    },
    fromStatus: {
      type: String,
      default: null,
    },
    toStatus: {
      type: String,
      default: null,
    },
    eventDate: {
      type: Date,
      required: true,
      default: Date.now,
      index: true,
    },
    userId: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    userName: {
      type: String,
      trim: true,
      default: null,
    },
    metadata: {
      type: Schema.Types.Mixed,
      default: null,
    },
  },
  {
    timestamps: true,
    collection: 'asset_history',
  }
);

assetHistorySchema.index({ companyId: 1, assetId: 1, eventDate: -1 });
assetHistorySchema.index({ companyId: 1, type: 1, eventDate: -1 });

const AssetHistory = mongoose.model('AssetHistory', assetHistorySchema);

export default AssetHistory;
