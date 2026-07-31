import mongoose from 'mongoose';

const { Schema } = mongoose;

const departmentSchema = new Schema(
  {
    companyId: {
      type: Schema.Types.ObjectId,
      ref: 'Company',
      required: true,
      index: true,
    },
    branchId: {
      type: Schema.Types.ObjectId,
      ref: 'Branch',
      required: true,
    },
    regionId: {
      type: Schema.Types.ObjectId,
      ref: 'Region',
      required: true,
    },
    cityId: {
      type: Schema.Types.ObjectId,
      ref: 'City',
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
    supervisorIds: [{
      type: Schema.Types.ObjectId,
      ref: 'User',
    }],
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
    collection: 'departments',
  }
);

departmentSchema.index({ cityId: 1, code: 1 }, { unique: true });
departmentSchema.index({ companyId: 1, cityId: 1 });

const Department = mongoose.model('Department', departmentSchema);

export default Department;
