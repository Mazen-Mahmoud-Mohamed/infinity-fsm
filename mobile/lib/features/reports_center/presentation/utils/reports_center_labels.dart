import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/features/assets/domain/entities/asset.dart';
import 'package:mobile/features/attendance/domain/entities/attendance_status.dart';
import 'package:mobile/features/inventory/domain/entities/spare_part.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_status.dart';
import 'package:mobile/features/pm/domain/entities/pm_entities.dart';
import 'package:mobile/features/reports_center/domain/entities/reports_center_module.dart';
import 'package:mobile/features/service_reports/domain/entities/service_report_entities.dart';
import 'package:mobile/features/work_orders/domain/entities/work_order_status.dart';

String reportsModuleLabel(AppLocalizations l10n, ReportsCenterModule module) {
  switch (module) {
    case ReportsCenterModule.attendance:
      return l10n.attendance;
    case ReportsCenterModule.overtime:
      return l10n.overtime;
    case ReportsCenterModule.workOrders:
      return l10n.workOrders;
    case ReportsCenterModule.assets:
      return l10n.assets;
    case ReportsCenterModule.inventory:
      return l10n.inventory;
    case ReportsCenterModule.pm:
      return l10n.pmTitle;
    case ReportsCenterModule.serviceReports:
      return l10n.reportsTitle;
  }
}

String reportsModuleEmptyLabel(
  AppLocalizations l10n,
  ReportsCenterModule module,
) {
  switch (module) {
    case ReportsCenterModule.attendance:
      return l10n.reportsCenterEmptyAttendance;
    case ReportsCenterModule.overtime:
      return l10n.reportsCenterEmptyOvertime;
    case ReportsCenterModule.workOrders:
      return l10n.reportsCenterEmptyWorkOrders;
    case ReportsCenterModule.assets:
      return l10n.reportsCenterEmptyAssets;
    case ReportsCenterModule.inventory:
      return l10n.reportsCenterEmptyInventory;
    case ReportsCenterModule.pm:
      return l10n.reportsCenterEmptyPm;
    case ReportsCenterModule.serviceReports:
      return l10n.reportsCenterEmptyServiceReports;
  }
}

List<({String key, String label})> reportsStatusOptions(
  AppLocalizations l10n,
  ReportsCenterModule module,
) {
  switch (module) {
    case ReportsCenterModule.attendance:
      return [
        for (final s in AttendanceStatus.values)
          (key: s.name, label: _attendanceLabel(l10n, s)),
      ];
    case ReportsCenterModule.overtime:
      return [
        for (final s in OvertimeStatus.values)
          (key: s.name, label: _overtimeLabel(l10n, s)),
      ];
    case ReportsCenterModule.workOrders:
      return [
        for (final s in WorkOrderStatus.values)
          (key: s.name, label: _workOrderLabel(l10n, s)),
      ];
    case ReportsCenterModule.assets:
      return [
        for (final s in AssetStatus.values)
          (key: s.name, label: _assetLabel(l10n, s)),
      ];
    case ReportsCenterModule.inventory:
      return [
        for (final s in StockStatus.values)
          (key: s.name, label: _stockLabel(l10n, s)),
      ];
    case ReportsCenterModule.pm:
      return [
        for (final s in PmPlanStatus.values)
          (key: s.name, label: _pmLabel(l10n, s)),
      ];
    case ReportsCenterModule.serviceReports:
      return [
        for (final s in ServiceReportStatus.values)
          (key: s.name, label: _serviceLabel(l10n, s)),
      ];
  }
}

String reportsSortLabel(AppLocalizations l10n, ReportsSort sort) {
  switch (sort) {
    case ReportsSort.titleAsc:
      return l10n.reportsCenterSortTitleAsc;
    case ReportsSort.titleDesc:
      return l10n.reportsCenterSortTitleDesc;
    case ReportsSort.dateAsc:
      return l10n.reportsCenterSortDateAsc;
    case ReportsSort.dateDesc:
      return l10n.reportsCenterSortDateDesc;
    case ReportsSort.statusAsc:
      return l10n.reportsCenterSortStatusAsc;
    case ReportsSort.statusDesc:
      return l10n.reportsCenterSortStatusDesc;
  }
}

String _attendanceLabel(AppLocalizations l10n, AttendanceStatus s) {
  switch (s) {
    case AttendanceStatus.notStarted:
      return l10n.attendanceStatusNotStarted;
    case AttendanceStatus.clockedIn:
      return l10n.attendanceStatusWorking;
    case AttendanceStatus.onBreak:
      return l10n.attendanceStatusOnBreak;
    case AttendanceStatus.clockedOut:
      return l10n.attendanceStatusClockedOut;
  }
}

String _overtimeLabel(AppLocalizations l10n, OvertimeStatus s) {
  switch (s) {
    case OvertimeStatus.running:
      return l10n.overtimeStatusRunning;
    case OvertimeStatus.pendingReview:
      return l10n.overtimeStatusPendingReview;
    case OvertimeStatus.approved:
      return l10n.overtimeStatusApproved;
    case OvertimeStatus.rejected:
      return l10n.overtimeStatusRejected;
    case OvertimeStatus.cancelled:
      return l10n.overtimeStatusCancelled;
  }
}

String _workOrderLabel(AppLocalizations l10n, WorkOrderStatus s) {
  switch (s) {
    case WorkOrderStatus.pending:
      return l10n.workOrderStatusPending;
    case WorkOrderStatus.assigned:
      return l10n.workOrderStatusAssigned;
    case WorkOrderStatus.accepted:
      return l10n.workOrderStatusAccepted;
    case WorkOrderStatus.rejected:
      return l10n.workOrderStatusRejected;
    case WorkOrderStatus.inProgress:
      return l10n.workOrderStatusInProgress;
    case WorkOrderStatus.completed:
      return l10n.workOrderStatusCompleted;
    case WorkOrderStatus.cancelled:
      return l10n.workOrderStatusCancelled;
  }
}

String _assetLabel(AppLocalizations l10n, AssetStatus s) {
  switch (s) {
    case AssetStatus.active:
      return l10n.assetsStatusActive;
    case AssetStatus.maintenance:
      return l10n.assetsStatusMaintenance;
    case AssetStatus.offline:
      return l10n.assetsStatusOffline;
    case AssetStatus.retired:
      return l10n.assetsStatusRetired;
  }
}

String _stockLabel(AppLocalizations l10n, StockStatus s) {
  switch (s) {
    case StockStatus.inStock:
      return l10n.inventoryInStock;
    case StockStatus.lowStock:
      return l10n.inventoryLowStock;
    case StockStatus.outOfStock:
      return l10n.inventoryOutOfStock;
  }
}

String _pmLabel(AppLocalizations l10n, PmPlanStatus s) {
  switch (s) {
    case PmPlanStatus.active:
      return l10n.pmStatusActive;
    case PmPlanStatus.inactive:
      return l10n.pmStatusInactive;
  }
}

String _serviceLabel(AppLocalizations l10n, ServiceReportStatus s) {
  switch (s) {
    case ServiceReportStatus.draft:
      return l10n.reportsStatusDraft;
    case ServiceReportStatus.generated:
      return l10n.reportsStatusGenerated;
    case ServiceReportStatus.downloaded:
      return l10n.reportsStatusDownloaded;
  }
}
