import { describe, it, expect, beforeEach, jest } from '@jest/globals';

const mockCreate = jest.fn();
const mockFindOne = jest.fn();
const mockSend = jest.fn();
const mockListTokens = jest.fn();

jest.unstable_mockModule(
  '../modules/notifications/models/appNotification.model.js',
  () => ({
    default: {
      findOne: (...args) => {
        const result = mockFindOne(...args);
        return {
          lean: async () => result,
        };
      },
      create: mockCreate,
    },
  })
);

jest.unstable_mockModule(
  '../modules/notifications/deviceToken.service.js',
  () => ({
    listActiveTokensForUsers: mockListTokens,
  })
);

jest.unstable_mockModule('../modules/notifications/fcm.service.js', () => ({
  sendFcmToTokens: mockSend,
}));

jest.unstable_mockModule('../modules/core/organization/models/user.model.js', () => ({
  default: { find: jest.fn() },
}));

const { notifyUsers } = await import(
  '../modules/notifications/notifications.service.js'
);

describe('notifications push delivery', () => {
  beforeEach(() => {
    mockCreate.mockReset();
    mockFindOne.mockReset();
    mockSend.mockReset();
    mockListTokens.mockReset();
    mockListTokens.mockResolvedValue([
      { token: 'token-android-1', platform: 'android', locale: 'ar', userId: 'u1' },
      { token: 'token-android-2', platform: 'android', locale: 'ar', userId: 'u1' },
    ]);
    mockSend.mockResolvedValue({ sent: 1, failed: 0, skipped: false });
  });

  it('targets recipient and sends FCM to multiple tokens', async () => {
    mockFindOne.mockResolvedValue(null);
    mockCreate.mockResolvedValue({
      toObject() {
        return {
          _id: { toString: () => 'n1' },
          recipientUserId: { toString: () => 'u1' },
          titleAr: 'أمر شغل جديد',
          titleEn: 'New Work Order',
          bodyAr: 'تم تعيين أمر الشغل WO-1 لك.',
          bodyEn: 'Work order WO-1 was assigned to you.',
          entityType: 'work_order',
          entityId: 'wo1',
          type: 'WORK_ORDER_ASSIGNED',
          module: 'work_orders',
          data: { type: 'work_order', workOrderId: 'wo1' },
        };
      },
    });

    const result = await notifyUsers({
      companyId: 'c1',
      recipientUserIds: ['u1'],
      type: 'WORK_ORDER_ASSIGNED',
      module: 'work_orders',
      titleAr: 'أمر شغل جديد',
      titleEn: 'New Work Order',
      bodyAr: 'تم تعيين أمر الشغل WO-1 لك.',
      bodyEn: 'Work order WO-1 was assigned to you.',
      entityType: 'work_order',
      entityId: 'wo1',
      dedupeKey: 'wo:wo1:created',
      data: { type: 'work_order', workOrderId: 'wo1' },
    });

    expect(result.created).toHaveLength(1);
    await new Promise((r) => setTimeout(r, 40));
    expect(mockSend).toHaveBeenCalled();
    const args = mockSend.mock.calls[0][0];
    expect(args.tokens).toHaveLength(2);
    expect(args.title).toBe('أمر شغل جديد');
  });

  it('does not create duplicate notification or push for same dedupeKey', async () => {
    mockFindOne.mockResolvedValue({
      _id: 'existing',
      dedupeKey: 'wo:wo1:created:u1',
    });

    const result = await notifyUsers({
      companyId: 'c1',
      recipientUserIds: ['u1'],
      type: 'WORK_ORDER_ASSIGNED',
      module: 'work_orders',
      titleAr: 'أمر شغل جديد',
      titleEn: 'New Work Order',
      bodyAr: 'body',
      bodyEn: 'body',
      dedupeKey: 'wo:wo1:created',
    });

    expect(result.created).toHaveLength(0);
    expect(mockCreate).not.toHaveBeenCalled();
    await new Promise((r) => setTimeout(r, 20));
    expect(mockSend).not.toHaveBeenCalled();
  });

  it('push failure does not reject notifyUsers', async () => {
    mockFindOne.mockResolvedValue(null);
    mockCreate.mockResolvedValue({
      toObject() {
        return {
          _id: { toString: () => 'n2' },
          recipientUserId: { toString: () => 'u1' },
          titleAr: 't',
          titleEn: 't',
          bodyAr: 'b',
          bodyEn: 'b',
          entityType: 'work_order',
          entityId: 'wo2',
          type: 'WORK_ORDER_ASSIGNED',
          module: 'work_orders',
          data: {},
        };
      },
    });
    mockSend.mockImplementation(async () => {
      throw new Error('FCM down');
    });

    await expect(
      notifyUsers({
        companyId: 'c1',
        recipientUserIds: ['u1'],
        type: 'WORK_ORDER_ASSIGNED',
        module: 'work_orders',
        titleAr: 't',
        titleEn: 't',
        bodyAr: 'b',
        bodyEn: 'b',
        dedupeKey: 'wo:wo2:created',
      })
    ).resolves.toMatchObject({ skipped: false });
  });
});
