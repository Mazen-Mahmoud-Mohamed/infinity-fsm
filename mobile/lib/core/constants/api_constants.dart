class ApiConstants {
  ApiConstants._();

  static const String authLogin = '/auth/login';
  static const String authRefresh = '/auth/refresh';
  static const String authLogout = '/auth/logout';
  static const String authMe = '/auth/me';

  static const String organizationContext = '/organization/me/context';
  static const String organizationSummary = '/organization/summary';
  static const String organizationsCompanies = '/organization/companies';
  static const String organizationBranches = '/organization/branches';
  static const String organizationDepartments = '/organization/departments';
  static const String organizationTeams = '/organization/teams';
  static const String organizationPositions = '/organization/positions';
  static const String organizationUsers = '/organization/users';

  static const String attendanceSessions = '/attendance';
  static const String attendanceClockIn = '/attendance/clock-in';
  static const String attendanceClockOut = '/attendance/clock-out';
  static const String attendanceBreakStart = '/attendance/break-start';
  static const String attendanceBreakEnd = '/attendance/break-end';
  static const String attendanceStatus = '/attendance/status';
  static const String attendanceToday = '/attendance/today';
  static const String attendanceHistory = '/attendance/history';
  static const String attendanceGpsAddress = '/attendance/gps-address';

  static String attendanceById(String id) => '/attendance/$id';

  static const String overtimeSessions = '/overtime';
  static const String overtimeRunning = '/overtime/running';
  static const String overtimeMine = '/overtime/mine';
  static const String overtimeStats = '/overtime/stats';
  static const String overtimeStart = '/overtime/start';
  static const String overtimeExport = '/overtime/export';

  static String overtimeArrivedAtWorkSite(String id) =>
      '/overtime/$id/arrived-at-work-site';

  static String overtimeFinishedWork(String id) =>
      '/overtime/$id/finished-work';

  static String overtimeGpsAddress(String id) => '/overtime/$id/gps-address';

  static const String workOrders = '/work-orders';
  static const String workOrdersMine = '/work-orders/my-assignments';

  static const String inventoryDashboard = '/inventory/dashboard';
  static const String inventoryWarehouses = '/inventory/warehouses';
  static const String inventoryParts = '/inventory/parts';
  static const String inventoryMovements = '/inventory/movements';
  static const String inventoryStockIn = '/inventory/movements/stock-in';
  static const String inventoryStockOut = '/inventory/movements/stock-out';
  static const String inventoryTransfer = '/inventory/movements/transfer';
  static const String inventoryAdjustment = '/inventory/movements/adjustment';

  static const String assets = '/assets';
  static const String assetsDashboard = '/assets/dashboard';
  static const String assetsCategories = '/assets/categories';
  static const String assetsHistory = '/assets/history';

  static const String pmDashboard = '/pm/dashboard';
  static const String pmPlans = '/pm/plans';
  static const String pmSchedules = '/pm/schedules';
  static const String pmHistory = '/pm/history';

  static const String reports = '/reports';
  static const String reportsDashboard = '/reports/dashboard';
  static const String reportsGenerate = '/reports/generate';
  static const String reportsSignatures = '/reports/signatures';

  static const String users = '/users';
  static const String usersDashboard = '/users/dashboard';
  static const String usersChangePassword = '/users/me/change-password';

  static const String roles = '/roles';
  static const String rolesDashboard = '/roles/dashboard';
  static const String rolesPermissions = '/roles/permissions';

  static const String settingsOrganization = '/settings/organization';
  static const String settingsOrganizationLogo = '/settings/organization/logo';
  static const String settingsSystem = '/settings/system';

  static const String dashboardSummary = '/dashboard/summary';

  static const String serverTime = '/time';
  static const String securityEvents = '/security/events';
}
