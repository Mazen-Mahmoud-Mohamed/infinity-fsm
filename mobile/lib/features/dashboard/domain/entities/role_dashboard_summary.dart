import 'package:equatable/equatable.dart';

enum DashboardPeriod { today, week, month, year, custom }

enum DashboardViewRole { admin, supervisor, technician }

class DashboardChartPoint extends Equatable {
  const DashboardChartPoint({required this.label, required this.value});

  final String label;
  final double value;

  @override
  List<Object?> get props => [label, value];
}

class DashboardCharts extends Equatable {
  const DashboardCharts({
    this.attendance = const [],
    this.overtime = const [],
    this.workOrders = const [],
    this.preventiveMaintenance = const [],
  });

  final List<DashboardChartPoint> attendance;
  final List<DashboardChartPoint> overtime;
  final List<DashboardChartPoint> workOrders;
  final List<DashboardChartPoint> preventiveMaintenance;

  @override
  List<Object?> get props =>
      [attendance, overtime, workOrders, preventiveMaintenance];
}

class DashboardKpis extends Equatable {
  const DashboardKpis({
    this.totalEmployees = 0,
    this.activeEmployees = 0,
    this.employeesCurrentlyWorking = 0,
    this.employeesOnOvertime = 0,
    this.employeesOnTravelOvertime = 0,
  });

  final int totalEmployees;
  final int activeEmployees;
  final int employeesCurrentlyWorking;
  final int employeesOnOvertime;
  final int employeesOnTravelOvertime;

  @override
  List<Object?> get props => [
        totalEmployees,
        activeEmployees,
        employeesCurrentlyWorking,
        employeesOnOvertime,
        employeesOnTravelOvertime,
      ];
}

class DashboardAttendanceSummary extends Equatable {
  const DashboardAttendanceSummary({
    this.totalWorkingHours = 0,
    this.averageWorkingHours = 0,
    this.attendanceRate = 0,
    this.todayStatus,
    this.checkInAt,
    this.checkOutAt,
    this.todayWorkingHours = 0,
  });

  final double totalWorkingHours;
  final double averageWorkingHours;
  final double attendanceRate;
  final String? todayStatus;
  final DateTime? checkInAt;
  final DateTime? checkOutAt;
  final double todayWorkingHours;

  @override
  List<Object?> get props => [
        totalWorkingHours,
        averageWorkingHours,
        attendanceRate,
        todayStatus,
        checkInAt,
        checkOutAt,
        todayWorkingHours,
      ];
}

class DashboardTopOvertimeEmployee extends Equatable {
  const DashboardTopOvertimeEmployee({
    required this.userId,
    required this.fullName,
    required this.hours,
  });

  final String userId;
  final String fullName;
  final double hours;

  @override
  List<Object?> get props => [userId, fullName, hours];
}

class DashboardOvertimeSummary extends Equatable {
  const DashboardOvertimeSummary({
    this.totalOvertimeHours = 0,
    this.totalTravelOvertimeHours = 0,
    this.averageOtHoursPerEmployee = 0,
    this.topOvertimeEmployees = const [],
  });

  final double totalOvertimeHours;
  final double totalTravelOvertimeHours;
  final double averageOtHoursPerEmployee;
  final List<DashboardTopOvertimeEmployee> topOvertimeEmployees;

  @override
  List<Object?> get props => [
        totalOvertimeHours,
        totalTravelOvertimeHours,
        averageOtHoursPerEmployee,
        topOvertimeEmployees,
      ];
}

class DashboardWorkOrdersSummary extends Equatable {
  const DashboardWorkOrdersSummary({
    this.total = 0,
    this.pending = 0,
    this.assigned = 0,
    this.inProgress = 0,
    this.completed = 0,
    this.cancelled = 0,
  });

  final int total;
  final int pending;
  final int assigned;
  final int inProgress;
  final int completed;
  final int cancelled;

  @override
  List<Object?> get props =>
      [total, pending, assigned, inProgress, completed, cancelled];
}

class DashboardPmSummary extends Equatable {
  const DashboardPmSummary({
    this.due = 0,
    this.overdue = 0,
    this.completed = 0,
    this.assignedTasks = 0,
    this.completedTasks = 0,
  });

  final int due;
  final int overdue;
  final int completed;
  final int assignedTasks;
  final int completedTasks;

  @override
  List<Object?> get props =>
      [due, overdue, completed, assignedTasks, completedTasks];
}

class DashboardStockMovementItem extends Equatable {
  const DashboardStockMovementItem({
    required this.id,
    required this.type,
    this.quantity,
    this.quantityDelta,
    this.partName,
    this.sku,
    this.createdAt,
  });

  final String id;
  final String type;
  final num? quantity;
  final num? quantityDelta;
  final String? partName;
  final String? sku;
  final DateTime? createdAt;

  @override
  List<Object?> get props =>
      [id, type, quantity, quantityDelta, partName, sku, createdAt];
}

class DashboardInventorySummary extends Equatable {
  const DashboardInventorySummary({
    this.lowStock = 0,
    this.outOfStock = 0,
    this.recentStockMovements = const [],
  });

  final int lowStock;
  final int outOfStock;
  final List<DashboardStockMovementItem> recentStockMovements;

  @override
  List<Object?> get props => [lowStock, outOfStock, recentStockMovements];
}

class DashboardAssetsSummary extends Equatable {
  const DashboardAssetsSummary({
    this.totalAssets = 0,
    this.active = 0,
    this.underMaintenance = 0,
    this.retired = 0,
  });

  final int totalAssets;
  final int active;
  final int underMaintenance;
  final int retired;

  @override
  List<Object?> get props => [totalAssets, active, underMaintenance, retired];
}

class DashboardLiveActivityItem extends Equatable {
  const DashboardLiveActivityItem({
    required this.id,
    required this.action,
    required this.module,
    this.actorName,
    this.createdAt,
  });

  final String id;
  final String action;
  final String module;
  final String? actorName;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [id, action, module, actorName, createdAt];
}

class DashboardNotificationItem extends Equatable {
  const DashboardNotificationItem({
    required this.id,
    required this.title,
    required this.body,
    this.createdAt,
  });

  final String id;
  final String title;
  final String body;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [id, title, body, createdAt];
}

class DashboardTeamAttendance extends Equatable {
  const DashboardTeamAttendance({
    this.currentlyWorking = 0,
    this.totalWorkingHours = 0,
    this.membersPresent = 0,
  });

  final int currentlyWorking;
  final double totalWorkingHours;
  final int membersPresent;

  @override
  List<Object?> get props =>
      [currentlyWorking, totalWorkingHours, membersPresent];
}

class DashboardTeamOvertime extends Equatable {
  const DashboardTeamOvertime({
    this.totalOvertimeHours = 0,
    this.totalTravelOvertimeHours = 0,
  });

  final double totalOvertimeHours;
  final double totalTravelOvertimeHours;

  @override
  List<Object?> get props => [totalOvertimeHours, totalTravelOvertimeHours];
}

class DashboardTeamWorkOrders extends Equatable {
  const DashboardTeamWorkOrders({
    this.total = 0,
    this.pending = 0,
    this.assigned = 0,
    this.inProgress = 0,
    this.completed = 0,
  });

  final int total;
  final int pending;
  final int assigned;
  final int inProgress;
  final int completed;

  @override
  List<Object?> get props => [total, pending, assigned, inProgress, completed];
}

class DashboardTeamPm extends Equatable {
  const DashboardTeamPm({
    this.due = 0,
    this.overdue = 0,
    this.completed = 0,
  });

  final int due;
  final int overdue;
  final int completed;

  @override
  List<Object?> get props => [due, overdue, completed];
}

class DashboardTeamInventoryAlerts extends Equatable {
  const DashboardTeamInventoryAlerts({this.lowStock = 0});

  final int lowStock;

  @override
  List<Object?> get props => [lowStock];
}

class DashboardTeamPerformance extends Equatable {
  const DashboardTeamPerformance({
    this.completionRate = 0,
    this.averageWorkingHours = 0,
  });

  final double completionRate;
  final double averageWorkingHours;

  @override
  List<Object?> get props => [completionRate, averageWorkingHours];
}

class DashboardTechnicianWork extends Equatable {
  const DashboardTechnicianWork({
    this.assigned = 0,
    this.completed = 0,
    this.pending = 0,
  });

  final int assigned;
  final int completed;
  final int pending;

  @override
  List<Object?> get props => [assigned, completed, pending];
}

class DashboardLocationSummary extends Equatable {
  const DashboardLocationSummary({
    this.latitude,
    this.longitude,
    this.lastKnownAddress,
    this.lastSynchronization,
  });

  final double? latitude;
  final double? longitude;
  final String? lastKnownAddress;
  final DateTime? lastSynchronization;

  @override
  List<Object?> get props =>
      [latitude, longitude, lastKnownAddress, lastSynchronization];
}

class DashboardPerformanceSummary extends Equatable {
  const DashboardPerformanceSummary({
    this.attendanceRate = 0,
    this.monthlyWorkingHours = 0,
    this.monthlyOvertimeHours = 0,
    this.monthlyTravelOtHours = 0,
    this.completedJobs = 0,
    this.averageCompletionHours = 0,
  });

  final double attendanceRate;
  final double monthlyWorkingHours;
  final double monthlyOvertimeHours;
  final double monthlyTravelOtHours;
  final int completedJobs;
  final double averageCompletionHours;

  @override
  List<Object?> get props => [
        attendanceRate,
        monthlyWorkingHours,
        monthlyOvertimeHours,
        monthlyTravelOtHours,
        completedJobs,
        averageCompletionHours,
      ];
}

class RoleDashboardSummary extends Equatable {
  const RoleDashboardSummary({
    required this.viewRole,
    required this.period,
    required this.from,
    required this.to,
    this.teamSize,
    this.kpis,
    this.attendance,
    this.overtime,
    this.workOrders,
    this.preventiveMaintenance,
    this.inventory,
    this.assets,
    this.liveActivity = const [],
    this.notifications = const [],
    this.teamAttendance,
    this.teamOvertime,
    this.teamWorkOrders,
    this.teamPm,
    this.teamInventoryAlerts,
    this.teamActivity = const [],
    this.teamPerformance,
    this.work,
    this.location,
    this.performance,
    this.charts = const DashboardCharts(),
  });

  final DashboardViewRole viewRole;
  final DashboardPeriod period;
  final DateTime from;
  final DateTime to;
  final int? teamSize;
  final DashboardKpis? kpis;
  final DashboardAttendanceSummary? attendance;
  final DashboardOvertimeSummary? overtime;
  final DashboardWorkOrdersSummary? workOrders;
  final DashboardPmSummary? preventiveMaintenance;
  final DashboardInventorySummary? inventory;
  final DashboardAssetsSummary? assets;
  final List<DashboardLiveActivityItem> liveActivity;
  final List<DashboardNotificationItem> notifications;
  final DashboardTeamAttendance? teamAttendance;
  final DashboardTeamOvertime? teamOvertime;
  final DashboardTeamWorkOrders? teamWorkOrders;
  final DashboardTeamPm? teamPm;
  final DashboardTeamInventoryAlerts? teamInventoryAlerts;
  final List<DashboardLiveActivityItem> teamActivity;
  final DashboardTeamPerformance? teamPerformance;
  final DashboardTechnicianWork? work;
  final DashboardLocationSummary? location;
  final DashboardPerformanceSummary? performance;
  final DashboardCharts charts;

  @override
  List<Object?> get props => [
        viewRole,
        period,
        from,
        to,
        teamSize,
        kpis,
        attendance,
        overtime,
        workOrders,
        preventiveMaintenance,
        inventory,
        assets,
        liveActivity,
        notifications,
        teamAttendance,
        teamOvertime,
        teamWorkOrders,
        teamPm,
        teamInventoryAlerts,
        teamActivity,
        teamPerformance,
        work,
        location,
        performance,
        charts,
      ];
}
