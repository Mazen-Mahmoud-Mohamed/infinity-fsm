import { describe, it, expect, beforeEach, jest } from '@jest/globals';

const mockFind = jest.fn();

jest.unstable_mockModule(
  '../modules/notifications/models/devicePushToken.model.js',
  () => ({
    default: {
      find: (...args) => mockFind(...args),
    },
  })
);

const { listActiveTokensForUsers } = await import(
  '../modules/notifications/deviceToken.service.js'
);

describe('listActiveTokensForUsers', () => {
  beforeEach(() => {
    mockFind.mockReset();
    mockFind.mockReturnValue({
      select: () => ({
        lean: async () => [{ token: 't1', userId: 'u1', active: true }],
      }),
    });
  });

  it('requires active tokens and scopes by company when provided', async () => {
    await listActiveTokensForUsers(['u1', 'u2'], { companyId: 'c1' });
    expect(mockFind).toHaveBeenCalledWith({
      userId: { $in: ['u1', 'u2'] },
      active: true,
      companyId: 'c1',
    });
  });

  it('does not select tokens from another company', async () => {
    await listActiveTokensForUsers(['u1'], { companyId: 'c1' });
    const query = mockFind.mock.calls[0][0];
    expect(query.companyId).toBe('c1');
    expect(query.companyId).not.toBe('c2');
    expect(query.active).toBe(true);
  });

  it('keeps inactive tokens excluded when company context is absent', async () => {
    await listActiveTokensForUsers(['u1']);
    expect(mockFind).toHaveBeenCalledWith({
      userId: { $in: ['u1'] },
      active: true,
    });
    expect(mockFind.mock.calls[0][0].active).toBe(true);
  });
});
