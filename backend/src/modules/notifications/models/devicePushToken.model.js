import mongoose from 'mongoose';

/**
 * Multi-device FCM / platform push tokens.
 * One document per token; a user may have many active tokens.
 */
const devicePushTokenSchema = new mongoose.Schema(
  {
    companyId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Company',
      required: true,
      index: true,
    },
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    token: {
      type: String,
      required: true,
      trim: true,
    },
    platform: {
      type: String,
      enum: ['android', 'ios', 'windows', 'web', 'unknown'],
      default: 'unknown',
    },
    /** App locale preference for push title/body (ar | en). */
    locale: {
      type: String,
      enum: ['ar', 'en'],
      default: 'ar',
    },
    /** Stable client device id when available (not trusted as auth). */
    deviceId: {
      type: String,
      trim: true,
      default: null,
    },
    active: {
      type: Boolean,
      default: true,
      index: true,
    },
    lastSeenAt: {
      type: Date,
      default: Date.now,
    },
    deactivatedAt: {
      type: Date,
      default: null,
    },
    deactivationReason: {
      type: String,
      default: null,
    },
  },
  {
    timestamps: true,
    collection: 'device_push_tokens',
  }
);

devicePushTokenSchema.index({ token: 1 }, { unique: true });
devicePushTokenSchema.index({ userId: 1, active: 1 });
devicePushTokenSchema.index({ companyId: 1, userId: 1, active: 1 });

const DevicePushToken = mongoose.model('DevicePushToken', devicePushTokenSchema);

export default DevicePushToken;
