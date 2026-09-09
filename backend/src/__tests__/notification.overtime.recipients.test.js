import { describe, it, expect, beforeEach, jest } from '@jest/globals';

const mockNotifyUsers = jest.fn();
const mockFindManagement = jest.fn();

jest.unstable_mockModule(
  '../modules/notifications/notifications.service.js',
  () => ({
    notifyUsers: (...args) => mockNotifyUsers(...args),
    findManagementRecipientIds: (...args) => mockFindManagement(...args),
  })
);

const { notifyOvertimeEvent } = await import(
  '../modules/notifications/notification.hooks.js'
);

describe('notifyOvertimeEvent actor exclusion', () => {
  beforeEach(() => {
    mockNotifyUsers.mockReset();
    mockFindManagement.mockReset();
    mockNotifyUsers.mockResolvedValue({ created: [] });
  });

  it('excludes the acting manager and still notifies other managers', async () => {
    mockFindManagement.mockImplementation(async (_companyId, opts = {}) => {
      const all = ['actor1', 'admin1', 'sv1'];
      return all.filter(
        (id) => !opts.excludeUserId || id !== String(opts.excludeUserId)
      );
    });

    await notifyOvertimeEvent({
      companyId: 'c1',
      overtime: { _id: 'ot1', startAddress: 'Site' },
      actor: { _id: 'actor1', firstName: 'Mazen' },
      event: 'started',
    });

    await new Promise((r) => setTimeout(r, 20));

    expect(mockFindManagement).toHaveBeenCalledWith('c1', {
      excludeUserId: 'actor1',
    });
    expect(mockNotifyUsers).toHaveBeenCalledTimes(1);
    expect(mockNotifyUsers.mock.calls[0][0].recipientUserIds).toEqual([
      'admin1',
      'sv1',
    ]);
    expect(mockNotifyUsers.mock.calls[0][0].recipientUserIds).not.toContain(
      'actor1'
    );
    expect(mockNotifyUsers.mock.calls[0][0].dedupeKey).toBe('ot:ot1:started');
  });

  it('keeps the overtime dedupe key when the actor is not a manager', async () => {
    mockFindManagement.mockImplementation(async (_companyId, opts = {}) => {
      expect(opts.excludeUserId).toBe('tech1');
      return ['admin1', 'sv1'];
    });

    await notifyOvertimeEvent({
      companyId: 'c1',
      overtime: { _id: 'ot9' },
      actor: { _id: 'tech1', firstName: 'Field' },
      event: 'arrived',
    });

    await new Promise((r) => setTimeout(r, 20));

    expect(mockNotifyUsers).toHaveBeenCalledWith(
      expect.objectContaining({
        recipientUserIds: ['admin1', 'sv1'],
        dedupeKey: 'ot:ot9:arrived',
        entityType: 'overtime',
      })
    );
  });

  it('does not notify when the actor is the only management recipient', async () => {
    mockFindManagement.mockResolvedValue([]);

    await notifyOvertimeEvent({
      companyId: 'c1',
      overtime: { _id: 'ot2' },
      actor: { _id: 'solo-admin' },
      event: 'ended',
    });

    await new Promise((r) => setTimeout(r, 20));
    expect(mockNotifyUsers).not.toHaveBeenCalled();
  });

  it('uses OVERTIME_CANCELLED type and overtime dedupe key for cancelled events', async () => {
    mockFindManagement.mockResolvedValue(['admin1']);

    await notifyOvertimeEvent({
      companyId: 'c1',
      overtime: { _id: 'ot-cancel' },
      actor: { _id: 'tech1', firstName: 'Field' },
      event: 'cancelled',
    });

    await new Promise((r) => setTimeout(r, 20));

    expect(mockNotifyUsers).toHaveBeenCalledWith(
      expect.objectContaining({
        type: 'OVERTIME_CANCELLED',
        module: 'overtime',
        entityType: 'overtime',
        entityId: 'ot-cancel',
        dedupeKey: 'ot:ot-cancel:cancelled',
        titleAr: 'إلغاء العمل',
        bodyAr: expect.stringContaining('ألغى'),
        recipientUserIds: ['admin1'],
      })
    );
  });
});
