export const ROLES = Object.freeze({
  ADMIN: 'ADMIN',
  SUPERVISOR: 'SUPERVISOR',
  TECHNICIAN: 'TECHNICIAN',
  HR: 'HR',
  WAREHOUSE: 'WAREHOUSE',
  VIEWER: 'VIEWER',
});

export const ROLE_SLUGS = Object.freeze(Object.values(ROLES));

export const SYSTEM_ROLE_DEFINITIONS = Object.freeze([
  {
    slug: ROLES.ADMIN,
    name: 'Administrator',
    description: 'Full system access',
    color: '#C62828',
  },
  {
    slug: ROLES.SUPERVISOR,
    name: 'Supervisor',
    description: 'Team and operations management',
    color: '#1565C0',
  },
  {
    slug: ROLES.TECHNICIAN,
    name: 'Technician',
    description: 'Field service execution',
    color: '#2E7D32',
  },
  {
    slug: ROLES.WAREHOUSE,
    name: 'Warehouse',
    description: 'Inventory and stock management',
    color: '#EF6C00',
  },
  {
    slug: ROLES.VIEWER,
    name: 'Viewer',
    description: 'Read-only access',
    color: '#546E7A',
  },
  {
    slug: ROLES.HR,
    name: 'HR',
    description: 'Human resources (legacy system role)',
    color: '#6A1B9A',
  },
]);

export default ROLES;
