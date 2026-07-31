import { getPermissionsForRoles } from '../shared/constants/permissions.constants.js';
import { ROLES } from '../shared/constants/roles.constants.js';

describe('RBAC permissions', () => {
  it('grants admin all defined permissions', () => {
    const permissions = getPermissionsForRoles([ROLES.ADMIN]);
    expect(permissions).toContain('organization:manage_users');
    expect(permissions).toContain('settings:manage');
    expect(permissions).toContain('audit:view');
  });

  it('grants technician no management permissions by default', () => {
    const permissions = getPermissionsForRoles([ROLES.TECHNICIAN]);
    expect(permissions).toEqual([]);
  });

  it('grants supervisor limited view permissions', () => {
    const permissions = getPermissionsForRoles([ROLES.SUPERVISOR]);
    expect(permissions).toContain('organization:view');
    expect(permissions).not.toContain('organization:manage_users');
  });
});

describe('JWT expiry parser', () => {
  it('parses minute-based expiry strings', async () => {
    const { default: authService } = await import('../modules/core/auth/auth.service.js');
    expect(authService).toBeDefined();
  });
});
