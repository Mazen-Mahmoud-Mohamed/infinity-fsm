import { describe, it, expect, beforeEach, jest } from '@jest/globals';

const mockAggregate = jest.fn();

jest.unstable_mockModule(
  '../modules/core/organization/models/user.model.js',
  () => ({
    default: {
      aggregate: (...args) => mockAggregate(...args),
    },
  })
);

jest.unstable_mockModule(
  '../modules/notifications/notifications.service.js',
  () => ({
    notifyUsers: jest.fn(),
  })
);

jest.unstable_mockModule('../modules/core/releases/releases.service.js', () => ({
  default: {
    clearCache: jest.fn(),
    getLatestRelease: jest.fn(),
  },
}));

const {
  listActiveRecipientsByCompany,
  notifyAppUpdateRelease,
} = await import('../modules/core/releases/releases.webhook.js');

describe('listActiveRecipientsByCompany', () => {
  beforeEach(() => {
    mockAggregate.mockReset();
  });

  it('uses lean aggregate with projection, active filter, and company grouping', async () => {
    mockAggregate.mockResolvedValue([
      { _id: 'company-a', userIds: ['u1', 'u2'] },
      { _id: 'company-b', userIds: ['u3'] },
    ]);

    const byCompany = await listActiveRecipientsByCompany();

    expect(mockAggregate).toHaveBeenCalledTimes(1);
    const pipeline = mockAggregate.mock.calls[0][0];
    expect(pipeline).toEqual([
      {
        $match: {
          isActive: true,
          deletedAt: null,
          companyId: { $ne: null },
        },
      },
      { $project: { _id: 1, companyId: 1 } },
      {
        $group: {
          _id: '$companyId',
          userIds: { $addToSet: '$_id' },
        },
      },
    ]);

    expect(byCompany.get('company-a')).toEqual(['u1', 'u2']);
    expect(byCompany.get('company-b')).toEqual(['u3']);
    expect(byCompany.size).toBe(2);
  });

  it('isolates recipients by company and skips empty company keys', async () => {
    mockAggregate.mockResolvedValue([
      { _id: 'c1', userIds: ['a'] },
      { _id: '', userIds: ['ghost'] },
      { _id: null, userIds: ['ghost2'] },
    ]);

    const byCompany = await listActiveRecipientsByCompany();
    expect(byCompany.has('c1')).toBe(true);
    expect(byCompany.has('')).toBe(false);
    expect(byCompany.has('null')).toBe(false);
    expect([...byCompany.keys()]).toEqual(['c1']);
  });

  it('does not silently truncate a large recipient set for a company', async () => {
    const largeIds = Array.from({ length: 500 }, (_, i) => `user-${i}`);
    mockAggregate.mockResolvedValue([{ _id: 'big-co', userIds: largeIds }]);

    const byCompany = await listActiveRecipientsByCompany();
    expect(byCompany.get('big-co')).toHaveLength(500);
    expect(byCompany.get('big-co')).toEqual(largeIds);
  });

  it('stringifies ObjectId-like values without loading full user documents', async () => {
    mockAggregate.mockResolvedValue([
      {
        _id: { toString: () => 'co-1' },
        userIds: [{ toString: () => 'uid-1' }, { toString: () => 'uid-2' }],
      },
    ]);

    const byCompany = await listActiveRecipientsByCompany();
    expect(byCompany.get('co-1')).toEqual(['uid-1', 'uid-2']);
  });

  it('notifyAppUpdateRelease passes full per-company arrays without Set spread copies', async () => {
    const { notifyUsers } = await import(
      '../modules/notifications/notifications.service.js'
    );
    notifyUsers.mockReset();
    notifyUsers.mockResolvedValue({ created: [{}, {}, {}], skipped: false });

    const ids = Array.from({ length: 120 }, (_, i) => `u${i}`);
    mockAggregate.mockResolvedValue([{ _id: 'c1', userIds: ids }]);

    const result = await notifyAppUpdateRelease({
      manifest: {
        version: '1.0.20',
        build: 20,
        channel: 'stable',
        android: { available: true },
        windows: { available: true },
      },
      io: null,
    });

    expect(result.notified).toBe(3);
    expect(notifyUsers).toHaveBeenCalledTimes(1);
    const call = notifyUsers.mock.calls[0][0];
    expect(call.recipientUserIds).toEqual(ids);
    expect(call.recipientUserIds).toHaveLength(120);
    expect(call.data.androidAvailable).toBe(true);
    expect(call.data.windowsAvailable).toBe(true);
  });

  it('filters inactive users only via $match (no post-filter truncation)', async () => {
    mockAggregate.mockResolvedValue([
      { _id: 'c1', userIds: ['active-only'] },
    ]);
    await listActiveRecipientsByCompany();
    const match = mockAggregate.mock.calls[0][0][0].$match;
    expect(match.isActive).toBe(true);
    expect(match.deletedAt).toBeNull();
  });
});
