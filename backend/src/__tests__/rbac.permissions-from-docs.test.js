import rbacService from '../modules/core/rbac/rbac.service.js';
import { getPermissionsForRoles } from '../shared/constants/permissions.constants.js';
import { ROLES } from '../shared/constants/roles.constants.js';

describe('rbac permissionsFromRoleDocs parity', () => {
  it('matches static ROLE_PERMISSIONS when role docs are empty', () => {
    const user = {
      roles: [ROLES.SUPERVISOR],
      permissionOverrides: [],
    };
    const fromDocs = rbacService.permissionsFromRoleDocs(user, []);
    const expected = getPermissionsForRoles([ROLES.SUPERVISOR]);
    expect([...fromDocs].sort()).toEqual([...expected].sort());
  });

  it('uses Role.permissions when present and applies overrides', () => {
    const user = {
      roles: [ROLES.TECHNICIAN],
      permissionOverrides: [{ type: 'grant', permission: 'custom:perm' }],
    };
    const fromDocs = rbacService.permissionsFromRoleDocs(user, [
      { slug: ROLES.TECHNICIAN, permissions: ['overtime:start'] },
    ]);
    expect(fromDocs).toEqual(
      expect.arrayContaining(['overtime:start', 'custom:perm'])
    );
  });
});
