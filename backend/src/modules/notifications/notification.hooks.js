import {
  notifyUsers,
  findManagementRecipientIds,
} from './notifications.service.js';
import logger from '../../shared/utils/logger.util.js';

function displayName(user) {
  if (!user) return '';
  const name = [user.firstName, user.lastName].filter(Boolean).join(' ').trim();
  return name || user.fullName || user.email || 'Technician';
}

function toIdList(ids) {
  return [...new Set((ids || []).map((id) => id?.toString?.() ?? String(id || '')).filter(Boolean))];
}

/**
 * Fire-and-forget helper — never rejects to callers.
 */
function safeNotify(promise) {
  Promise.resolve(promise).catch((error) => {
    logger.error({ err: error }, 'Notification hook failed');
  });
}

/**
 * Work order created/assigned → notify each assigned technician.
 */
export function notifyWorkOrderAssigned({
  io,
  companyId,
  workOrder,
  actor,
  newlyAssignedTechnicianIds,
  event = 'assigned',
}) {
  const recipients = toIdList(newlyAssignedTechnicianIds);
  if (!recipients.length) return;

  const jobNumber = workOrder.jobNumber || '';
  const workOrderId = workOrder._id?.toString?.() || String(workOrder.id || '');

  safeNotify(
    notifyUsers({
      io,
      companyId,
      recipientUserIds: recipients,
      type: 'WORK_ORDER_ASSIGNED',
      module: 'work_orders',
      titleAr: 'أمر شغل جديد',
      titleEn: 'New Work Order',
      bodyAr: jobNumber
        ? `تم تعيين أمر الشغل ${jobNumber} لك.`
        : 'تم تعيين أمر شغل جديد لك.',
      bodyEn: jobNumber
        ? `Work order ${jobNumber} was assigned to you.`
        : 'A new work order was assigned to you.',
      entityType: 'work_order',
      entityId: workOrderId,
      actorId: actor?._id || null,
      actorName: displayName(actor),
      dedupeKey: `wo:${workOrderId}:${event}:${recipients.sort().join(',')}`,
      data: {
        type: 'work_order',
        workOrderId,
        entityId: workOrderId,
        event,
        jobNumber,
      },
    })
  );
}

/**
 * Work order status change that needs management attention.
 */
export async function notifyWorkOrderStatusForManagers({
  io,
  companyId,
  workOrder,
  actor,
  event,
  titleAr,
  titleEn,
  bodyAr,
  bodyEn,
}) {
  const recipients = await findManagementRecipientIds(companyId, {
    excludeUserId: actor?._id,
  });
  if (!recipients.length) return;

  const workOrderId = workOrder._id?.toString?.() || String(workOrder.id || '');
  const jobNumber = workOrder.jobNumber || '';

  safeNotify(
    notifyUsers({
      io,
      companyId,
      recipientUserIds: recipients,
      type: `WORK_ORDER_${String(event || 'UPDATED').toUpperCase()}`,
      module: 'work_orders',
      titleAr,
      titleEn,
      bodyAr,
      bodyEn,
      entityType: 'work_order',
      entityId: workOrderId,
      actorId: actor?._id || null,
      actorName: displayName(actor),
      dedupeKey: `wo:${workOrderId}:${event}:managers`,
      data: {
        type: 'work_order',
        workOrderId,
        entityId: workOrderId,
        event,
        jobNumber,
      },
    })
  );
}

/**
 * Overtime lifecycle → notify admins/supervisors.
 */
export async function notifyOvertimeEvent({
  io,
  companyId,
  overtime,
  actor,
  event,
  titleAr,
  titleEn,
  bodyAr,
  bodyEn,
}) {
  const recipients = await findManagementRecipientIds(companyId, {
    excludeUserId: null,
  });
  // Still notify managers even if actor is also admin (they want to see it on Windows).
  // Exclude only when actor is the sole recipient would be odd — keep all managers.
  if (!recipients.length) return;

  const overtimeId = overtime._id?.toString?.() || String(overtime.id || '');
  const techName = displayName(actor);

  safeNotify(
    notifyUsers({
      io,
      companyId,
      recipientUserIds: recipients,
      type: `OVERTIME_${String(event || 'UPDATE').toUpperCase()}`,
      module: 'overtime',
      titleAr,
      titleEn,
      bodyAr: bodyAr.replace('{name}', techName),
      bodyEn: bodyEn.replace('{name}', techName),
      entityType: 'overtime',
      entityId: overtimeId,
      actorId: actor?._id || null,
      actorName: techName,
      dedupeKey: `ot:${overtimeId}:${event}`,
      data: {
        type: 'overtime',
        overtimeId,
        entityId: overtimeId,
        event,
      },
    })
  );
}

export default {
  notifyWorkOrderAssigned,
  notifyWorkOrderStatusForManagers,
  notifyOvertimeEvent,
};
