import mongoose from 'mongoose';

const { Schema } = mongoose;

const warehouseSchema = new Schema(
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
      type: String,
      trim: true,
      default: null,
      maxlength: 500,
    },
    description: {
      type: String,
      trim: true,
      default: null,
      maxlength: 2000,
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
    collection: 'warehouses',
  }
);

warehouseSchema.index(
  { companyId: 1, code: 1 },
  {
    unique: true,
    partialFilterExpression: { deletedAt: null },
  }
);

warehouseSchema.index({ companyId: 1, name: 1, deletedAt: 1 });

const Warehouse = mongoose.model('Warehouse', warehouseSchema);

export default Warehouse;
