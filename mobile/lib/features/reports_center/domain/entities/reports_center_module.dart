import 'package:mobile/features/auth/domain/services/permission_checker.dart';

enum ReportsCenterModule {
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
  bool get supportsDateRange => false;

  /// Backend list APIs that accept an employee/user filter.
  bool get supportsEmployeeFilter => false;
}

enum ReportsSort {
  titleAsc,
  titleDesc,
  dateAsc,
  dateDesc,
  statusAsc,
  statusDesc,
}
