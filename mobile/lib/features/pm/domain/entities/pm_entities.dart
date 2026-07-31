import 'package:equatable/equatable.dart';

enum PmFrequency {
  daily,
  weekly,
  monthly,
  quarterly,
  semiAnnual,
  annual;

  String get apiValue => switch (this) {
        PmFrequency.daily => 'DAILY',
        PmFrequency.weekly => 'WEEKLY',
        PmFrequency.monthly => 'MONTHLY',
        PmFrequency.quarterly => 'QUARTERLY',
        PmFrequency.semiAnnual => 'SEMI_ANNUAL',
        PmFrequency.annual => 'ANNUAL',
      };

  static PmFrequency fromApi(String? value) {
    switch (value?.toUpperCase().replaceAll(' ', '_').replaceAll('-', '_')) {
      case 'DAILY':
        return PmFrequency.daily;
      case 'WEEKLY':
        return PmFrequency.weekly;
      case 'QUARTERLY':
        return PmFrequency.quarterly;
      case 'SEMI_ANNUAL':
      case 'SEMIANNUAL':
        return PmFrequency.semiAnnual;
      case 'ANNUAL':
        return PmFrequency.annual;
      case 'MONTHLY':
      default:
        return PmFrequency.monthly;
    }
  }
}

enum PmTrigger {
  timeBased,
  meterBased;

  String get apiValue =>
      this == PmTrigger.timeBased ? 'TIME_BASED' : 'METER_BASED';

  static PmTrigger fromApi(String? value) {
    final normalized = value?.toUpperCase().replaceAll(' ', '_');
    if (normalized == 'METER_BASED' || normalized == 'METERBASED') {
      return PmTrigger.meterBased;
    }
    return PmTrigger.timeBased;
  }
}

enum PmPriority {
  low,
  medium,
  high,
  critical;

  String get apiValue => switch (this) {
        PmPriority.low => 'LOW',
        PmPriority.medium => 'MEDIUM',
        PmPriority.high => 'HIGH',
        PmPriority.critical => 'CRITICAL',
      };

  static PmPriority fromApi(String? value) {
    switch (value?.toUpperCase()) {
      case 'LOW':
        return PmPriority.low;
      case 'HIGH':
        return PmPriority.high;
      case 'CRITICAL':
        return PmPriority.critical;
      case 'MEDIUM':
      default:
        return PmPriority.medium;
    }
  }
}

enum PmPlanStatus {
  active,
  inactive;

  String get apiValue => this == PmPlanStatus.active ? 'ACTIVE' : 'INACTIVE';

  static PmPlanStatus fromApi(String? value) {
    if (value?.toUpperCase() == 'INACTIVE') return PmPlanStatus.inactive;
    return PmPlanStatus.active;
  }
}

enum PmScheduleStatus {
  scheduled,
  completed,
  cancelled,
  overdue;

  String get apiValue => switch (this) {
        PmScheduleStatus.scheduled => 'SCHEDULED',
        PmScheduleStatus.completed => 'COMPLETED',
        PmScheduleStatus.cancelled => 'CANCELLED',
        PmScheduleStatus.overdue => 'OVERDUE',
      };

  static PmScheduleStatus fromApi(String? value) {
    switch (value?.toUpperCase()) {
      case 'COMPLETED':
        return PmScheduleStatus.completed;
      case 'CANCELLED':
        return PmScheduleStatus.cancelled;
      case 'OVERDUE':
        return PmScheduleStatus.overdue;
      case 'SCHEDULED':
      default:
        return PmScheduleStatus.scheduled;
    }
  }
}

class PmNamedRef extends Equatable {
  const PmNamedRef({required this.id, this.name});
  final String id;
  final String? name;
  @override
  List<Object?> get props => [id, name];
}

class PmAssetRef extends Equatable {
  const PmAssetRef({required this.id, this.name, this.assetNumber});
  final String id;
  final String? name;
  final String? assetNumber;
  @override
  List<Object?> get props => [id, name, assetNumber];
}

class PmChecklistItem extends Equatable {
  const PmChecklistItem({
    required this.title,
    this.id,
    this.description,
    this.requiresPassFail = true,
    this.requiresNotes = false,
    this.photoRequired = false,
    this.sortOrder = 0,
  });

  final String? id;
  final String title;
  final String? description;
  final bool requiresPassFail;
  final bool requiresNotes;
  final bool photoRequired;
  final int sortOrder;

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'title': title,
        if (description != null) 'description': description,
        'requiresPassFail': requiresPassFail,
        'requiresNotes': requiresNotes,
        'photoRequired': photoRequired,
        'sortOrder': sortOrder,
      };

  PmChecklistItem copyWith({
    String? id,
    String? title,
    String? description,
    bool? requiresPassFail,
    bool? requiresNotes,
    bool? photoRequired,
    int? sortOrder,
  }) {
    return PmChecklistItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      requiresPassFail: requiresPassFail ?? this.requiresPassFail,
      requiresNotes: requiresNotes ?? this.requiresNotes,
      photoRequired: photoRequired ?? this.photoRequired,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        requiresPassFail,
        requiresNotes,
        photoRequired,
        sortOrder,
      ];
}

class MaintenancePlan extends Equatable {
  const MaintenancePlan({
    required this.id,
    required this.name,
    required this.code,
    required this.frequency,
    required this.trigger,
    required this.priority,
    required this.status,
    this.companyId,
    this.description,
    this.nextDueDate,
    this.estimatedDurationMinutes = 60,
    this.assignedTeam,
    this.assignedTechnician,
    this.asset,
    this.meterThreshold,
    this.currentMeterReading,
    this.checklistItems = const [],
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String? companyId;
  final String name;
  final String code;
  final String? description;
  final PmFrequency frequency;
  final PmTrigger trigger;
  final DateTime? nextDueDate;
  final PmPriority priority;
  final int estimatedDurationMinutes;
  final PmNamedRef? assignedTeam;
  final PmNamedRef? assignedTechnician;
  final PmAssetRef? asset;
  final double? meterThreshold;
  final double? currentMeterReading;
  final PmPlanStatus status;
  final List<PmChecklistItem> checklistItems;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  @override
  List<Object?> get props => [
        id,
        companyId,
        name,
        code,
        description,
        frequency,
        trigger,
        nextDueDate,
        priority,
        estimatedDurationMinutes,
        assignedTeam,
        assignedTechnician,
        asset,
        meterThreshold,
        currentMeterReading,
        status,
        checklistItems,
        createdAt,
        updatedAt,
      ];
}

class MaintenancePlanPage extends Equatable {
  const MaintenancePlanPage({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  final List<MaintenancePlan> items;
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  bool get hasMore => page < totalPages;

  @override
  List<Object?> get props => [items, page, limit, total, totalPages];
}

class MaintenancePlanUpsertInput {
  const MaintenancePlanUpsertInput({
    required this.name,
    required this.code,
    this.description,
    this.frequency = PmFrequency.monthly,
    this.trigger = PmTrigger.timeBased,
    this.nextDueDate,
    this.priority = PmPriority.medium,
    this.estimatedDurationMinutes = 60,
    this.assignedTeamId,
    this.assignedTechnicianId,
    this.assetId,
    this.meterThreshold,
    this.currentMeterReading,
    this.status = PmPlanStatus.active,
    this.checklistItems = const [],
  });

  final String name;
  final String code;
  final String? description;
  final PmFrequency frequency;
  final PmTrigger trigger;
  final DateTime? nextDueDate;
  final PmPriority priority;
  final int estimatedDurationMinutes;
  final String? assignedTeamId;
  final String? assignedTechnicianId;
  final String? assetId;
  final double? meterThreshold;
  final double? currentMeterReading;
  final PmPlanStatus status;
  final List<PmChecklistItem> checklistItems;
}

class PmPlanRef extends Equatable {
  const PmPlanRef({
    required this.id,
    this.name,
    this.code,
    this.priority,
    this.assetId,
  });

  final String id;
  final String? name;
  final String? code;
  final String? priority;
  final String? assetId;

  @override
  List<Object?> get props => [id, name, code, priority, assetId];
}

class ChecklistResult extends Equatable {
  const ChecklistResult({
    required this.checklistItemId,
    this.title,
    this.result,
    this.notes,
    this.photoUrl,
  });

  final String checklistItemId;
  final String? title;
  final String? result;
  final String? notes;
  final String? photoUrl;

  Map<String, dynamic> toJson() => {
        'checklistItemId': checklistItemId,
        if (title != null) 'title': title,
        if (result != null) 'result': result,
        if (notes != null) 'notes': notes,
        if (photoUrl != null) 'photoUrl': photoUrl,
      };

  @override
  List<Object?> get props => [checklistItemId, title, result, notes, photoUrl];
}

class MaintenanceSchedule extends Equatable {
  const MaintenanceSchedule({
    required this.id,
    required this.plan,
    required this.status,
    this.companyId,
    this.scheduledDate,
    this.completedDate,
    this.cancelledDate,
    this.notes,
    this.checklistResults = const [],
    this.workOrderId,
    this.completedBy,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String? companyId;
  final PmPlanRef plan;
  final DateTime? scheduledDate;
  final PmScheduleStatus status;
  final DateTime? completedDate;
  final DateTime? cancelledDate;
  final String? notes;
  final List<ChecklistResult> checklistResults;
  final String? workOrderId;
  final PmNamedRef? completedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  @override
  List<Object?> get props => [
        id,
        companyId,
        plan,
        scheduledDate,
        status,
        completedDate,
        cancelledDate,
        notes,
        checklistResults,
        workOrderId,
        completedBy,
        createdAt,
        updatedAt,
      ];
}

class MaintenanceSchedulePage extends Equatable {
  const MaintenanceSchedulePage({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  final List<MaintenanceSchedule> items;
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  bool get hasMore => page < totalPages;

  @override
  List<Object?> get props => [items, page, limit, total, totalPages];
}

class PmDashboard extends Equatable {
  const PmDashboard({
    required this.upcoming,
    required this.overdue,
    required this.completed,
    required this.cancelled,
    this.activePlans = 0,
    this.recentSchedules = const [],
  });

  final int upcoming;
  final int overdue;
  final int completed;
  final int cancelled;
  final int activePlans;
  final List<MaintenanceSchedule> recentSchedules;

  @override
  List<Object?> get props => [
        upcoming,
        overdue,
        completed,
        cancelled,
        activePlans,
        recentSchedules,
      ];
}

enum PendingPmActionType {
  createPlan,
  updatePlan,
  deletePlan,
  updateChecklist,
  completeSchedule,
  cancelSchedule,
}

class PendingPmAction extends Equatable {
  const PendingPmAction({
    required this.id,
    required this.type,
    required this.createdAt,
    this.resourceId,
    this.payload = const {},
    this.retryCount = 0,
    this.lastError,
  });

  final String id;
  final PendingPmActionType type;
  final String? resourceId;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final int retryCount;
  final String? lastError;

  @override
  List<Object?> get props =>
      [id, type, resourceId, payload, createdAt, retryCount, lastError];
}
