import mongoose from 'mongoose';

/**
 * Recipient-targeted in-app + push notification records.
 */
const appNotificationSchema = new mongoose.Schema(
  {
    companyId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Company',
      required: true,
      index: true,
    },
    recipientUserId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    type: {
      type: String,
      required: true,
      index: true,
    },
    module: {
      type: String,
      required: true,
      default: 'general',
    },
    titleAr: { type: String, required: true },
    titleEn: { type: String, required: true },
    bodyAr: { type: String, required: true },
    bodyEn: { type: String, required: true },
    entityType: {
      type: String,
      enum: ['work_order', 'overtime', 'app_update', 'general', null],
      default: null,
    },
    /**
     * Related entity id. ObjectId strings for WO/OT; null for app_update
     * (version/build live in `data`).
     */
    entityId: {
      type: mongoose.Schema.Types.Mixed,
      default: null,
    },
    /** Structured navigation / event payload for clients. */
    data: {
      type: mongoose.Schema.Types.Mixed,
      default: {},
    },
    actorId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null,
    },
    actorName: {
      type: String,
      default: null,
    },
    isRead: {
      type: Boolean,
      default: false,
      index: true,
    },
    readAt: {
      type: Date,
      default: null,
    },
    /**
     * Idempotency key: company + recipient + event identity.
     * Prevents duplicate in-app rows and duplicate pushes for the same event.
     */
    dedupeKey: {
      type: String,
      required: true,
    },
  },
  {
    timestamps: true,
    collection: 'notifications',
  }
);

appNotificationSchema.index(
  { companyId: 1, recipientUserId: 1, dedupeKey: 1 },
  { unique: true }
);
appNotificationSchema.index({
  recipientUserId: 1,
  companyId: 1,
  createdAt: -1,
});
appNotificationSchema.index({
  recipientUserId: 1,
  companyId: 1,
  isRead: 1,
});

const AppNotification = mongoose.model('AppNotification', appNotificationSchema);

export default AppNotification;
