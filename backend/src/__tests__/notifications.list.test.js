import { describe, it, expect, beforeEach, jest } from '@jest/globals';

const mockFind = jest.fn();
const mockCountDocuments = jest.fn();
const mockSort = jest.fn();
const mockSkip = jest.fn();
const mockLimit = jest.fn();
const mockLean = jest.fn();
const mockSelect = jest.fn();

function notificationQuery() {
  const query = {
    select: (...args) => {
      mockSelect(...args);
      return query;
    },
    sort: (...args) => {
      mockSort(...args);
      return query;
    },
    skip: (...args) => {
      mockSkip(...args);
      return query;
    },
    limit: (...args) => {
      mockLimit(...args);
      return query;
    },
    lean: () => mockLean(),
  };
  return query;
}

jest.unstable_mockModule(
  '../modules/notifications/models/appNotification.model.js',
  () => ({
    default: {
      find: (...args) => {
        mockFind(...args);
        return notificationQuery();
      },
      countDocuments: (...args) => mockCountDocuments(...args),
    },
  })
);

jest.unstable_mockModule(
  '../modules/notifications/deviceToken.service.js',
  () => ({
    listActiveTokensForUsers: jest.fn(),
  })
);

jest.unstable_mockModule('../modules/notifications/fcm.service.js', () => ({
  sendFcmToTokens: jest.fn(),
}));

jest.unstable_mockModule(
  '../modules/core/organization/models/user.model.js',
  () => ({
    default: {
      find: jest.fn(),
    },
  })
);

const dashboardSummarySpy = jest.fn();
jest.unstable_mockModule(
  '../modules/core/dashboard/dashboard.service.js',
  () => ({
    default: {
      getDashboardSummary: dashboardSummarySpy,
    },
    getDashboardSummary: dashboardSummarySpy,
  })
);

const { listNotifications, getUnreadCount, mapNotification } = await import(
  '../modules/notifications/notifications.service.js'
);

function makeDoc(overrides = {}) {
  return {
    _id: { toString: () => overrides.id || 'n1' },
    type: overrides.type || 'WORK_ORDER_ASSIGNED',
    module: overrides.module || 'work_orders',
    titleAr: overrides.titleAr || 'عنوان',
    titleEn: overrides.titleEn || 'Title',
    bodyAr: overrides.bodyAr || 'نص',
    bodyEn: overrides.bodyEn || 'Body',
    entityType: overrides.entityType || 'work_order',
    entityId: overrides.entityId || 'wo1',
    data: overrides.data || { route: '/work-orders/wo1' },
    actorName: overrides.actorName || 'Admin',
    isRead: overrides.isRead ?? false,
    createdAt: overrides.createdAt || new Date('2026-09-01T10:00:00.000Z'),
  };
}

describe('notifications list API', () => {
  const user = { _id: 'user-1' };
  const auth = { companyId: 'company-1' };

  beforeEach(() => {
    mockFind.mockReset();
    mockCountDocuments.mockReset();
    mockSort.mockReset();
    mockSkip.mockReset();
    mockLimit.mockReset();
    mockLean.mockReset();
    mockSelect.mockReset();
    dashboardSummarySpy.mockReset();
  });

  it('lists AppNotification docs only — never calls dashboard summary', async () => {
    const docs = [
      makeDoc({ id: 'n2', createdAt: new Date('2026-09-02T00:00:00.000Z') }),
      makeDoc({ id: 'n1', isRead: true }),
    ];
    mockLean.mockResolvedValue(docs);
    mockCountDocuments
      .mockResolvedValueOnce(2)
      .mockResolvedValueOnce(1);

    const result = await listNotifications(user, auth, { page: 1, limit: 50 });

    expect(dashboardSummarySpy).not.toHaveBeenCalled();
    expect(mockFind).toHaveBeenCalledWith({
      companyId: 'company-1',
      recipientUserId: 'user-1',
    });
    expect(mockSelect).toHaveBeenCalled();
    expect(mockSort).toHaveBeenCalledWith({ createdAt: -1 });
    expect(mockSkip).toHaveBeenCalledWith(0);
    expect(mockLimit).toHaveBeenCalledWith(50);

    expect(result.unreadCount).toBe(1);
    expect(result.pagination).toEqual({
      page: 1,
      limit: 50,
      total: 2,
      totalPages: 1,
    });
    expect(result.items).toHaveLength(2);
    expect(result.items[0]).toMatchObject({
      id: 'n2',
      type: 'WORK_ORDER_ASSIGNED',
      module: 'work_orders',
      titleAr: 'عنوان',
      titleEn: 'Title',
      bodyAr: 'نص',
      bodyEn: 'Body',
      entityType: 'work_order',
      entityId: 'wo1',
      isRead: false,
    });
    expect(result.items[0]).toHaveProperty('title');
    expect(result.items[0]).toHaveProperty('body');
    expect(result.items[0]).toHaveProperty('data');
    expect(result.items[0]).toHaveProperty('createdAt');
  });

  it('paginates with skip/limit and clamps page/limit bounds', async () => {
    mockLean.mockResolvedValue([makeDoc({ id: 'n10' })]);
    mockCountDocuments.mockResolvedValueOnce(120).mockResolvedValueOnce(5);

    const result = await listNotifications(user, auth, { page: 3, limit: 20 });

    expect(mockSkip).toHaveBeenCalledWith(40);
    expect(mockLimit).toHaveBeenCalledWith(20);
    expect(result.pagination).toEqual({
      page: 3,
      limit: 20,
      total: 120,
      totalPages: 6,
    });
    expect(result.unreadCount).toBe(5);

    mockLean.mockResolvedValue([]);
    mockCountDocuments.mockResolvedValueOnce(0).mockResolvedValueOnce(0);
    const clamped = await listNotifications(user, auth, {
      page: 0,
      limit: 999,
    });
    expect(mockSkip).toHaveBeenLastCalledWith(0);
    expect(mockLimit).toHaveBeenLastCalledWith(100);
    expect(clamped.pagination.page).toBe(1);
    expect(clamped.pagination.limit).toBe(100);
  });

  it('scopes unread count to company + recipient and unread only', async () => {
    mockCountDocuments.mockResolvedValue(7);
    const result = await getUnreadCount(user, auth);
    expect(mockCountDocuments).toHaveBeenCalledWith({
      companyId: 'company-1',
      recipientUserId: 'user-1',
      isRead: false,
    });
    expect(result).toEqual({ count: 7 });
  });

  it('preserves mapNotification response shape for list items', () => {
    const mapped = mapNotification(
      makeDoc({
        id: 'shape-1',
        data: { route: '/x' },
        isRead: true,
      })
    );
    expect(Object.keys(mapped).sort()).toEqual(
      [
        'actorName',
        'body',
        'bodyAr',
        'bodyEn',
        'createdAt',
        'data',
        'entityId',
        'entityType',
        'id',
        'isRead',
        'module',
        'title',
        'titleAr',
        'titleEn',
        'type',
      ].sort()
    );
    expect(mapped.isRead).toBe(true);
    expect(mapped.id).toBe('shape-1');
  });

  it('documents that dashboard-summary fallback is not a backend list path', async () => {
    mockLean.mockResolvedValue([]);
    mockCountDocuments.mockResolvedValue(0);
    await listNotifications(user, auth);
    expect(dashboardSummarySpy).not.toHaveBeenCalled();
    // Flutter client may still fall back to dashboard activity when the API
    // fails; that path is outside this backend service.
  });
});
