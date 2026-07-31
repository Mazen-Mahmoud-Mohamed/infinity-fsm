export const PERMISSIONS = Object.freeze({
  // Organization
  ORGANIZATION_VIEW: 'organization:view',
  ORGANIZATION_MANAGE_BRANCHES: 'organization:manage_branches',
  ORGANIZATION_MANAGE_REGIONS: 'organization:manage_regions',
  ORGANIZATION_MANAGE_CITIES: 'organization:manage_cities',
  ORGANIZATION_MANAGE_DEPARTMENTS: 'organization:manage_departments',
  ORGANIZATION_MANAGE_TEAMS: 'organization:manage_teams',
  ORGANIZATION_MANAGE_USERS: 'organization:manage_users',

  // Settings
  SETTINGS_VIEW: 'settings:view',
  SETTINGS_MANAGE: 'settings:manage',
  SETTINGS_MANAGE_HOLIDAYS: 'settings:manage_holidays',

  // Audit
  AUDIT_VIEW: 'audit:view',

  // Dashboard
  DASHBOARD_VIEW: 'dashboard:view',

  // RBAC (legacy keys — kept for backward compatibility)
  RBAC_MANAGE_ROLES: 'rbac:manage_roles',
  RBAC_MANAGE_PERMISSIONS: 'rbac:manage_permissions',

  // Roles Management
  ROLES_VIEW: 'roles:view',
  ROLES_CREATE: 'roles:create',
  ROLES_UPDATE: 'roles:update',
  ROLES_DELETE: 'roles:delete',

  // Attendance
  ATTENDANCE_VIEW_OWN: 'attendance:view_own',
  ATTENDANCE_VIEW_TEAM: 'attendance:view_team',
  ATTENDANCE_VIEW_ALL: 'attendance:view_all',
  ATTENDANCE_MANAGE_OWN: 'attendance:manage_own',

  // Overtime
  OVERTIME_VIEW_OWN: 'overtime:view_own',
  OVERTIME_VIEW_TEAM: 'overtime:view_team',
  OVERTIME_VIEW_ALL: 'overtime:view_all',
  OVERTIME_CREATE: 'overtime:create',
  OVERTIME_START: 'overtime:start',
  OVERTIME_END: 'overtime:end',
  OVERTIME_CANCEL: 'overtime:cancel',
  OVERTIME_APPROVE: 'overtime:approve',
  OVERTIME_REJECT: 'overtime:reject',

  // Work Orders
  WORK_ORDERS_VIEW_OWN: 'work_orders:view_own',
  WORK_ORDERS_VIEW_TEAM: 'work_orders:view_team',
  WORK_ORDERS_VIEW_ALL: 'work_orders:view_all',
  WORK_ORDERS_CREATE: 'work_orders:create',
  WORK_ORDERS_UPDATE: 'work_orders:update',
  WORK_ORDERS_ASSIGN: 'work_orders:assign',
  WORK_ORDERS_COMPLETE: 'work_orders:complete',
  WORK_ORDERS_CANCEL: 'work_orders:cancel',

  // Inventory
  INVENTORY_VIEW: 'inventory:view',
  INVENTORY_CREATE: 'inventory:create',
  INVENTORY_UPDATE: 'inventory:update',
  INVENTORY_DELETE: 'inventory:delete',
  INVENTORY_STOCK_MANAGE: 'inventory:stock_manage',

  // Assets
  ASSETS_VIEW: 'assets:view',
  ASSETS_CREATE: 'assets:create',
  ASSETS_UPDATE: 'assets:update',
  ASSETS_DELETE: 'assets:delete',

  // Preventive Maintenance
  PM_VIEW: 'pm:view',
  PM_CREATE: 'pm:create',
  PM_UPDATE: 'pm:update',
  PM_DELETE: 'pm:delete',

  // Service Reports & Customer Signatures
  REPORTS_VIEW: 'reports:view',
  REPORTS_GENERATE: 'reports:generate',
  REPORTS_DOWNLOAD: 'reports:download',

  // User Management
  USERS_VIEW: 'users:view',
  USERS_CREATE: 'users:create',
  USERS_UPDATE: 'users:update',
  USERS_DELETE: 'users:delete',
  USERS_RESET_PASSWORD: 'users:reset_password',
});

const WORK_ORDER_PERMISSIONS = [
  PERMISSIONS.WORK_ORDERS_VIEW_OWN,
  PERMISSIONS.WORK_ORDERS_VIEW_TEAM,
  PERMISSIONS.WORK_ORDERS_VIEW_ALL,
  PERMISSIONS.WORK_ORDERS_CREATE,
  PERMISSIONS.WORK_ORDERS_UPDATE,
  PERMISSIONS.WORK_ORDERS_ASSIGN,
  PERMISSIONS.WORK_ORDERS_COMPLETE,
  PERMISSIONS.WORK_ORDERS_CANCEL,
];

const INVENTORY_MANAGE_PERMISSIONS = [
  PERMISSIONS.INVENTORY_VIEW,
  PERMISSIONS.INVENTORY_CREATE,
  PERMISSIONS.INVENTORY_UPDATE,
  PERMISSIONS.INVENTORY_STOCK_MANAGE,
];

const ASSETS_MANAGE_PERMISSIONS = [
  PERMISSIONS.ASSETS_VIEW,
  PERMISSIONS.ASSETS_CREATE,
  PERMISSIONS.ASSETS_UPDATE,
];

const PM_MANAGE_PERMISSIONS = [
  PERMISSIONS.PM_VIEW,
  PERMISSIONS.PM_CREATE,
  PERMISSIONS.PM_UPDATE,
];

const REPORTS_MANAGE_PERMISSIONS = [
  PERMISSIONS.REPORTS_VIEW,
  PERMISSIONS.REPORTS_GENERATE,
  PERMISSIONS.REPORTS_DOWNLOAD,
];

const USERS_MANAGE_PERMISSIONS = [
  PERMISSIONS.USERS_VIEW,
  PERMISSIONS.USERS_CREATE,
  PERMISSIONS.USERS_UPDATE,
  PERMISSIONS.USERS_RESET_PASSWORD,
];

const ROLES_MANAGE_PERMISSIONS = [
  PERMISSIONS.ROLES_VIEW,
  PERMISSIONS.ROLES_CREATE,
  PERMISSIONS.ROLES_UPDATE,
  PERMISSIONS.ROLES_DELETE,
  PERMISSIONS.RBAC_MANAGE_ROLES,
  PERMISSIONS.RBAC_MANAGE_PERMISSIONS,
];

const VIEWER_PERMISSIONS = [
  PERMISSIONS.ORGANIZATION_VIEW,
  PERMISSIONS.SETTINGS_VIEW,
  PERMISSIONS.ATTENDANCE_VIEW_OWN,
  PERMISSIONS.OVERTIME_VIEW_OWN,
  PERMISSIONS.WORK_ORDERS_VIEW_OWN,
  PERMISSIONS.INVENTORY_VIEW,
  PERMISSIONS.ASSETS_VIEW,
  PERMISSIONS.PM_VIEW,
  PERMISSIONS.REPORTS_VIEW,
];

const WAREHOUSE_PERMISSIONS = [
  PERMISSIONS.ORGANIZATION_VIEW,
  ...INVENTORY_MANAGE_PERMISSIONS,
  PERMISSIONS.INVENTORY_DELETE,
  PERMISSIONS.ASSETS_VIEW,
  PERMISSIONS.REPORTS_VIEW,
];

export const ROLE_PERMISSIONS = Object.freeze({
  ADMIN: Object.values(PERMISSIONS),

  SUPERVISOR: [
    PERMISSIONS.ORGANIZATION_VIEW,
    PERMISSIONS.SETTINGS_VIEW,
    PERMISSIONS.DASHBOARD_VIEW,
    PERMISSIONS.ATTENDANCE_VIEW_OWN,
    PERMISSIONS.ATTENDANCE_VIEW_TEAM,
    PERMISSIONS.ATTENDANCE_MANAGE_OWN,
    PERMISSIONS.OVERTIME_VIEW_OWN,
    PERMISSIONS.OVERTIME_VIEW_TEAM,
    PERMISSIONS.OVERTIME_START,
    PERMISSIONS.OVERTIME_END,
    ...WORK_ORDER_PERMISSIONS,
    ...INVENTORY_MANAGE_PERMISSIONS,
    ...ASSETS_MANAGE_PERMISSIONS,
    ...PM_MANAGE_PERMISSIONS,
    ...REPORTS_MANAGE_PERMISSIONS,
    ...USERS_MANAGE_PERMISSIONS,
    PERMISSIONS.ROLES_VIEW,
  ],

  TECHNICIAN: [
    PERMISSIONS.DASHBOARD_VIEW,
    PERMISSIONS.ATTENDANCE_VIEW_OWN,
    PERMISSIONS.ATTENDANCE_MANAGE_OWN,
    PERMISSIONS.OVERTIME_VIEW_OWN,
    PERMISSIONS.OVERTIME_CREATE,
    PERMISSIONS.OVERTIME_START,
    PERMISSIONS.OVERTIME_END,
    PERMISSIONS.OVERTIME_CANCEL,
    PERMISSIONS.WORK_ORDERS_VIEW_OWN,
    PERMISSIONS.WORK_ORDERS_COMPLETE,
    PERMISSIONS.INVENTORY_VIEW,
    PERMISSIONS.ASSETS_VIEW,
    PERMISSIONS.PM_VIEW,
    PERMISSIONS.REPORTS_VIEW,
    PERMISSIONS.REPORTS_GENERATE,
  ],

  HR: [
    PERMISSIONS.ORGANIZATION_VIEW,
    PERMISSIONS.SETTINGS_VIEW,
    PERMISSIONS.AUDIT_VIEW,
    PERMISSIONS.ATTENDANCE_VIEW_ALL,
    ...USERS_MANAGE_PERMISSIONS,
    PERMISSIONS.ROLES_VIEW,
  ],

  WAREHOUSE: WAREHOUSE_PERMISSIONS,

  VIEWER: VIEWER_PERMISSIONS,
});

/**
 * Sync fallback used when Role documents are missing.
 * Dynamic resolution prefers Role.permissions from the database.
 */
export function getPermissionsForRoles(roles) {
  const permissionSet = new Set();

  for (const role of roles || []) {
    const permissions = ROLE_PERMISSIONS[role] || [];
    permissions.forEach((permission) => permissionSet.add(permission));
  }

  return Array.from(permissionSet);
}

export function getPermissionCatalog() {
  return Object.entries(PERMISSIONS).map(([constant, key]) => {
    const [module, ...actionParts] = key.split(':');
    return {
      key,
      constant,
      module,
      action: actionParts.join(':'),
    };
  });
}

export default PERMISSIONS;
