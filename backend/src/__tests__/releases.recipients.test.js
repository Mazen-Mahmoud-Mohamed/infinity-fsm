import { describe, it, expect, beforeEach, jest } from '@jest/globals';

const mockDistinct = jest.fn();
const mockFind = jest.fn();

function usersForFilter(filter, usersByCompany) {
  const companyId = filter.companyId?.toString?.() ?? String(filter.companyId || '');
  let ids = [...(usersByCompany.get(companyId) || [])];
  const after = filter._id?.$gt;
  if (after != null) {
    const afterStr = after.toString();
    const idx = ids.findIndex((id) => String(id) === afterStr);
    ids = idx >= 0 ? ids.slice(idx + 1) : [];
  }
  return ids;
}

function mockUserModel(usersByCompany) {
  mockDistinct.mockImplementation(async () => [...usersByCompany.keys()]);
  mockFind.mockImplementation((filter = {}) => {
    const ids = usersForFilter(filter, usersByCompany);
    const chain = {
      _limit: ids.length,
      select: () => chain,
      sort: () => chain,
      limit: (n) => {
        chain._limit = n;
        return chain;
      },
      lean: async () =>
        ids.slice(0, chain._limit).map((id) => ({ _id: id })),
    };
    return chain;
  });
  return {
    distinct: (...args) => mockDistinct(...args),
    find: (...args) => mockFind(...args),
  };
}

jest.unstable_mockModule(
  '../modules/core/organization/models/user.model.js',
  () => ({
    default: {
      distinct: (...args) => mockDistinct(...args),
      find: (...args) => mockFind(...args),
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
  listActiveCompanyIds,
  fetchActiveRecipientPage,
  notifyAppUpdateRelease,
  RELEASE_RECIPIENT_CHUNK_SIZE,
  RELEASE_COMPANY_FANOUT_CONCURRENCY,
} = await import('../modules/core/releases/releases.webhook.js');

describe('release recipient fanout', () => {
  beforeEach(() => {
    mockDistinct.mockReset();
    mockFind.mockReset();
  });

  it('lists company ids via distinct without loading every user id', async () => {
    mockDistinct.mockResolvedValue(['company-a', 'company-b', '', null]);
    const ids = await listActiveCompanyIds();
    expect(mockDistinct).toHaveBeenCalledWith('companyId', {
      isActive: true,
      deletedAt: null,
      companyId: { $ne: null },
    });
    expect(ids).toEqual(['company-a', 'company-b']);
  });

  it('pages active recipients with _id cursor and active filter', async () => {
    const byCompany = new Map([['c1', ['u1', 'u2', 'u3']]]);
    mockUserModel(byCompany);

    const first = await fetchActiveRecipientPage({
      companyId: 'c1',
      limit: 2,
    });
    expect(first.map(String)).toEqual(['u1', 'u2']);
    expect(mockFind).toHaveBeenCalledWith(
      expect.objectContaining({
        companyId: 'c1',
        isActive: true,
        deletedAt: null,
      })
    );

    const second = await fetchActiveRecipientPage({
      companyId: 'c1',
      afterId: 'u2',
      limit: 2,
    });
    expect(second.map(String)).toEqual(['u3']);
  });

  it('small company is processed in a single notifyUsers chunk', async () => {
    const { notifyUsers } = await import(
      '../modules/notifications/notifications.service.js'
    );
    notifyUsers.mockReset();
    notifyUsers.mockResolvedValue({ created: [{}, {}], skipped: false });
    mockUserModel(new Map([['c1', ['a', 'b']]]));

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

    expect(result.notified).toBe(2);
    expect(notifyUsers).toHaveBeenCalledTimes(1);
    expect(notifyUsers.mock.calls[0][0].recipientUserIds).toEqual(['a', 'b']);
    expect(notifyUsers.mock.calls[0][0].dedupeKey).toBe('app-update:v1.0.20:20');
  });

  it('large recipient set is chunked without duplicate ids', async () => {
    const { notifyUsers } = await import(
      '../modules/notifications/notifications.service.js'
    );
    notifyUsers.mockReset();
    notifyUsers.mockResolvedValue({ created: [{}], skipped: false });

    const ids = Array.from({ length: RELEASE_RECIPIENT_CHUNK_SIZE + 50 }, (_, i) => `u${i}`);
    mockUserModel(new Map([['big-co', ids]]));

    await notifyAppUpdateRelease({
      manifest: { version: '1.0.20', build: 21, channel: 'stable' },
      io: null,
    });

    expect(notifyUsers.mock.calls.length).toBeGreaterThan(1);
    const all = notifyUsers.mock.calls.flatMap((call) => call[0].recipientUserIds);
    expect(all).toHaveLength(ids.length);
    expect(new Set(all).size).toBe(ids.length);
    expect(all).toEqual(ids);
    expect(
      notifyUsers.mock.calls.every(
        (call) => call[0].dedupeKey === 'app-update:v1.0.20:21'
      )
    ).toBe(true);
    expect(
      notifyUsers.mock.calls.every(
        (call) => call[0].recipientUserIds.length <= RELEASE_RECIPIENT_CHUNK_SIZE
      )
    ).toBe(true);
  });

  it('continues later chunks when one notifyUsers call fails', async () => {
    const { notifyUsers } = await import(
      '../modules/notifications/notifications.service.js'
    );
    notifyUsers.mockReset();
    notifyUsers
      .mockRejectedValueOnce(new Error('chunk 1 down'))
      .mockResolvedValue({ created: [{}, {}], skipped: false });

    const ids = Array.from({ length: RELEASE_RECIPIENT_CHUNK_SIZE + 10 }, (_, i) => `u${i}`);
    mockUserModel(new Map([['c1', ids]]));

    const result = await notifyAppUpdateRelease({
      manifest: { version: '1.0.20', build: 22, channel: 'stable' },
      io: null,
    });

    expect(notifyUsers.mock.calls.length).toBeGreaterThanOrEqual(2);
    expect(result.notified).toBe(2);
  });

  it('keeps existing company fanout and recipient chunk ceilings', () => {
    expect(RELEASE_COMPANY_FANOUT_CONCURRENCY).toBe(3);
    expect(RELEASE_RECIPIENT_CHUNK_SIZE).toBe(200);
  });
});
