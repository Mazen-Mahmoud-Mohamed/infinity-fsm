import 'package:mobile/features/dashboard/domain/entities/role_dashboard_summary.dart';

DashboardPeriod dashboardPeriodFromString(String? value) {
  switch (value?.toLowerCase()) {
    case 'today':
      return DashboardPeriod.today;
    case 'week':
      return DashboardPeriod.week;
    case 'year':
      return DashboardPeriod.year;
    case 'custom':
      return DashboardPeriod.custom;
    case 'month':
    default:
      return DashboardPeriod.month;
  }
}

String dashboardPeriodToQuery(DashboardPeriod period) {
  switch (period) {
    case DashboardPeriod.today:
      return 'today';
    case DashboardPeriod.week:
      return 'week';
    case DashboardPeriod.month:
      return 'month';
    case DashboardPeriod.year:
      return 'year';
    case DashboardPeriod.custom:
      return 'custom';
  }
}

DashboardViewRole dashboardViewRoleFromString(String? value) {
  switch (value?.toLowerCase()) {
    case 'admin':
      return DashboardViewRole.admin;
    case 'supervisor':
      return DashboardViewRole.supervisor;
    case 'technician':
    default:
      return DashboardViewRole.technician;
  }
}

int _asInt(Object? value) => (value as num?)?.toInt() ?? 0;

double _asDouble(Object? value) => (value as num?)?.toDouble() ?? 0;

DateTime? _asDate(Object? value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

Map<String, dynamic>? _asMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

List<Map<String, dynamic>> _asMapList(Object? value) {
  if (value is! List) return const [];
  return value
      .whereType<Map<Object?, Object?>>()
      .map(Map<String, dynamic>.from)
      .toList();
}

class RoleDashboardSummaryModel extends RoleDashboardSummary {
  const RoleDashboardSummaryModel({
    required super.viewRole,
    required super.period,
    required super.from,
    required super.to,
    super.teamSize,
    super.kpis,
    super.attendance,
    super.overtime,
    super.workOrders,
    super.preventiveMaintenance,
    super.inventory,
    super.assets,
    super.liveActivity,
    super.notifications,
    super.teamAttendance,
    super.teamOvertime,
    super.teamWorkOrders,
    super.teamPm,
    super.teamInventoryAlerts,
    super.teamActivity,
    super.teamPerformance,
    super.work,
    super.location,
    super.performance,
    super.charts,
  });

  factory RoleDashboardSummaryModel.fromJson(Map<String, dynamic> json) {
    final from =
        _asDate(json['from']) ?? DateTime.now().toUtc();
    final to = _asDate(json['to']) ?? from;

    return RoleDashboardSummaryModel(
      viewRole: dashboardViewRoleFromString(json['viewRole']?.toString()),
      period: dashboardPeriodFromString(json['period']?.toString()),
      from: from,
      to: to,
      teamSize: json['teamSize'] == null ? null : _asInt(json['teamSize']),
      kpis: _mapKpis(_asMap(json['kpis'])),
      attendance: _mapAttendance(_asMap(json['attendance'])),
      overtime: _mapOvertime(_asMap(json['overtime'])),
      workOrders: _mapWorkOrders(_asMap(json['workOrders'])),
      preventiveMaintenance: _mapPm(_asMap(json['preventiveMaintenance'])),
      inventory: _mapInventory(_asMap(json['inventory'])),
      assets: _mapAssets(_asMap(json['assets'])),
      liveActivity: _mapLiveActivity(json['liveActivity']),
      notifications: _mapNotifications(json['notifications']),
      teamAttendance: _mapTeamAttendance(_asMap(json['teamAttendance'])),
      teamOvertime: _mapTeamOvertime(_asMap(json['teamOvertime'])),
      teamWorkOrders: _mapTeamWorkOrders(_asMap(json['teamWorkOrders'])),
      teamPm: _mapTeamPm(_asMap(json['teamPm'])),
      teamInventoryAlerts:
          _mapTeamInventory(_asMap(json['teamInventoryAlerts'])),
      teamActivity: _mapLiveActivity(json['teamActivity']),
      teamPerformance: _mapTeamPerformance(_asMap(json['teamPerformance'])),
      work: _mapWork(_asMap(json['work'])),
      location: _mapLocation(_asMap(json['location'])),
      performance: _mapPerformance(_asMap(json['performance'])),
      charts: _mapCharts(_asMap(json['charts'])),
    );
  }

  static DashboardKpis? _mapKpis(Map<String, dynamic>? json) {
    if (json == null) return null;
    return DashboardKpis(
      totalEmployees: _asInt(json['totalEmployees']),
      activeEmployees: _asInt(json['activeEmployees']),
      employeesCurrentlyWorking: _asInt(json['employeesCurrentlyWorking']),
      employeesOnOvertime: _asInt(json['employeesOnOvertime']),
      employeesOnTravelOvertime: _asInt(json['employeesOnTravelOvertime']),
    );
  }

  static DashboardAttendanceSummary? _mapAttendance(Map<String, dynamic>? json) {
    if (json == null) return null;
    return DashboardAttendanceSummary(
      totalWorkingHours: _asDouble(json['totalWorkingHours']),
      averageWorkingHours: _asDouble(json['averageWorkingHours']),
      attendanceRate: _asDouble(json['attendanceRate']),
      todayStatus: json['todayStatus']?.toString(),
      checkInAt: _asDate(json['checkInAt']),
      checkOutAt: _asDate(json['checkOutAt']),
      todayWorkingHours: _asDouble(json['todayWorkingHours']),
    );
  }

  static DashboardOvertimeSummary? _mapOvertime(Map<String, dynamic>? json) {
    if (json == null) return null;
    return DashboardOvertimeSummary(
      totalOvertimeHours: _asDouble(json['totalOvertimeHours']),
      totalTravelOvertimeHours: _asDouble(json['totalTravelOvertimeHours']),
      totalTrips: _asInt(json['totalTrips']),
      overnightTrips: _asInt(json['overnightTrips']),
      totalTechnicians: _asInt(json['totalTechnicians']),
      averageHoursPerTrip: _asDouble(json['averageHoursPerTrip']),
      averageOtHoursPerEmployee: _asDouble(json['averageOtHoursPerEmployee']),
      topOvertimeEmployees: _asMapList(json['topOvertimeEmployees'])
          .map(
            (row) => DashboardTopOvertimeEmployee(
              userId: row['userId']?.toString() ?? '',
              fullName: row['fullName']?.toString() ?? '—',
              hours: _asDouble(row['hours']),
              trips: _asInt(row['trips']),
              overnightTrips: _asInt(row['overnightTrips']),
              averageHoursPerTrip: _asDouble(row['averageHoursPerTrip']),
            ),
          )
          .toList(),
      hoursPerTechnician: _mapPoints(json['hoursPerTechnician']),
      tripsPerTechnician: _mapPoints(json['tripsPerTechnician']),
    );
  }

  static DashboardWorkOrdersSummary? _mapWorkOrders(
    Map<String, dynamic>? json,
  ) {
    if (json == null) return null;
    return DashboardWorkOrdersSummary(
      total: _asInt(json['total']),
      pending: _asInt(json['pending']),
      assigned: _asInt(json['assigned']),
      inProgress: _asInt(json['inProgress']),
      completed: _asInt(json['completed']),
      cancelled: _asInt(json['cancelled']),
    );
  }

  static DashboardPmSummary? _mapPm(Map<String, dynamic>? json) {
    if (json == null) return null;
    return DashboardPmSummary(
      due: _asInt(json['due']),
      overdue: _asInt(json['overdue']),
      completed: _asInt(json['completed']),
      assignedTasks: _asInt(json['assignedTasks']),
      completedTasks: _asInt(json['completedTasks']),
    );
  }

  static DashboardInventorySummary? _mapInventory(Map<String, dynamic>? json) {
    if (json == null) return null;
    return DashboardInventorySummary(
      lowStock: _asInt(json['lowStock']),
      outOfStock: _asInt(json['outOfStock']),
      recentStockMovements: _asMapList(json['recentStockMovements'])
          .map(
            (row) => DashboardStockMovementItem(
              id: row['id']?.toString() ?? '',
              type: row['type']?.toString() ?? '',
              quantity: row['quantity'] as num?,
              quantityDelta: row['quantityDelta'] as num?,
              partName: row['partName']?.toString(),
              sku: row['sku']?.toString(),
              createdAt: _asDate(row['createdAt']),
            ),
          )
          .toList(),
    );
  }

  static DashboardAssetsSummary? _mapAssets(Map<String, dynamic>? json) {
    if (json == null) return null;
    return DashboardAssetsSummary(
      totalAssets: _asInt(json['totalAssets']),
      active: _asInt(json['active']),
      underMaintenance: _asInt(json['underMaintenance']),
      retired: _asInt(json['retired']),
    );
  }

  static List<DashboardLiveActivityItem> _mapLiveActivity(Object? value) {
    return _asMapList(value)
        .map(
          (row) => DashboardLiveActivityItem(
            id: row['id']?.toString() ?? '',
            action: row['action']?.toString() ?? '',
            module: row['module']?.toString() ?? '',
            actorName: row['actorName']?.toString(),
            createdAt: _asDate(row['createdAt']),
          ),
        )
        .toList();
  }

  static List<DashboardNotificationItem> _mapNotifications(Object? value) {
    return _asMapList(value)
        .map(
          (row) => DashboardNotificationItem(
            id: row['id']?.toString() ?? '',
            title: row['title']?.toString() ?? '',
            body: row['body']?.toString() ?? '',
            createdAt: _asDate(row['createdAt']),
          ),
        )
        .toList();
  }

  static DashboardTeamAttendance? _mapTeamAttendance(
    Map<String, dynamic>? json,
  ) {
    if (json == null) return null;
    return DashboardTeamAttendance(
      currentlyWorking: _asInt(json['currentlyWorking']),
      totalWorkingHours: _asDouble(json['totalWorkingHours']),
      membersPresent: _asInt(json['membersPresent']),
    );
  }

  static DashboardTeamOvertime? _mapTeamOvertime(Map<String, dynamic>? json) {
    if (json == null) return null;
    return DashboardTeamOvertime(
      totalOvertimeHours: _asDouble(json['totalOvertimeHours']),
      totalTravelOvertimeHours: _asDouble(json['totalTravelOvertimeHours']),
    );
  }

  static DashboardTeamWorkOrders? _mapTeamWorkOrders(
    Map<String, dynamic>? json,
  ) {
    if (json == null) return null;
    return DashboardTeamWorkOrders(
      total: _asInt(json['total']),
      pending: _asInt(json['pending']),
      assigned: _asInt(json['assigned']),
      inProgress: _asInt(json['inProgress']),
      completed: _asInt(json['completed']),
    );
  }

  static DashboardTeamPm? _mapTeamPm(Map<String, dynamic>? json) {
    if (json == null) return null;
    return DashboardTeamPm(
      due: _asInt(json['due']),
      overdue: _asInt(json['overdue']),
      completed: _asInt(json['completed']),
    );
  }

  static DashboardTeamInventoryAlerts? _mapTeamInventory(
    Map<String, dynamic>? json,
  ) {
    if (json == null) return null;
    return DashboardTeamInventoryAlerts(lowStock: _asInt(json['lowStock']));
  }

  static DashboardTeamPerformance? _mapTeamPerformance(
    Map<String, dynamic>? json,
  ) {
    if (json == null) return null;
    return DashboardTeamPerformance(
      completionRate: _asDouble(json['completionRate']),
      averageWorkingHours: _asDouble(json['averageWorkingHours']),
    );
  }

  static DashboardTechnicianWork? _mapWork(Map<String, dynamic>? json) {
    if (json == null) return null;
    return DashboardTechnicianWork(
      assigned: _asInt(json['assigned']),
      completed: _asInt(json['completed']),
      pending: _asInt(json['pending']),
    );
  }

  static DashboardLocationSummary? _mapLocation(Map<String, dynamic>? json) {
    if (json == null) return null;
    return DashboardLocationSummary(
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      lastKnownAddress: json['lastKnownAddress']?.toString(),
      lastSynchronization: _asDate(json['lastSynchronization']),
    );
  }

  static DashboardPerformanceSummary? _mapPerformance(
    Map<String, dynamic>? json,
  ) {
    if (json == null) return null;
    return DashboardPerformanceSummary(
      attendanceRate: _asDouble(json['attendanceRate']),
      monthlyWorkingHours: _asDouble(json['monthlyWorkingHours']),
      monthlyOvertimeHours: _asDouble(json['monthlyOvertimeHours']),
      monthlyTravelOtHours: _asDouble(json['monthlyTravelOtHours']),
      completedJobs: _asInt(json['completedJobs']),
      averageCompletionHours: _asDouble(json['averageCompletionHours']),
    );
  }

  static DashboardCharts _mapCharts(Map<String, dynamic>? json) {
    if (json == null) return const DashboardCharts();
    return DashboardCharts(
      attendance: _mapPoints(json['attendance']),
      overtime: _mapPoints(json['overtime']),
      workOrders: _mapPoints(json['workOrders']),
      preventiveMaintenance: _mapPoints(json['preventiveMaintenance']),
    );
  }

  static List<DashboardChartPoint> _mapPoints(Object? value) {
    return _asMapList(value)
        .map(
          (row) => DashboardChartPoint(
            label: row['label']?.toString() ?? '',
            value: _asDouble(row['value']),
          ),
        )
        .toList();
  }
}
