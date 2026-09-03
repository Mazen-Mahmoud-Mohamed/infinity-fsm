import { describe, it, expect, beforeEach, jest } from '@jest/globals';

const mockUpdateMany = jest.fn();
const mockLogAuthEvent = jest.fn(async () => undefined);
const mockDeactivateAllDeviceTokens = jest.fn(async () => ({
  deactivated: 2,
}));

jest.unstable_mockModule(
  '../modules/core/auth/models/refreshToken.model.js',
  () => ({
    default: {
      updateMany: (...args) => mockUpdateMany(...args),
    },
  })
);

jest.unstable_mockModule('../modules/core/audit/audit.service.js', () => ({
  default: {
    logAuthEvent: (...args) => mockLogAuthEvent(...args),
  },
}));

jest.unstable_mockModule(
  '../modules/notifications/deviceToken.service.js',
  () => ({
    deactivateAllDeviceTokens: (...args) =>
      mockDeactivateAllDeviceTokens(...args),
  })
);

jest.unstable_mockModule('../config/index.js', () => ({
  default: {
    jwt: {
      accessSecret: 'test-secret-min-32-chars-xxxxxxxxxx',
      accessExpiry: '15m',
      refreshExpiry: '7d',
    },
  },
}));

jest.unstable_mockModule('../modules/core/organization/models/user.model.js', () => ({
  default: {},
}));

jest.unstable_mockModule('../modules/core/rbac/rbac.service.js', () => ({
  default: {},
}));

const { default: authService } = await import(
  '../modules/core/auth/auth.service.js'
);

describe('auth.service logoutAllDevices', () => {
  const user = {
    _id: 'user-1',
    companyId: 'company-1',
    roles: ['ADMIN'],
  };
  const req = { ip: '127.0.0.1' };

  beforeEach(() => {
    mockUpdateMany.mockReset();
    mockLogAuthEvent.mockClear();
    mockDeactivateAllDeviceTokens.mockClear();
    mockUpdateMany.mockResolvedValue({ modifiedCount: 3 });
  });

  it('revokes refresh sessions and deactivates push tokens', async () => {
    const result = await authService.logoutAllDevices(req, user);

    expect(mockUpdateMany).toHaveBeenCalledWith(
      { userId: user._id, revokedAt: null },
      expect.objectContaining({ revokedAt: expect.any(Date) })
    );
    expect(mockDeactivateAllDeviceTokens).toHaveBeenCalledWith(user, {
      companyId: user.companyId,
    });
    expect(mockLogAuthEvent).toHaveBeenCalledWith(
      req,
      expect.objectContaining({
        action: 'auth.logout_all_devices',
        metadata: {
          revokedSessions: 3,
          deactivatedPushTokens: 2,
        },
      })
    );
    expect(result).toEqual({
      revokedSessions: 3,
      deactivatedPushTokens: 2,
    });
  });

  it('still succeeds when push cleanup fails', async () => {
    mockDeactivateAllDeviceTokens.mockRejectedValueOnce(new Error('push down'));

    const result = await authService.logoutAllDevices(req, user);

    expect(result).toEqual({
      revokedSessions: 3,
      deactivatedPushTokens: 0,
    });
    expect(mockLogAuthEvent).toHaveBeenCalled();
  });
});
