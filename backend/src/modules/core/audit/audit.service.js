import AuditLog from './models/auditLog.model.js';

class AuditService {
  async log({
    companyId,
    actorId = null,
    actorRole = null,
    action,
    module,
    resourceType,
    resourceId = null,
    metadata = null,
    ipAddress = null,
    userAgent = null,
  }) {
    return AuditLog.create({
      companyId,
      actorId,
      actorRole,
      action,
      module,
      resourceType,
      resourceId,
      metadata,
      ipAddress,
      userAgent,
    });
  }

  async logAuthEvent(req, { companyId, actorId, actorRole, action, metadata = null }) {
    return this.log({
      companyId,
      actorId,
      actorRole,
      action,
      module: 'auth',
      resourceType: 'user',
      resourceId: actorId,
      metadata,
      ipAddress: req.ip,
      userAgent: req.get('user-agent'),
    });
  }
}

export default new AuditService();
