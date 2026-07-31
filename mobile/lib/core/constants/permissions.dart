/// Permission keys aligned with backend RBAC catalog (docs/RBAC.md).
class Permissions {
  Permissions._();

  static const String overtimeViewOwn = 'overtime:view_own';
  static const String overtimeViewTeam = 'overtime:view_team';
  static const String overtimeViewAll = 'overtime:view_all';
  static const String overtimeCreate = 'overtime:create';
  static const String overtimeStart = 'overtime:start';
  static const String overtimeEnd = 'overtime:end';
  static const String overtimeCancel = 'overtime:cancel';
  static const String overtimeApprove = 'overtime:approve';
  static const String overtimeReject = 'overtime:reject';
  static const String overtimeArchive = 'overtime:archive';

  static const String workOrdersViewOwn = 'work_orders:view_own';
  static const String workOrdersViewTeam = 'work_orders:view_team';
  static const String workOrdersViewAll = 'work_orders:view_all';
  static const String workOrdersCreate = 'work_orders:create';
  static const String workOrdersUpdate = 'work_orders:update';
  static const String workOrdersAssign = 'work_orders:assign';
  static const String workOrdersComplete = 'work_orders:complete';
  static const String workOrdersCancel = 'work_orders:cancel';

  static const String organizationView = 'organization:view';
  static const String organizationManageUsers = 'organization:manage_users';
  static const String organizationManageBranches = 'organization:manage_branches';
  static const String organizationManageDepartments =
      'organization:manage_departments';

  static const String attendanceViewOwn = 'attendance:view_own';
  static const String attendanceViewTeam = 'attendance:view_team';
  static const String attendanceViewAll = 'attendance:view_all';
  static const String attendanceManageOwn = 'attendance:manage_own';

  static const String inventoryView = 'inventory:view';
  static const String inventoryCreate = 'inventory:create';
  static const String inventoryUpdate = 'inventory:update';
  static const String inventoryDelete = 'inventory:delete';
  static const String inventoryStockManage = 'inventory:stock_manage';

  static const String assetsView = 'assets:view';
  static const String assetsCreate = 'assets:create';
  static const String assetsUpdate = 'assets:update';
  static const String assetsDelete = 'assets:delete';

  static const String pmView = 'pm:view';
  static const String pmCreate = 'pm:create';
  static const String pmUpdate = 'pm:update';
  static const String pmDelete = 'pm:delete';

  static const String reportsView = 'reports:view';
  static const String reportsGenerate = 'reports:generate';
  static const String reportsDownload = 'reports:download';

  static const String usersView = 'users:view';
  static const String usersCreate = 'users:create';
  static const String usersUpdate = 'users:update';
  static const String usersDelete = 'users:delete';
  static const String usersResetPassword = 'users:reset_password';

  static const String rolesView = 'roles:view';
  static const String rolesCreate = 'roles:create';
  static const String rolesUpdate = 'roles:update';
  static const String rolesDelete = 'roles:delete';

  static const String settingsView = 'settings:view';
  static const String settingsManage = 'settings:manage';

  static const String dashboardView = 'dashboard:view';
}
