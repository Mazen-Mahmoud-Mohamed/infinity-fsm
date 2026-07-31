import mongoose from 'mongoose';

const { Schema } = mongoose;

export const STOCK_MOVEMENT_TYPES = Object.freeze([
  'STOCK_IN',
  'STOCK_OUT',
  'TRANSFER',
  'ADJUSTMENT',
]);

const stockMovementSchema = new Schema(
  {
    companyId: {
      type: Schema.Types.ObjectId,
      ref: 'Company',
      required: true,
      index: true,
    },
    sparePartId: {
      type: Schema.Types.ObjectId,
      ref: 'SparePart',
      required: true,
      index: true,
    },
    type: {
      type: String,
      enum: STOCK_MOVEMENT_TYPES,
      required: true,
      index: true,
    },
    quantity: {
      type: Number,
      required: true,
      min: 0.0001,
    },
    quantityDelta: {
      type: Number,
      required: true,
    },
    quantityBefore: {
      type: Number,
      required: true,
      min: 0,
    },
    quantityAfter: {
      type: Number,
      required: true,
      min: 0,
    },
    warehouseId: {
      type: Schema.Types.ObjectId,
      ref: 'Warehouse',
      default: null,
      index: true,
    },
    fromWarehouseId: {
      type: Schema.Types.ObjectId,
      ref: 'Warehouse',
      default: null,
    },
    toWarehouseId: {
      type: Schema.Types.ObjectId,
      ref: 'Warehouse',
      default: null,
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
    movementDate: {
      type: Date,
      required: true,
      default: Date.now,
      index: true,
    },
    reason: {
      type: String,
      trim: true,
      default: null,
      maxlength: 500,
    },
    notes: {
      type: String,
      trim: true,
      default: null,
      maxlength: 2000,
    },
  },
  {
    timestamps: true,
    collection: 'stock_movements',
  }
);

stockMovementSchema.index({ companyId: 1, movementDate: -1 });
stockMovementSchema.index({ companyId: 1, sparePartId: 1, movementDate: -1 });
stockMovementSchema.index({ companyId: 1, type: 1, movementDate: -1 });

const StockMovement = mongoose.model('StockMovement', stockMovementSchema);

export default StockMovement;
