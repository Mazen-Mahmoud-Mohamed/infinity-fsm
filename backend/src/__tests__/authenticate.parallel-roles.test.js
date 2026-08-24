import { jest } from '@jest/globals';

const mockUserFindOne = jest.fn();
const mockEnsureSystemRoles = jest.fn(async () => undefined);
const mockFindRoleDocuments = jest.fn(async () => []);
const mockPermissionsFromRoleDocs = jest.fn(() => ['perm:a']);
const mockResolveUserPermissions = jest.fn(async () => ['perm:fallback']);

jest.unstable_mockModule(
  '../modules/core/organization/models/user.model.js',
  () => ({
    default: {
      findOne: (...args) => mockUserFindOne(...args),
    },
  })
);

jest.unstable_mockModule('../modules/core/rbac/rbac.service.js', () => ({
  default: {
    ensureSystemRoles: (...args) => mockEnsureSystemRoles(...args),
    findRoleDocuments: (...args) => mockFindRoleDocuments(...args),
    permissionsFromRoleDocs: (...args) => mockPermissionsFromRoleDocs(...args),
    resolveUserPermissions: (...args) => mockResolveUserPermissions(...args),
  },
}));

jest.unstable_mockModule('../config/index.js', () => ({
  default: {
    jwt: {
      accessSecret: 'test-secret-min-32-chars-xxxxxxxxxx',
      accessExpiry: '15m',
    },
  },
}));

const {
  rolesMatch,
  normalizeRoleSet,
  buildAuthContextFromToken,
} = await import('../shared/middleware/authenticate.middleware.js');

function leanQuery(result) {
  return {
    select() {
      return this;
    },
    lean: async () => result,
  };
}

describe('auth role set helpers', () => {
  it('normalizes and sorts roles', () => {
    expect(normalizeRoleSet(['technician', 'ADMIN', 'admin'])).toEqual([
      'ADMIN',
      'TECHNICIAN',
    ]);
  });

  it('matches equivalent role sets regardless of order', () => {
    expect(rolesMatch(['TECHNICIAN', 'ADMIN'], ['ADMIN', 'TECHNICIAN'])).toBe(
      true
    );
    expect(rolesMatch(['ADMIN'], ['TECHNICIAN'])).toBe(false);
  });
});

describe('buildAuthContextFromToken concurrency + security', () => {
  beforeEach(() => {
    mockUserFindOne.mockReset();
    mockEnsureSystemRoles.mockClear();
    mockFindRoleDocuments.mockReset();
    mockPermissionsFromRoleDocs.mockReset();
    mockResolveUserPermissions.mockReset();
    mockPermissionsFromRoleDocs.mockReturnValue(['dashboard:view']);
    mockResolveUserPermissions.mockResolvedValue(['dashboard:view']);
  });

  it('starts User.findOne and Role.find concurrently', async () => {
    const starts = [];
    mockUserFindOne.mockImplementation(() => {
      starts.push({ op: 'user', at: performance.now() });
      return leanQuery({
        _id: { toString: () => 'u1' },
        companyId: { toString: () => 'c1' },
        roles: ['ADMIN'],
        isActive: true,
        deletedAt: null,
      });
    });
    mockFindRoleDocuments.mockImplementation(async () => {
      starts.push({ op: 'role', at: performance.now() });
      await new Promise((r) => setTimeout(r, 40));
      return [{ slug: 'ADMIN', permissions: ['dashboard:view'] }];
    });

    const decoded = {
      sub: 'u1',
      companyId: 'c1',
      roles: ['ADMIN'],
      type: 'access',
    };

    const started = performance.now();
    await buildAuthContextFromToken(decoded);
    const elapsed = performance.now() - started;

    expect(starts.map((s) => s.op).sort()).toEqual(['role', 'user']);
    // Both must begin before either could finish a 40ms role delay alone if sequential.
    const userStart = starts.find((s) => s.op === 'user').at;
    const roleStart = starts.find((s) => s.op === 'role').at;
    expect(Math.abs(userStart - roleStart)).toBeLessThan(15);
    expect(elapsed).toBeLessThan(90);
    expect(mockResolveUserPermissions).not.toHaveBeenCalled();
    expect(mockPermissionsFromRoleDocs).toHaveBeenCalled();
  });

  it('accepts matching Admin JWT/DB roles using prefetch', async () => {
    mockUserFindOne.mockReturnValue(
      leanQuery({
        _id: { toString: () => 'u-admin' },
        companyId: { toString: () => 'co1' },
        roles: ['ADMIN'],
      })
    );
    mockFindRoleDocuments.mockResolvedValue([
      { slug: 'ADMIN', permissions: ['dashboard:view', 'audit:view'] },
    ]);
    mockPermissionsFromRoleDocs.mockReturnValue([
      'dashboard:view',
      'audit:view',
    ]);

    const ctx = await buildAuthContextFromToken({
      sub: 'u-admin',
      companyId: 'co1',
      roles: ['ADMIN'],
      type: 'access',
    });

    expect(ctx.auth.roles).toEqual(['ADMIN']);
    expect(ctx.auth.permissions).toEqual(['dashboard:view', 'audit:view']);
    expect(ctx._meta.usedPrefetchedRoles).toBe(true);
    expect(mockResolveUserPermissions).not.toHaveBeenCalled();
  });

  it('accepts matching Technician JWT/DB roles using prefetch', async () => {
    mockUserFindOne.mockReturnValue(
      leanQuery({
        _id: { toString: () => 'u-tech' },
        companyId: { toString: () => 'co1' },
        roles: ['TECHNICIAN'],
      })
    );
    mockFindRoleDocuments.mockResolvedValue([
      { slug: 'TECHNICIAN', permissions: ['overtime:start'] },
    ]);
    mockPermissionsFromRoleDocs.mockReturnValue(['overtime:start']);

    const ctx = await buildAuthContextFromToken({
      sub: 'u-tech',
      companyId: 'co1',
      roles: ['TECHNICIAN'],
      type: 'access',
    });

    expect(ctx.auth.roles).toEqual(['TECHNICIAN']);
    expect(ctx._meta.usedPrefetchedRoles).toBe(true);
  });

  it('accepts matching Supervisor JWT/DB roles using prefetch', async () => {
    mockUserFindOne.mockReturnValue(
      leanQuery({
        _id: { toString: () => 'u-sup' },
        companyId: { toString: () => 'co1' },
        roles: ['SUPERVISOR'],
      })
    );
    mockFindRoleDocuments.mockResolvedValue([
      { slug: 'SUPERVISOR', permissions: ['organization:view'] },
    ]);
    mockPermissionsFromRoleDocs.mockReturnValue(['organization:view']);

    const ctx = await buildAuthContextFromToken({
      sub: 'u-sup',
      companyId: 'co1',
      roles: ['SUPERVISOR'],
      type: 'access',
    });

    expect(ctx.auth.roles).toEqual(['SUPERVISOR']);
    expect(ctx._meta.usedPrefetchedRoles).toBe(true);
  });

  it('supports multiple roles when JWT and DB match', async () => {
    mockUserFindOne.mockReturnValue(
      leanQuery({
        _id: { toString: () => 'u-multi' },
        companyId: { toString: () => 'co1' },
        roles: ['SUPERVISOR', 'TECHNICIAN'],
      })
    );
    mockFindRoleDocuments.mockResolvedValue([
      { slug: 'SUPERVISOR', permissions: ['organization:view'] },
      { slug: 'TECHNICIAN', permissions: ['overtime:start'] },
    ]);
    mockPermissionsFromRoleDocs.mockReturnValue([
      'organization:view',
      'overtime:start',
    ]);

    const ctx = await buildAuthContextFromToken({
      sub: 'u-multi',
      companyId: 'co1',
      roles: ['TECHNICIAN', 'SUPERVISOR'],
      type: 'access',
    });

    expect(ctx._meta.usedPrefetchedRoles).toBe(true);
    expect(mockFindRoleDocuments).toHaveBeenCalledWith(
      ['TECHNICIAN', 'SUPERVISOR'],
      'co1'
    );
  });

  it('falls back when JWT roles do not match DB roles', async () => {
    mockUserFindOne.mockReturnValue(
      leanQuery({
        _id: { toString: () => 'u1' },
        companyId: { toString: () => 'co1' },
        roles: ['TECHNICIAN'],
      })
    );
    mockFindRoleDocuments.mockResolvedValue([
      { slug: 'ADMIN', permissions: ['dashboard:view'] },
    ]);
    mockResolveUserPermissions.mockResolvedValue(['overtime:start']);

    const ctx = await buildAuthContextFromToken({
      sub: 'u1',
      companyId: 'co1',
      roles: ['ADMIN'],
      type: 'access',
    });

    expect(ctx._meta.usedPrefetchedRoles).toBe(false);
    expect(ctx._meta.jwtRolesCompatible).toBe(false);
    expect(mockResolveUserPermissions).toHaveBeenCalled();
    expect(ctx.auth.permissions).toEqual(['overtime:start']);
    expect(ctx.auth.roles).toEqual(['TECHNICIAN']);
  });

  it('falls back when JWT companyId does not match DB company', async () => {
    mockUserFindOne.mockReturnValue(
      leanQuery({
        _id: { toString: () => 'u1' },
        companyId: { toString: () => 'co-db' },
        roles: ['ADMIN'],
      })
    );
    mockFindRoleDocuments.mockResolvedValue([]);
    mockResolveUserPermissions.mockResolvedValue(['dashboard:view']);

    const ctx = await buildAuthContextFromToken({
      sub: 'u1',
      companyId: 'co-jwt',
      roles: ['ADMIN'],
      type: 'access',
    });

    expect(ctx._meta.companyMatches).toBe(false);
    expect(ctx._meta.usedPrefetchedRoles).toBe(false);
    expect(mockResolveUserPermissions).toHaveBeenCalled();
    expect(ctx.auth.companyId).toBe('co-db');
  });

  it('rejects inactive/missing users (same findOne filter semantics)', async () => {
    mockUserFindOne.mockReturnValue(leanQuery(null));

    await expect(
      buildAuthContextFromToken({
        sub: 'missing',
        companyId: 'co1',
        roles: ['ADMIN'],
        type: 'access',
      })
    ).rejects.toMatchObject({
      message: 'User account is inactive or does not exist',
    });
  });

  it('rejects non-access token types', async () => {
    await expect(
      buildAuthContextFromToken({
        sub: 'u1',
        companyId: 'co1',
        roles: ['ADMIN'],
        type: 'refresh',
      })
    ).rejects.toMatchObject({ message: 'Invalid token type' });
  });

  it('permissionsFromRoleDocs receives DB user, not JWT-only data', async () => {
    const dbUser = {
      _id: { toString: () => 'u1' },
      companyId: { toString: () => 'co1' },
      roles: ['ADMIN'],
      permissionOverrides: [],
    };
    mockUserFindOne.mockReturnValue(leanQuery(dbUser));
    const roleDocs = [{ slug: 'ADMIN', permissions: ['x'] }];
    mockFindRoleDocuments.mockResolvedValue(roleDocs);

    await buildAuthContextFromToken({
      sub: 'u1',
      companyId: 'co1',
      roles: ['ADMIN'],
      type: 'access',
    });

    expect(mockPermissionsFromRoleDocs).toHaveBeenCalledWith(dbUser, roleDocs);
  });
});
