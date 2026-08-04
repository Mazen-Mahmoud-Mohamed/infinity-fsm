import 'package:mobile/core/localization/l10n/app_localizations.dart';

/// Centralized **presentation-only** labels for roles, permission groups,
/// and permission keys/descriptions. Backend identifiers stay unchanged.
///
/// All user-visible permission strings come from ARB (`AppLocalizations`).
class RbacLabels {
  RbacLabels._();

  static bool _isArabic(AppLocalizations l10n) =>
      l10n.localeName.toLowerCase().startsWith('ar');

  // ---------------------------------------------------------------------------
  // Roles
  // ---------------------------------------------------------------------------

  static String role(AppLocalizations l10n, String? roleOrName) {
    final raw = (roleOrName ?? '').trim();
    if (raw.isEmpty) {
      return l10n.valueNotSet;
    }

    final upper = raw.toUpperCase().replaceAll('-', '_').replaceAll(' ', '_');
    switch (upper) {
      case 'ADMIN':
      case 'ADMINISTRATOR':
      case 'SYSTEM_ADMINISTRATOR':
      case 'SYS_ADMIN':
        return l10n.usersRoleAdmin;
      case 'SUPERVISOR':
        return l10n.usersRoleSupervisor;
      case 'TECHNICIAN':
      case 'FIELD_TECHNICIAN':
        return l10n.usersRoleTechnician;
      case 'HR':
      case 'HUMAN_RESOURCES':
        return l10n.usersRoleHr;
      case 'WAREHOUSE':
      case 'WAREHOUSE_MANAGER':
        return l10n.usersRoleWarehouse;
      case 'VIEWER':
      case 'READ_ONLY':
        return l10n.usersRoleViewer;
      case 'MANAGER':
        return l10n.usersRoleManager;
    }

    final lower = raw.toLowerCase();
    if (lower == 'administrator' || lower == 'admin') {
      return l10n.usersRoleAdmin;
    }
    if (lower == 'supervisor') return l10n.usersRoleSupervisor;
    if (lower == 'technician') return l10n.usersRoleTechnician;
    if (lower == 'warehouse') return l10n.usersRoleWarehouse;
    if (lower == 'viewer') return l10n.usersRoleViewer;
    if (lower == 'manager') return l10n.usersRoleManager;
    if (lower == 'hr' || lower == 'human resources') {
      return l10n.usersRoleHr;
    }

    return raw;
  }

  // ---------------------------------------------------------------------------
  // Permission groups
  // ---------------------------------------------------------------------------

  static String group(AppLocalizations l10n, String module) {
    switch (module.trim().toLowerCase()) {
      case 'dashboard':
        return l10n.permGroupDashboard;
      case 'users':
        return l10n.permGroupUsers;
      case 'roles':
      case 'rbac':
        return l10n.permGroupRoles;
      case 'attendance':
        return l10n.permGroupAttendance;
      case 'overtime':
        return l10n.permGroupOvertime;
      case 'inventory':
        return l10n.permGroupInventory;
      case 'assets':
        return l10n.permGroupAssets;
      case 'pm':
      case 'maintenance':
      case 'preventive_maintenance':
        return l10n.permGroupMaintenance;
      case 'reports':
      case 'service_reports':
        return l10n.permGroupServiceReports;
      case 'work_orders':
        return l10n.permGroupWorkOrders;
      case 'settings':
        return l10n.permGroupSettings;
      case 'profile':
        return l10n.permGroupProfile;
      case 'notifications':
        return l10n.permGroupNotifications;
      case 'organization':
        return l10n.permGroupOrganization;
      case 'audit':
        return l10n.permGroupAudit;
      case 'general':
        return l10n.permGroupGeneral;
      default:
        return _titleCase(module.replaceAll('_', ' '));
    }
  }

  static String groupDescription(AppLocalizations l10n, String module) {
    switch (module.trim().toLowerCase()) {
      case 'dashboard':
        return l10n.permGroupDashboardDesc;
      case 'users':
        return l10n.permGroupUsersDesc;
      case 'roles':
      case 'rbac':
        return l10n.permGroupRolesDesc;
      case 'attendance':
        return l10n.permGroupAttendanceDesc;
      case 'overtime':
        return l10n.permGroupOvertimeDesc;
      case 'inventory':
        return l10n.permGroupInventoryDesc;
      case 'assets':
        return l10n.permGroupAssetsDesc;
      case 'pm':
      case 'maintenance':
      case 'preventive_maintenance':
        return l10n.permGroupMaintenanceDesc;
      case 'reports':
      case 'service_reports':
        return l10n.permGroupServiceReportsDesc;
      case 'work_orders':
        return l10n.permGroupWorkOrdersDesc;
      case 'settings':
        return l10n.permGroupSettingsDesc;
      case 'profile':
        return l10n.permGroupProfileDesc;
      case 'notifications':
        return l10n.permGroupNotificationsDesc;
      case 'organization':
        return l10n.permGroupOrganizationDesc;
      case 'audit':
        return l10n.permGroupAuditDesc;
      case 'general':
        return l10n.permGroupGeneralDesc;
      default:
        return '';
    }
  }

  // ---------------------------------------------------------------------------
  // Permission keys + descriptions (ARB)
  // ---------------------------------------------------------------------------

  static (String name, String description) permissionPair(
    AppLocalizations l10n,
    String key,
  ) {
    final normalized = key.trim();
    if (normalized.isEmpty) {
      return (normalized, '');
    }

    switch (normalized) {
      case 'organization:view':
        return (l10n.permOrganizationView, l10n.permOrganizationViewDesc);
      case 'organization:manage_branches':
        return (
          l10n.permOrganizationManageBranches,
          l10n.permOrganizationManageBranchesDesc,
        );
      case 'organization:manage_regions':
        return (
          l10n.permOrganizationManageRegions,
          l10n.permOrganizationManageRegionsDesc,
        );
      case 'organization:manage_cities':
        return (
          l10n.permOrganizationManageCities,
          l10n.permOrganizationManageCitiesDesc,
        );
      case 'organization:manage_departments':
        return (
          l10n.permOrganizationManageDepartments,
          l10n.permOrganizationManageDepartmentsDesc,
        );
      case 'organization:manage_teams':
        return (
          l10n.permOrganizationManageTeams,
          l10n.permOrganizationManageTeamsDesc,
        );
      case 'organization:manage_users':
        return (
          l10n.permOrganizationManageUsers,
          l10n.permOrganizationManageUsersDesc,
        );
      case 'settings:view':
        return (l10n.permSettingsView, l10n.permSettingsViewDesc);
      case 'settings:manage':
        return (l10n.permSettingsManage, l10n.permSettingsManageDesc);
      case 'settings:update':
        return (l10n.permSettingsUpdate, l10n.permSettingsUpdateDesc);
      case 'settings:manage_holidays':
        return (
          l10n.permSettingsManageHolidays,
          l10n.permSettingsManageHolidaysDesc,
        );
      case 'audit:view':
        return (l10n.permAuditView, l10n.permAuditViewDesc);
      case 'dashboard:view':
        return (l10n.permDashboardView, l10n.permDashboardViewDesc);
      case 'rbac:manage_roles':
        return (l10n.permRbacManageRoles, l10n.permRbacManageRolesDesc);
      case 'rbac:manage_permissions':
        return (
          l10n.permRbacManagePermissions,
          l10n.permRbacManagePermissionsDesc,
        );
      case 'roles:view':
        return (l10n.permRolesView, l10n.permRolesViewDesc);
      case 'roles:create':
        return (l10n.permRolesCreate, l10n.permRolesCreateDesc);
      case 'roles:update':
        return (l10n.permRolesUpdate, l10n.permRolesUpdateDesc);
      case 'roles:delete':
        return (l10n.permRolesDelete, l10n.permRolesDeleteDesc);
      case 'roles:manage':
        return (l10n.permRolesManage, l10n.permRolesManageDesc);
      case 'attendance:view_own':
        return (l10n.permAttendanceViewOwn, l10n.permAttendanceViewOwnDesc);
      case 'attendance:view_team':
        return (l10n.permAttendanceViewTeam, l10n.permAttendanceViewTeamDesc);
      case 'attendance:view_all':
        return (l10n.permAttendanceViewAll, l10n.permAttendanceViewAllDesc);
      case 'attendance:manage_own':
        return (
          l10n.permAttendanceManageOwn,
          l10n.permAttendanceManageOwnDesc,
        );
      case 'attendance:view':
        return (l10n.permAttendanceView, l10n.permAttendanceViewDesc);
      case 'attendance:update':
        return (l10n.permAttendanceUpdate, l10n.permAttendanceUpdateDesc);
      case 'attendance:approve':
        return (l10n.permAttendanceApprove, l10n.permAttendanceApproveDesc);
      case 'overtime:view_own':
        return (l10n.permOvertimeViewOwn, l10n.permOvertimeViewOwnDesc);
      case 'overtime:view_team':
        return (l10n.permOvertimeViewTeam, l10n.permOvertimeViewTeamDesc);
      case 'overtime:view_all':
        return (l10n.permOvertimeViewAll, l10n.permOvertimeViewAllDesc);
      case 'overtime:create':
        return (l10n.permOvertimeCreate, l10n.permOvertimeCreateDesc);
      case 'overtime:start':
        return (l10n.permOvertimeStart, l10n.permOvertimeStartDesc);
      case 'overtime:end':
        return (l10n.permOvertimeEnd, l10n.permOvertimeEndDesc);
      case 'overtime:cancel':
        return (l10n.permOvertimeCancel, l10n.permOvertimeCancelDesc);
      case 'overtime:approve':
        return (l10n.permOvertimeApprove, l10n.permOvertimeApproveDesc);
      case 'overtime:reject':
        return (l10n.permOvertimeReject, l10n.permOvertimeRejectDesc);
      case 'overtime:archive':
        return (l10n.permOvertimeArchive, l10n.permOvertimeArchiveDesc);
      case 'work_orders:view_own':
        return (l10n.permWorkOrdersViewOwn, l10n.permWorkOrdersViewOwnDesc);
      case 'work_orders:view_team':
        return (l10n.permWorkOrdersViewTeam, l10n.permWorkOrdersViewTeamDesc);
      case 'work_orders:view_all':
        return (l10n.permWorkOrdersViewAll, l10n.permWorkOrdersViewAllDesc);
      case 'work_orders:create':
        return (l10n.permWorkOrdersCreate, l10n.permWorkOrdersCreateDesc);
      case 'work_orders:update':
        return (l10n.permWorkOrdersUpdate, l10n.permWorkOrdersUpdateDesc);
      case 'work_orders:assign':
        return (l10n.permWorkOrdersAssign, l10n.permWorkOrdersAssignDesc);
      case 'work_orders:complete':
        return (l10n.permWorkOrdersComplete, l10n.permWorkOrdersCompleteDesc);
      case 'work_orders:cancel':
        return (l10n.permWorkOrdersCancel, l10n.permWorkOrdersCancelDesc);
      case 'work_orders:delete':
        return (l10n.permWorkOrdersDelete, l10n.permWorkOrdersDeleteDesc);
      case 'inventory:view':
        return (l10n.permInventoryView, l10n.permInventoryViewDesc);
      case 'inventory:create':
        return (l10n.permInventoryCreate, l10n.permInventoryCreateDesc);
      case 'inventory:update':
        return (l10n.permInventoryUpdate, l10n.permInventoryUpdateDesc);
      case 'inventory:delete':
        return (l10n.permInventoryDelete, l10n.permInventoryDeleteDesc);
      case 'inventory:stock_manage':
        return (
          l10n.permInventoryStockManage,
          l10n.permInventoryStockManageDesc,
        );
      case 'assets:view':
        return (l10n.permAssetsView, l10n.permAssetsViewDesc);
      case 'assets:create':
        return (l10n.permAssetsCreate, l10n.permAssetsCreateDesc);
      case 'assets:update':
        return (l10n.permAssetsUpdate, l10n.permAssetsUpdateDesc);
      case 'assets:delete':
        return (l10n.permAssetsDelete, l10n.permAssetsDeleteDesc);
      case 'assets:assign':
        return (l10n.permAssetsAssign, l10n.permAssetsAssignDesc);
      case 'pm:view':
        return (l10n.permPmView, l10n.permPmViewDesc);
      case 'pm:create':
        return (l10n.permPmCreate, l10n.permPmCreateDesc);
      case 'pm:update':
        return (l10n.permPmUpdate, l10n.permPmUpdateDesc);
      case 'pm:delete':
        return (l10n.permPmDelete, l10n.permPmDeleteDesc);
      case 'pm:manage':
        return (l10n.permPmManage, l10n.permPmManageDesc);
      case 'maintenance:manage':
        return (l10n.permMaintenanceManage, l10n.permMaintenanceManageDesc);
      case 'reports:view':
        return (l10n.permReportsView, l10n.permReportsViewDesc);
      case 'reports:generate':
        return (l10n.permReportsGenerate, l10n.permReportsGenerateDesc);
      case 'reports:download':
        return (l10n.permReportsDownload, l10n.permReportsDownloadDesc);
      case 'users:view':
        return (l10n.permUsersView, l10n.permUsersViewDesc);
      case 'users:create':
        return (l10n.permUsersCreate, l10n.permUsersCreateDesc);
      case 'users:update':
        return (l10n.permUsersUpdate, l10n.permUsersUpdateDesc);
      case 'users:delete':
        return (l10n.permUsersDelete, l10n.permUsersDeleteDesc);
      case 'users:read':
        return (l10n.permUsersRead, l10n.permUsersReadDesc);
      case 'users:reset_password':
        return (l10n.permUsersResetPassword, l10n.permUsersResetPasswordDesc);
      default:
        return (
          _fallbackPermissionLabel(l10n, normalized),
          _fallbackPermissionDescription(l10n, normalized),
        );
    }
  }

  static String permission(AppLocalizations l10n, String key) =>
      permissionPair(l10n, key).$1;

  static String permissionDescription(AppLocalizations l10n, String key) =>
      permissionPair(l10n, key).$2;

  static String _fallbackPermissionLabel(AppLocalizations l10n, String key) {
    final parts = key.split(':');
    if (parts.length < 2) {
      return _titleCase(key.replaceAll('_', ' '));
    }
    final module = group(l10n, parts.first);
    final action = _titleCase(parts.sublist(1).join(' ').replaceAll('_', ' '));
    if (_isArabic(l10n)) {
      return '$action $module'.trim();
    }
    return '$action $module'.trim();
  }

  static String _fallbackPermissionDescription(
    AppLocalizations l10n,
    String key,
  ) {
    final label = _fallbackPermissionLabel(l10n, key);
    if (_isArabic(l10n)) {
      return 'يسمح بالوصول إلى: $label.';
    }
    return 'Allows access to: $label.';
  }

  static String _titleCase(String input) {
    if (input.isEmpty) return input;
    return input
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .map((w) => '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }
}

String localizeRoleLabel(AppLocalizations l10n, String? role) =>
    RbacLabels.role(l10n, role);

String localizePermissionGroup(AppLocalizations l10n, String module) =>
    RbacLabels.group(l10n, module);

String localizePermissionGroupDescription(
  AppLocalizations l10n,
  String module,
) =>
    RbacLabels.groupDescription(l10n, module);

String localizePermissionKey(AppLocalizations l10n, String key) =>
    RbacLabels.permission(l10n, key);

String localizePermissionDescription(AppLocalizations l10n, String key) =>
    RbacLabels.permissionDescription(l10n, key);

extension RbacLabelsLocalizations on AppLocalizations {
  String roleLabelFor(String? role) => RbacLabels.role(this, role);

  String permissionGroupFor(String module) => RbacLabels.group(this, module);

  String permissionLabelFor(String key) => RbacLabels.permission(this, key);

  String permissionDescriptionFor(String key) =>
      RbacLabels.permissionDescription(this, key);
}
