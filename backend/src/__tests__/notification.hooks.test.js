import { describe, it, expect } from '@jest/globals';
import {
  buildWorkOrderAssignedCopy,
  buildWorkOrderManagerCopy,
  buildOvertimeCopy,
} from '../modules/notifications/notification.hooks.js';

describe('notification.hooks copy builders', () => {
  const workOrder = {
    _id: 'wo1',
    jobNumber: 'WO-20260826-0002',
    customerName: 'شركة النور',
    locationLabel: 'القاهرة - مدينة نصر',
  };

  const actor = {
    firstName: 'أحمد',
    lastName: 'محمد',
  };

  const overtime = {
    _id: 'ot1',
    startAddress: 'موقع البداية',
    endAddress: 'موقع النهاية',
    checkpoints: {
      arrivedAtWorkSite: { address: 'موقع العمل' },
      finishedWork: { address: 'موقع العمل' },
      endJourney: { address: 'موقع النهاية' },
    },
  };

  it('builds technician work-order assignment with customer context', () => {
    const copy = buildWorkOrderAssignedCopy(workOrder);
    expect(copy.titleAr).toBe('أمر شغل جديد');
    expect(copy.bodyAr).toContain('WO-20260826-0002');
    expect(copy.bodyAr).toContain('شركة النور');
    expect(copy.bodyAr).not.toContain('(');
  });

  it('builds manager acceptance with technician name', () => {
    const copy = buildWorkOrderManagerCopy(workOrder, actor, 'accepted');
    expect(copy.bodyAr).toContain('أحمد محمد');
    expect(copy.bodyAr).toContain('WO-20260826-0002');
    expect(copy.bodyAr).toContain('شركة النور');
  });

  it('builds manager completion with distinct title', () => {
    const copy = buildWorkOrderManagerCopy(workOrder, actor, 'completed');
    expect(copy.titleAr).toBe('اكتمال أمر الشغل');
    expect(copy.bodyAr).toContain('أنهى أحمد محمد');
  });

  it('distinguishes finished work at site from journey end', () => {
    const finished = buildOvertimeCopy(overtime, actor, 'finished_work');
    const ended = buildOvertimeCopy(overtime, actor, 'ended');

    expect(finished.titleAr).toBe('إنهاء العمل في الموقع');
    expect(ended.titleAr).toBe('إنهاء رحلة العمل الإضافي');
    expect(finished.bodyAr).toContain('أنهى أحمد محمد');
    expect(ended.bodyAr).toContain('رحلة العمل الإضافي');
    expect(finished.titleAr).not.toBe(ended.titleAr);
  });

  it('includes technician name and site on arrival', () => {
    const copy = buildOvertimeCopy(overtime, actor, 'arrived');
    expect(copy.titleAr).toBe('وصول الفني إلى موقع العمل');
    expect(copy.bodyAr).toContain('أحمد محمد');
    expect(copy.bodyAr).toContain('موقع العمل');
  });
});
