import {
  notifyUsers,
  findManagementRecipientIds,
} from './notifications.service.js';
import logger from '../../shared/utils/logger.util.js';

function trim(value) {
  return value?.toString?.()?.trim?.() || '';
}

function displayName(user) {
  if (!user) return '';
  const name = [user.firstName, user.lastName].filter(Boolean).join(' ').trim();
  return name || user.fullName || user.email || '';
}

function toIdList(ids) {
  return [...new Set((ids || []).map((id) => id?.toString?.() ?? String(id || '')).filter(Boolean))];
}

function workOrderContext(workOrder) {
  return {
    jobNumber: trim(workOrder?.jobNumber),
    customerName: trim(workOrder?.customerName),
    locationLabel: trim(workOrder?.locationLabel),
  };
}

function customerSuffixAr(customerName) {
  return customerName ? ` لدى العميل ${customerName}` : '';
}

function customerSuffixEn(customerName) {
  return customerName ? ` for customer ${customerName}` : '';
}

function siteSuffixAr(site) {
  return site ? ` في ${site}` : '';
}

function siteSuffixEn(site) {
  return site ? ` at ${site}` : '';
}

function overtimeSiteLabel(overtime, event) {
  const checkpoints = overtime?.checkpoints || {};
  switch (event) {
    case 'arrived':
      return trim(checkpoints.arrivedAtWorkSite?.address) || trim(overtime?.startAddress);
    case 'finished_work':
      return (
        trim(checkpoints.finishedWork?.address) ||
        trim(checkpoints.arrivedAtWorkSite?.address)
      );
    case 'ended':
      return trim(overtime?.endAddress) || trim(checkpoints.endJourney?.address);
    case 'started':
      return trim(overtime?.startAddress);
    default:
      return '';
  }
}

export function buildWorkOrderAssignedCopy(workOrder) {
  const { jobNumber, customerName } = workOrderContext(workOrder);
  const customerPartAr = customerSuffixAr(customerName);
  const customerPartEn = customerSuffixEn(customerName);

  return {
    titleAr: 'أمر شغل جديد',
    titleEn: 'New Work Order',
    bodyAr: jobNumber
      ? `تم تعيين أمر الشغل ${jobNumber} لك${customerPartAr}.`
      : `تم تعيين أمر شغل جديد لك${customerPartAr}.`,
    bodyEn: jobNumber
      ? `Work order ${jobNumber} was assigned to you${customerPartEn}.`
      : `A new work order was assigned to you${customerPartEn}.`,
  };
}

export function buildWorkOrderManagerCopy(workOrder, actor, event) {
  const name = displayName(actor);
  const { jobNumber, customerName } = workOrderContext(workOrder);
  const woRefAr = jobNumber ? `أمر الشغل ${jobNumber}` : 'أمر الشغل';
  const woRefEn = jobNumber ? `work order ${jobNumber}` : 'the work order';
  const customerPartAr = customerSuffixAr(customerName);
  const customerPartEn = customerSuffixEn(customerName);

  switch (event) {
    case 'accepted':
      return {
        titleAr: 'تم قبول أمر الشغل',
        titleEn: 'Work Order Accepted',
        bodyAr: name
          ? `قام ${name} بقبول ${woRefAr}${customerPartAr}.`
          : `تم قبول ${woRefAr}${customerPartAr}.`,
        bodyEn: name
          ? `${name} accepted ${woRefEn}${customerPartEn}.`
          : `${woRefEn} was accepted${customerPartEn}.`,
      };
    case 'completed':
      return {
        titleAr: 'اكتمال أمر الشغل',
        titleEn: 'Work Order Completed',
        bodyAr: name
          ? `أنهى ${name} العمل في ${woRefAr}${customerPartAr}.`
          : `تم إكمال ${woRefAr}${customerPartAr}.`,
        bodyEn: name
          ? `${name} completed ${woRefEn}${customerPartEn}.`
          : `${woRefEn} was completed${customerPartEn}.`,
      };
    default:
      return {
        titleAr: 'تحديث أمر الشغل',
        titleEn: 'Work Order Updated',
        bodyAr: jobNumber
          ? `تم تحديث ${woRefAr}${customerPartAr}.`
          : 'تم تحديث أمر الشغل.',
        bodyEn: jobNumber
          ? `${woRefEn} was updated${customerPartEn}.`
          : 'The work order was updated.',
      };
  }
}

export function buildOvertimeCopy(overtime, actor, event) {
  const name = displayName(actor);
  const site = overtimeSiteLabel(overtime, event);
  const sitePartAr = siteSuffixAr(site);
  const sitePartEn = siteSuffixEn(site);

  switch (event) {
    case 'started':
      return {
        titleAr: 'بدء العمل الإضافي',
        titleEn: 'Overtime Started',
        bodyAr: name
          ? `بدأ ${name} العمل الإضافي.`
          : 'بدأ الفني العمل الإضافي.',
        bodyEn: name
          ? `${name} started overtime.`
          : 'The technician started overtime.',
      };
    case 'arrived':
      return {
        titleAr: 'وصول الفني إلى موقع العمل',
        titleEn: 'Technician Arrived at Site',
        bodyAr: name
          ? `وصل ${name} إلى موقع العمل${sitePartAr}.`
          : `وصل الفني إلى موقع العمل${sitePartAr}.`,
        bodyEn: name
          ? `${name} arrived at the work site${sitePartEn}.`
          : `The technician arrived at the work site${sitePartEn}.`,
      };
    case 'finished_work':
      return {
        titleAr: 'إنهاء العمل في الموقع',
        titleEn: 'Work Finished at Site',
        bodyAr: name
          ? `أنهى ${name} العمل في الموقع${sitePartAr}.`
          : `أنهى الفني العمل في الموقع${sitePartAr}.`,
        bodyEn: name
          ? `${name} finished work at the site${sitePartEn}.`
          : `The technician finished work at the site${sitePartEn}.`,
      };
    case 'ended':
      return {
        titleAr: 'إنهاء رحلة العمل الإضافي',
        titleEn: 'Overtime Journey Ended',
        bodyAr: name
          ? `أنهى ${name} رحلة العمل الإضافي.`
          : 'تم إنهاء رحلة العمل الإضافي.',
        bodyEn: name
          ? `${name} ended the overtime journey.`
          : 'The overtime journey was ended.',
      };
    default:
      return {
        titleAr: 'تحديث العمل الإضافي',
        titleEn: 'Overtime Updated',
        bodyAr: name
          ? `قام ${name} بتحديث سجل العمل الإضافي.`
          : 'تم تحديث سجل العمل الإضافي.',
        bodyEn: name
          ? `${name} updated the overtime record.`
          : 'The overtime record was updated.',
      };
  }
}

function workOrderData(workOrder, event, actor) {
  const workOrderId = workOrder._id?.toString?.() || String(workOrder.id || '');
  const ctx = workOrderContext(workOrder);
  return {
    type: 'work_order',
    workOrderId,
    entityId: workOrderId,
    event,
    jobNumber: ctx.jobNumber,
    customerName: ctx.customerName,
    locationLabel: ctx.locationLabel,
    actorName: displayName(actor),
  };
}

function overtimeData(overtime, event, actor) {
  const overtimeId = overtime._id?.toString?.() || String(overtime.id || '');
  const techName = displayName(actor);
  return {
    type: 'overtime',
    overtimeId,
    entityId: overtimeId,
    event,
    technicianName: techName,
    siteAddress: overtimeSiteLabel(overtime, event),
    actorName: techName,
  };
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

  const workOrderId = workOrder._id?.toString?.() || String(workOrder.id || '');
  const copy = buildWorkOrderAssignedCopy(workOrder);

  safeNotify(
    notifyUsers({
      io,
      companyId,
      recipientUserIds: recipients,
      type: 'WORK_ORDER_ASSIGNED',
      module: 'work_orders',
      titleAr: copy.titleAr,
      titleEn: copy.titleEn,
      bodyAr: copy.bodyAr,
      bodyEn: copy.bodyEn,
      entityType: 'work_order',
      entityId: workOrderId,
      actorId: actor?._id || null,
      actorName: displayName(actor),
      dedupeKey: `wo:${workOrderId}:${event}:${recipients.sort().join(',')}`,
      data: workOrderData(workOrder, event, actor),
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
  const copy = buildWorkOrderManagerCopy(workOrder, actor, event);

  safeNotify(
    notifyUsers({
      io,
      companyId,
      recipientUserIds: recipients,
      type: `WORK_ORDER_${String(event || 'UPDATED').toUpperCase()}`,
      module: 'work_orders',
      titleAr: titleAr ?? copy.titleAr,
      titleEn: titleEn ?? copy.titleEn,
      bodyAr: bodyAr ?? copy.bodyAr,
      bodyEn: bodyEn ?? copy.bodyEn,
      entityType: 'work_order',
      entityId: workOrderId,
      actorId: actor?._id || null,
      actorName: displayName(actor),
      dedupeKey: `wo:${workOrderId}:${event}:managers`,
      data: workOrderData(workOrder, event, actor),
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
  if (!recipients.length) return;

  const overtimeId = overtime._id?.toString?.() || String(overtime.id || '');
  const copy = buildOvertimeCopy(overtime, actor, event);

  safeNotify(
    notifyUsers({
      io,
      companyId,
      recipientUserIds: recipients,
      type: `OVERTIME_${String(event || 'UPDATE').toUpperCase()}`,
      module: 'overtime',
      titleAr: titleAr ?? copy.titleAr,
      titleEn: titleEn ?? copy.titleEn,
      bodyAr: bodyAr ?? copy.bodyAr,
      bodyEn: bodyEn ?? copy.bodyEn,
      entityType: 'overtime',
      entityId: overtimeId,
      actorId: actor?._id || null,
      actorName: displayName(actor),
      dedupeKey: `ot:${overtimeId}:${event}`,
      data: overtimeData(overtime, event, actor),
    })
  );
}

export default {
  notifyWorkOrderAssigned,
  notifyWorkOrderStatusForManagers,
  notifyOvertimeEvent,
  buildWorkOrderAssignedCopy,
  buildWorkOrderManagerCopy,
  buildOvertimeCopy,
};
