import mongoose from 'mongoose';

const { Schema } = mongoose;

const deviceInfoSchema = new Schema(
  {
    platform: { type: String, trim: true },
    manufacturer: { type: String, trim: true },
    phoneModel: { type: String, trim: true },
    osVersion: { type: String, trim: true },
    appVersion: { type: String, trim: true },
  },
  { _id: false }
);

const refreshTokenSchema = new Schema(
  {
    userId: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    tokenHash: {
      type: String,
      required: true,
      unique: true,
    },
    deviceId: {
      type: String,
      required: true,
      trim: true,
    },
    deviceInfo: {
      type: deviceInfoSchema,
      default: null,
    },
    expiresAt: {
      type: Date,
      required: true,
    },
    revokedAt: {
      type: Date,
      default: null,
    },
  },
  {
    timestamps: true,
    collection: 'refresh_tokens',
  }
);

refreshTokenSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 });
refreshTokenSchema.index({ userId: 1, deviceId: 1 });

const RefreshToken = mongoose.model('RefreshToken', refreshTokenSchema);

export default RefreshToken;
