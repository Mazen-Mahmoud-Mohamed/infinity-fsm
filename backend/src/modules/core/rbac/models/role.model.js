import mongoose from 'mongoose';

const { Schema } = mongoose;

const roleSchema = new Schema(
  {
    companyId: {
      type: Schema.Types.ObjectId,
      ref: 'Company',
      default: null,
      index: true,
    },
    name: {
      type: String,
      required: true,
      trim: true,
      maxlength: 120,
    },
    slug: {
      type: String,
      required: true,
      trim: true,
      uppercase: true,
      maxlength: 80,
    },
    description: {
      type: String,
      trim: true,
      default: null,
      maxlength: 2000,
    },
    permissions: {
      type: [String],
      default: [],
    },
    color: {
      type: String,
      trim: true,
      default: '#1565C0',
      maxlength: 32,
    },
    isSystem: {
      type: Boolean,
      default: false,
      index: true,
    },
    isActive: {
      type: Boolean,
      default: true,
      index: true,
    },
    createdBy: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      default: null,
    },
    updatedBy: {
      type: Schema.Types.ObjectId,
      ref: 'User',
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
    collection: 'roles',
  }
);

// System roles: unique slug globally (companyId null)
// Custom roles: unique slug per company
roleSchema.index(
  { companyId: 1, slug: 1 },
  {
    unique: true,
    partialFilterExpression: { deletedAt: null },
  }
);
roleSchema.index({ companyId: 1, name: 1, deletedAt: 1 });
roleSchema.index({ isSystem: 1, isActive: 1 });

const Role = mongoose.model('Role', roleSchema);

export default Role;
