import 'package:mobile/core/constants/permissions.dart';

class PermissionChecker {
  const PermissionChecker(this._permissions);

  final List<String> _permissions;

  bool hasPermission(String permission) => _permissions.contains(permission);

  bool canViewOvertime() {
    return hasPermission(Permissions.overtimeViewOwn) ||
        hasPermission(Permissions.overtimeViewTeam) ||
        hasPermission(Permissions.overtimeViewAll);
  }

  bool canViewAllOvertime() {
    return hasPermission(Permissions.overtimeViewAll);
  }

  bool canApproveOvertime() {
    return hasPermission(Permissions.overtimeApprove);
  }

  bool canRejectOvertime() {
    return hasPermission(Permissions.overtimeReject);
  }

  bool canManageUsers() {
    return hasPermission(Permissions.organizationManageUsers);
  }

  bool canCreateWorkOrder() {
    return hasPermission(Permissions.workOrdersCreate);
  }

  bool canViewOwnWorkOrders() {
    return hasPermission(Permissions.workOrdersViewOwn);
  }

  bool canViewTeamWorkOrders() {
    return hasPermission(Permissions.workOrdersViewTeam);
  }

  bool canViewAllWorkOrders() {
    return hasPermission(Permissions.workOrdersViewAll);
  }

  bool canViewWorkOrders() {
    return canViewOwnWorkOrders() ||
        canViewTeamWorkOrders() ||
        canViewAllWorkOrders();
  }

  bool canManageWorkOrders() {
    return canCreateWorkOrder() ||
        canUpdateWorkOrder() ||
        canAssignWorkOrder();
  }

  bool canUpdateWorkOrder() {
    return hasPermission(Permissions.workOrdersUpdate);
  }

  bool canAssignWorkOrder() {
    return hasPermission(Permissions.workOrdersAssign);
  }

  bool canCompleteWorkOrder() {
    return hasPermission(Permissions.workOrdersComplete);
  }

  bool canCancelWorkOrder() {
    return hasPermission(Permissions.workOrdersCancel);
  }

  bool canViewInventory() {
    return hasPermission(Permissions.inventoryView);
  }

  bool canCreateInventory() {
    return hasPermission(Permissions.inventoryCreate);
  }

  bool canUpdateInventory() {
    return hasPermission(Permissions.inventoryUpdate);
  }

  bool canDeleteInventory() {
    return hasPermission(Permissions.inventoryDelete);
  }

  bool canManageInventoryStock() {
    return hasPermission(Permissions.inventoryStockManage);
  }

  bool canManageInventory() {
    return canCreateInventory() ||
        canUpdateInventory() ||
        canDeleteInventory() ||
        canManageInventoryStock();
  }

  bool canViewAssets() {
    return hasPermission(Permissions.assetsView);
  }

  bool canCreateAssets() {
    return hasPermission(Permissions.assetsCreate);
  }

  bool canUpdateAssets() {
    return hasPermission(Permissions.assetsUpdate);
  }

  bool canDeleteAssets() {
    return hasPermission(Permissions.assetsDelete);
  }

  bool canManageAssets() {
    return canCreateAssets() || canUpdateAssets() || canDeleteAssets();
  }

  bool canViewPm() {
    return hasPermission(Permissions.pmView);
  }

  bool canCreatePm() {
    return hasPermission(Permissions.pmCreate);
  }

  bool canUpdatePm() {
    return hasPermission(Permissions.pmUpdate);
  }

  bool canDeletePm() {
    return hasPermission(Permissions.pmDelete);
  }

  bool canManagePm() {
    return canCreatePm() || canUpdatePm() || canDeletePm();
  }

  bool canViewReports() {
    return hasPermission(Permissions.reportsView);
  }

  bool canGenerateReports() {
    return hasPermission(Permissions.reportsGenerate);
  }

  bool canDownloadReports() {
    return hasPermission(Permissions.reportsDownload);
  }

  bool canViewUsers() {
    return hasPermission(Permissions.usersView);
  }

  bool canCreateUsers() {
    return hasPermission(Permissions.usersCreate);
  }

  bool canUpdateUsers() {
    return hasPermission(Permissions.usersUpdate);
  }

  bool canDeleteUsers() {
    return hasPermission(Permissions.usersDelete);
  }

  bool canResetUserPassword() {
    return hasPermission(Permissions.usersResetPassword);
  }

  bool canViewRoles() {
    return hasPermission(Permissions.rolesView);
  }

  bool canCreateRoles() {
    return hasPermission(Permissions.rolesCreate);
  }

  bool canUpdateRoles() {
    return hasPermission(Permissions.rolesUpdate);
  }

  bool canDeleteRoles() {
    return hasPermission(Permissions.rolesDelete);
  }

  bool canViewSettings() {
    return hasPermission(Permissions.settingsView);
  }

  bool canManageSettings() {
    return hasPermission(Permissions.settingsManage);
  }

  bool canViewDashboard() {
    return hasPermission(Permissions.dashboardView);
  }

  bool canViewAllAttendance() {
    return hasPermission(Permissions.attendanceViewAll);
  }

  bool canViewTeamAttendance() {
    return hasPermission(Permissions.attendanceViewTeam);
  }

  bool canViewAttendance() {
    return hasPermission(Permissions.attendanceViewOwn) ||
        canViewTeamAttendance() ||
        canViewAllAttendance();
  }
}
