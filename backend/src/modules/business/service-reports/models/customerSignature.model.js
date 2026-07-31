import mongoose from 'mongoose';

const { Schema } = mongoose;

const signatureImageSchema = new Schema(
  {
    url: { type: String, required: true },
    publicId: { type: String, default: null },
    fileName: { type: String, default: null },
    mimeType: { type: String, default: null },
    uploadedAt: { type: Date, default: Date.now },
  },
  { _id: false }
);

const customerSignatureSchema = new Schema(
  {
    companyId: {
      type: Schema.Types.ObjectId,
      ref: 'Company',
      required: true,
      index: true,
    },
    // Future Work Order link — stored only; no WO integration in Phase 1
    workOrderId: {
      type: Schema.Types.ObjectId,
      ref: 'WorkOrder',
      default: null,
      index: true,
    },
    workOrderNumber: {
      type: String,
      trim: true,
      default: null,
      maxlength: 100,
    },
    customerName: {
      type: String,
      required: true,
      trim: true,
      maxlength: 200,
    },
    customerPosition: {
      type: String,
      trim: true,
      default: null,
      maxlength: 200,
    },
    signatureImage: {
      type: signatureImageSchema,
      required: true,
    },
    signedAt: {
      type: Date,
      required: true,
      default: Date.now,
      index: true,
    },
    notes: {
      type: String,
      trim: true,
      default: null,
      maxlength: 5000,
    },
    createdBy: {
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
    collection: 'customer_signatures',
  }
);

customerSignatureSchema.index({ companyId: 1, signedAt: -1 });
customerSignatureSchema.index({ companyId: 1, customerName: 1 });

const CustomerSignature = mongoose.model(
  'CustomerSignature',
  customerSignatureSchema
);

export default CustomerSignature;
