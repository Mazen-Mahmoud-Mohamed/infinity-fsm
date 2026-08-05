import 'package:mobile/features/auth/domain/services/permission_checker.dart';

enum ReportsCenterModule {
  attendance,
  overtime,
  workOrders,
  assets,
  inventory,
  pm,
  serviceReports,
}

extension ReportsCenterModuleX on ReportsCenterModule {
  bool isAllowed(PermissionChecker permissions) {
    switch (this) {
      case ReportsCenterModule.attendance:
        return permissions.canViewAllAttendance() ||
            permissions.canViewTeamAttendance();
      case ReportsCenterModule.overtime:
        return permissions.canViewAllOvertime() ||
            permissions.canApproveOvertime();
      case ReportsCenterModule.workOrders:
        return permissions.canViewWorkOrders();
      case ReportsCenterModule.assets:
        return permissions.canViewAssets();
      case ReportsCenterModule.inventory:
        return permissions.canViewInventory();
      case ReportsCenterModule.pm:
        return permissions.canViewPm();
      case ReportsCenterModule.serviceReports:
        return permissions.canViewReports();
    }
  }

  /// Backend list APIs that accept a date range.
  bool get supportsDateRange => this == ReportsCenterModule.attendance;

  /// Backend list APIs that accept an employee/user filter.
  bool get supportsEmployeeFilter => this == ReportsCenterModule.attendance;
}

enum ReportsSort {
  titleAsc,
  titleDesc,
  dateAsc,
  dateDesc,
  statusAsc,
  statusDesc,
}
