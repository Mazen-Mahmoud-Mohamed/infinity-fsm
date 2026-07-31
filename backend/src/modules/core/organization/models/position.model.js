import mongoose from 'mongoose';

const { Schema } = mongoose;

const positionSchema = new Schema(
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
      maxlength: 500,
    },
    isActive: {
      type: Boolean,
      default: true,
    },
    deletedAt: {
      type: Date,
      default: null,
    },
  },
  {
    timestamps: true,
    collection: 'positions',
  }
);

positionSchema.index({ companyId: 1, code: 1 }, { unique: true });
positionSchema.index({ companyId: 1, isActive: 1 });

const Position = mongoose.model('Position', positionSchema);

export default Position;
