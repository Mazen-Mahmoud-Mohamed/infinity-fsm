import mongoose from 'mongoose';
import bcrypt from 'bcrypt';
import { getPermissionsForRoles } from '../../../../shared/constants/permissions.constants.js';

const { Schema } = mongoose;

const SALT_ROUNDS = 12;

export const USER_STATUSES = Object.freeze(['ACTIVE', 'DISABLED', 'LOCKED']);

const permissionOverrideSchema = new Schema(
  {
    permission: { type: String, required: true },
    type: { type: String, enum: ['grant', 'deny'], required: true },
  },
  { _id: false }
);

const userSchema = new Schema(
  {
    companyId: {
      type: Schema.Types.ObjectId,
      ref: 'Company',
      required: true,
      index: true,
    },
    employeeId: {
      type: String,
      required: true,
      trim: true,
      maxlength: 50,
    },
    username: {
      type: String,
      trim: true,
      lowercase: true,
      maxlength: 80,
      default: null,
    },
    email: {
      type: String,
      required: true,
      unique: true,
      lowercase: true,
      trim: true,
    },
    passwordHash: {
      type: String,
      required: true,
      select: false,
    },
    firstName: {
      type: String,
      required: true,
      trim: true,
      maxlength: 100,
    },
    lastName: {
      type: String,
      required: true,
      trim: true,
      maxlength: 100,
    },
    phone: {
      type: String,
      trim: true,
      default: null,
    },
    jobTitle: {
      type: String,
      trim: true,
      default: null,
      maxlength: 200,
    },
    avatarUrl: {
      type: String,
      default: null,
    },
    avatarPublicId: {
      type: String,
      default: null,
    },
    roles: {
      type: [String],
      required: true,
      validate: {
        validator: (roles) =>
          Array.isArray(roles) &&
          roles.length > 0 &&
          roles.every(
            (role) => typeof role === 'string' && role.trim().length > 0
          ),
        message: 'User must have at least one role',
      },
    },
    permissionOverrides: {
      type: [permissionOverrideSchema],
      default: [],
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
    },
    departmentId: {
      type: Schema.Types.ObjectId,
      ref: 'Department',
      required: true,
    },
    teamId: {
      type: Schema.Types.ObjectId,
      ref: 'Team',
      default: null,
    },
    positionId: {
      type: Schema.Types.ObjectId,
      ref: 'Position',
      default: null,
    },
    status: {
      type: String,
      enum: USER_STATUSES,
      default: 'ACTIVE',
      index: true,
    },
    isActive: {
      type: Boolean,
      default: true,
    },
    lastLoginAt: {
      type: Date,
      default: null,
    },
    lastSeenAt: {
      type: Date,
      default: null,
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
    },
  },
  {
    timestamps: true,
    collection: 'users',
  }
);

userSchema.index({ companyId: 1, employeeId: 1 }, { unique: true });
userSchema.index({ companyId: 1, departmentId: 1, isActive: 1 });
userSchema.index(
  { companyId: 1, username: 1 },
  {
    unique: true,
    partialFilterExpression: { username: { $type: 'string' } },
  }
);
userSchema.index({ companyId: 1, status: 1, deletedAt: 1 });

userSchema.virtual('fullName').get(function fullName() {
  return `${this.firstName} ${this.lastName}`;
});

userSchema.set('toJSON', {
  virtuals: true,
  transform(_doc, ret) {
    delete ret.passwordHash;
    delete ret.__v;
    return ret;
  },
});

userSchema.methods.getPermissions = function getPermissions() {
  const permissions = new Set(getPermissionsForRoles(this.roles));

  for (const override of this.permissionOverrides || []) {
    if (override.type === 'grant') {
      permissions.add(override.permission);
    } else if (override.type === 'deny') {
      permissions.delete(override.permission);
    }
  }

  return Array.from(permissions);
};

userSchema.methods.comparePassword = async function comparePassword(candidatePassword) {
  return bcrypt.compare(candidatePassword, this.passwordHash);
};

userSchema.statics.hashPassword = async function hashPassword(plainPassword) {
  return bcrypt.hash(plainPassword, SALT_ROUNDS);
};

userSchema.statics.syncActiveFromStatus = function syncActiveFromStatus(status) {
  return status === 'ACTIVE';
};

const User = mongoose.model('User', userSchema);

export default User;
