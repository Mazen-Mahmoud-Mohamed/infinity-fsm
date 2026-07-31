import mongoose from 'mongoose';

const { Schema } = mongoose;

export const USER_ACTIVITY_ACTIONS = Object.freeze([
  'CREATED',
  'UPDATED',
  'ENABLED',
  'DISABLED',
  'LOCKED',
  'UNLOCKED',
  'PASSWORD_RESET',
  'PASSWORD_CHANGED',
  'AVATAR_UPDATED',
  'DELETED',
]);

const userActivitySchema = new Schema(
  {
    companyId: {
      type: Schema.Types.ObjectId,
      ref: 'Company',
      required: true,
      index: true,
    },
    userId: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    actorId: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      default: null,
    },
    action: {
      type: String,
      enum: USER_ACTIVITY_ACTIONS,
      required: true,
      index: true,
    },
    summary: {
      type: String,
      trim: true,
      default: null,
      maxlength: 500,
    },
    metadata: {
      type: Schema.Types.Mixed,
      default: {},
    },
  },
  {
    timestamps: { createdAt: true, updatedAt: false },
    collection: 'user_activities',
  }
);

userActivitySchema.index({ companyId: 1, userId: 1, createdAt: -1 });

const UserActivity = mongoose.model('UserActivity', userActivitySchema);

export default UserActivity;
