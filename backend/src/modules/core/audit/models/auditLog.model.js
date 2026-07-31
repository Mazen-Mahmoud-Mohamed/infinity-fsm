import mongoose from 'mongoose';

const { Schema } = mongoose;

const auditLogSchema = new Schema(
  {
    companyId: {
      type: Schema.Types.ObjectId,
      ref: 'Company',
      default: null,
    },
    actorId: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      default: null,
    },
    actorRole: {
      type: String,
      default: null,
    },
    action: {
      type: String,
      required: true,
      index: true,
    },
    module: {
      type: String,
      required: true,
    },
    resourceType: {
      type: String,
      required: true,
    },
    resourceId: {
      type: Schema.Types.ObjectId,
      default: null,
    },
    metadata: {
      type: Schema.Types.Mixed,
      default: null,
    },
    ipAddress: {
      type: String,
      default: null,
    },
    userAgent: {
      type: String,
      default: null,
    },
  },
  {
    timestamps: { createdAt: true, updatedAt: false },
    collection: 'audit_logs',
  }
);

auditLogSchema.index({ companyId: 1, createdAt: -1 });
auditLogSchema.index({ companyId: 1, actorId: 1, createdAt: -1 });

auditLogSchema.pre('findOneAndUpdate', function blockUpdate() {
  throw new Error('Audit logs are immutable and cannot be updated');
});

auditLogSchema.pre('updateOne', function blockUpdate() {
  throw new Error('Audit logs are immutable and cannot be updated');
});

auditLogSchema.pre('deleteOne', function blockDelete() {
  throw new Error('Audit logs are immutable and cannot be deleted');
});

const AuditLog = mongoose.model('AuditLog', auditLogSchema);

export default AuditLog;
