import mongoose from 'mongoose';

const { Schema } = mongoose;

const companyAddressSchema = new Schema(
  {
    line1: { type: String, trim: true, default: null, maxlength: 200 },
    line2: { type: String, trim: true, default: null, maxlength: 200 },
    city: { type: String, trim: true, default: null, maxlength: 120 },
    governorate: { type: String, trim: true, default: null, maxlength: 120 },
    country: { type: String, trim: true, default: null, maxlength: 120 },
    postalCode: { type: String, trim: true, default: null, maxlength: 40 },
  },
  { _id: false }
);

const companySchema = new Schema(
  {
    name: {
      type: String,
      required: true,
      trim: true,
      maxlength: 200,
    },
    slug: {
      type: String,
      required: true,
      unique: true,
      lowercase: true,
      trim: true,
    },
    logoUrl: {
      type: String,
      default: null,
    },
    logoPublicId: {
      type: String,
      default: null,
    },
    contactEmail: {
      type: String,
      trim: true,
      lowercase: true,
      default: null,
      maxlength: 200,
    },
    contactPhone: {
      type: String,
      trim: true,
      default: null,
      maxlength: 40,
    },
    address: {
      type: companyAddressSchema,
      default: () => ({}),
    },
    timezone: {
      type: String,
      trim: true,
      default: 'Africa/Cairo',
      maxlength: 80,
    },
    isActive: {
      type: Boolean,
      default: true,
    },
    enabledModules: {
      type: [String],
      default: ['overtime'],
    },
  },
  {
    timestamps: true,
    collection: 'companies',
  }
);

companySchema.index({ isActive: 1 });

const Company = mongoose.model('Company', companySchema);

export default Company;
