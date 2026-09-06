import { describe, it, expect, beforeEach, jest } from '@jest/globals';

const mockFindExisting = jest.fn();
const mockInsertMany = jest.fn();
const mockSend = jest.fn();
const mockListTokens = jest.fn();
const mockUserFind = jest.fn();

jest.unstable_mockModule(
  '../modules/notifications/models/appNotification.model.js',
  () => ({
    default: {
      find: () => ({
        select: () => ({
          lean: () => mockFindExisting(),
        }),
      }),
      insertMany: mockInsertMany,
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
  default: {
    find: (...args) => {
      mockUserFind(...args);
      return {
        select: () => ({
          lean: async () => mockUserFind.mock.results.at(-1)?.value ?? [],
        }),
      };
    },
  },
}));

const {
  notifyUsers,
  findManagementRecipientIds,
} = await import('../modules/notifications/notifications.service.js');
const { mapWithConcurrency } = await import(
  '../shared/utils/concurrency.util.js'
);

function makeCreatedDoc(overrides = {}) {
  const doc = {
    _id: { toString: () => overrides.id || 'n1' },
    recipientUserId: {
      toString: () => overrides.recipientUserId || 'u1',
    },
    titleAr: overrides.titleAr || 'أمر شغل جديد',
    titleEn: overrides.titleEn || 'New Work Order',
    bodyAr: overrides.bodyAr || 'body-ar',
    bodyEn: overrides.bodyEn || 'body-en',
    entityType: overrides.entityType || 'work_order',
    entityId: overrides.entityId || 'wo1',
    type: overrides.type || 'WORK_ORDER_ASSIGNED',
    module: overrides.module || 'work_orders',
    data: overrides.data || { type: 'work_order', workOrderId: 'wo1' },
    dedupeKey: overrides.dedupeKey || 'wo:wo1:created:u1',
    ...overrides,
  };
  return {
    ...doc,
    toObject() {
      return doc;
    },
  };
}

describe('notifications push delivery', () => {
  beforeEach(() => {
    mockFindExisting.mockReset();
    mockInsertMany.mockReset();
    mockSend.mockReset();
    mockListTokens.mockReset();
    mockUserFind.mockReset();
    mockFindExisting.mockResolvedValue([]);
    mockListTokens.mockResolvedValue([
      { token: 'token-android-1', platform: 'android', locale: 'ar', userId: 'u1' },
      { token: 'token-android-2', platform: 'android', locale: 'ar', userId: 'u1' },
    ]);
    mockSend.mockResolvedValue({ sent: 1, failed: 0, skipped: false });
  });

  it('returns skipped for zero recipients', async () => {
    const result = await notifyUsers({
      companyId: 'c1',
      recipientUserIds: [],
      type: 'WORK_ORDER_ASSIGNED',
      module: 'work_orders',
      titleAr: 't',
      titleEn: 't',
      bodyAr: 'b',
      bodyEn: 'b',
      dedupeKey: 'wo:empty',
    });

    expect(result).toEqual({ created: [], skipped: true });
    expect(mockInsertMany).not.toHaveBeenCalled();
    expect(mockSend).not.toHaveBeenCalled();
  });

  it('targets one recipient and sends FCM to multiple tokens', async () => {
    mockInsertMany.mockResolvedValue([makeCreatedDoc()]);

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
    expect(mockInsertMany).toHaveBeenCalledTimes(1);
    expect(mockInsertMany.mock.calls[0][0]).toHaveLength(1);
    expect(mockInsertMany.mock.calls[0][1]).toEqual({ ordered: false });

    await new Promise((r) => setTimeout(r, 40));
    expect(mockListTokens).toHaveBeenCalledWith(['u1']);
    expect(mockSend).toHaveBeenCalled();
    const args = mockSend.mock.calls[0][0];
    expect(args.tokens).toHaveLength(2);
    expect(args.title).toBe('أمر شغل جديد');
    expect(args.data.recipientUserId).toBe('u1');
    expect(args.data.notificationId).toBe('n1');
  });

  it('creates bulk notifications for multiple recipients once', async () => {
    mockInsertMany.mockResolvedValue([
      makeCreatedDoc({ id: 'n1', recipientUserId: 'u1', dedupeKey: 'evt:u1' }),
      makeCreatedDoc({ id: 'n2', recipientUserId: 'u2', dedupeKey: 'evt:u2' }),
    ]);
    mockListTokens.mockResolvedValue([
      { token: 't1', platform: 'android', locale: 'ar', userId: 'u1' },
      { token: 't2', platform: 'android', locale: 'en', userId: 'u2' },
    ]);

    const result = await notifyUsers({
      companyId: 'c1',
      recipientUserIds: ['u1', 'u2', 'u1'],
      type: 'WORK_ORDER_ASSIGNED',
      module: 'work_orders',
      titleAr: 't',
      titleEn: 't',
      bodyAr: 'b',
      bodyEn: 'b',
      dedupeKey: 'evt',
    });

    expect(result.created).toHaveLength(2);
    expect(mockInsertMany.mock.calls[0][0]).toHaveLength(2);
    await new Promise((r) => setTimeout(r, 40));
    expect(mockListTokens).toHaveBeenCalledWith(['u1', 'u2']);
    expect(mockSend.mock.calls.length).toBeGreaterThanOrEqual(2);
  });

  it('dedupes duplicate recipient ids before insert', async () => {
    mockInsertMany.mockResolvedValue([makeCreatedDoc()]);

    await notifyUsers({
      companyId: 'c1',
      recipientUserIds: ['u1', 'u1', 'u1'],
      type: 'WORK_ORDER_ASSIGNED',
      module: 'work_orders',
      titleAr: 't',
      titleEn: 't',
      bodyAr: 'b',
      bodyEn: 'b',
      dedupeKey: 'wo:dup',
    });

    expect(mockInsertMany.mock.calls[0][0]).toHaveLength(1);
  });

  it('does not create duplicate notification or push for same dedupeKey', async () => {
    mockFindExisting.mockResolvedValue([
      { dedupeKey: 'wo:wo1:created:u1' },
    ]);

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
    expect(mockInsertMany).not.toHaveBeenCalled();
    await new Promise((r) => setTimeout(r, 20));
    expect(mockSend).not.toHaveBeenCalled();
  });

  it('treats concurrent duplicate insert (11000) as skip', async () => {
    const err = new Error('E11000 duplicate');
    err.code = 11000;
    err.writeErrors = [{ code: 11000 }];
    err.insertedDocs = [];
    mockInsertMany.mockRejectedValue(err);

    const result = await notifyUsers({
      companyId: 'c1',
      recipientUserIds: ['u1'],
      type: 'WORK_ORDER_ASSIGNED',
      module: 'work_orders',
      titleAr: 't',
      titleEn: 't',
      bodyAr: 'b',
      bodyEn: 'b',
      dedupeKey: 'wo:race',
    });

    expect(result.created).toHaveLength(0);
    await new Promise((r) => setTimeout(r, 20));
    expect(mockSend).not.toHaveBeenCalled();
  });

  it('keeps partial inserts when some duplicate writeErrors occur', async () => {
    const err = new Error('bulk');
    err.writeErrors = [{ code: 11000 }];
    err.insertedDocs = [
      makeCreatedDoc({ id: 'n-ok', recipientUserId: 'u2', dedupeKey: 'evt:u2' }),
    ];
    mockInsertMany.mockRejectedValue(err);
    mockListTokens.mockResolvedValue([
      { token: 't2', platform: 'android', locale: 'ar', userId: 'u2' },
    ]);

    const result = await notifyUsers({
      companyId: 'c1',
      recipientUserIds: ['u1', 'u2'],
      type: 'WORK_ORDER_ASSIGNED',
      module: 'work_orders',
      titleAr: 't',
      titleEn: 't',
      bodyAr: 'b',
      bodyEn: 'b',
      dedupeKey: 'evt',
    });

    expect(result.created).toHaveLength(1);
    await new Promise((r) => setTimeout(r, 40));
    expect(mockSend).toHaveBeenCalled();
  });

  it('push failure does not reject notifyUsers', async () => {
    mockInsertMany.mockResolvedValue([makeCreatedDoc({ id: 'n2' })]);
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

  it('database insert failure without duplicates does not throw to caller', async () => {
    mockInsertMany.mockRejectedValue(new Error('mongo down'));

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
        dedupeKey: 'wo:fail',
      })
    ).resolves.toMatchObject({ created: [], skipped: false });
  });

  it('emits Socket.IO to user rooms only (no company broadcast)', async () => {
    mockInsertMany.mockResolvedValue([
      makeCreatedDoc({ id: 'n1', recipientUserId: 'u1' }),
      makeCreatedDoc({ id: 'n2', recipientUserId: 'u2' }),
    ]);
    const roomEmit = jest.fn();
    const io = {
      to: jest.fn((room) => {
        expect(room.startsWith('user:')).toBe(true);
        return { emit: roomEmit };
      }),
    };

    await notifyUsers({
      companyId: 'c1',
      recipientUserIds: ['u1', 'u2'],
      type: 'WORK_ORDER_ASSIGNED',
      module: 'work_orders',
      titleAr: 't',
      titleEn: 't',
      bodyAr: 'b',
      bodyEn: 'b',
      dedupeKey: 'wo:socket',
      io,
    });

    await new Promise((r) => setTimeout(r, 40));
    expect(io.to).toHaveBeenCalledWith('user:u1');
    expect(io.to).toHaveBeenCalledWith('user:u2');
    expect(io.to).not.toHaveBeenCalledWith(expect.stringMatching(/^company:/));
    expect(roomEmit).toHaveBeenCalledWith(
      'notification:new',
      expect.objectContaining({
        titleAr: 'أمر شغل جديد',
        titleEn: 'New Work Order',
      })
    );
  });

  it('findManagementRecipientIds scopes by company and roles', async () => {
    mockUserFind.mockResolvedValue([
      { _id: { toString: () => 'a1' } },
      { _id: { toString: () => 's1' } },
    ]);

    const ids = await findManagementRecipientIds('c1', { excludeUserId: 'a1' });
    expect(mockUserFind).toHaveBeenCalledWith(
      expect.objectContaining({
        companyId: 'c1',
        roles: { $in: ['ADMIN', 'SUPERVISOR'] },
      })
    );
    expect(ids).toEqual(['s1']);
  });

  it('mapWithConcurrency respects the concurrency ceiling', async () => {
    let inflight = 0;
    let maxInflight = 0;
    const items = [1, 2, 3, 4, 5, 6];

    await mapWithConcurrency(items, 2, async () => {
      inflight += 1;
      maxInflight = Math.max(maxInflight, inflight);
      await new Promise((r) => setTimeout(r, 15));
      inflight -= 1;
    });

    expect(maxInflight).toBeLessThanOrEqual(2);
  });
});
