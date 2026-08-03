import mongoose from 'mongoose';

const { Schema } = mongoose;

export const gpsSchema = new Schema(
  {
    latitude: { type: Number, required: true },
    longitude: { type: Number, required: true },
    accuracy: { type: Number, required: true },
    heading: { type: Number, default: null },
    speed: { type: Number, default: null },
    altitude: { type: Number, default: null },
    provider: { type: String, default: null },
    recordedAt: { type: Date, required: true },
    // Reverse-geocoded address (additive — may be filled later after offline sync)
    fullAddress: { type: String, default: null, trim: true, maxlength: 500 },
    street: { type: String, default: null, trim: true, maxlength: 200 },
    area: { type: String, default: null, trim: true, maxlength: 200 },
    city: { type: String, default: null, trim: true, maxlength: 120 },
    country: { type: String, default: null, trim: true, maxlength: 120 },
    addressResolvedAt: { type: Date, default: null },
  },
  { _id: false }
);

export const actionRecordSchema = new Schema(
  {
    at: { type: Date, required: true },
    gps: { type: gpsSchema, required: true },
    selfieUrl: { type: String, required: true },
    deviceId: { type: String, required: true },
    clientEventId: { type: String, required: true },
    clientRecordedAt: { type: Date, default: null },
    source: {
      type: String,
      enum: ['ONLINE', 'OFFLINE_SYNC'],
      default: 'ONLINE',
    },
  },
  { _id: false }
);
