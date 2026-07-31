import 'package:mobile/features/pm/domain/entities/pm_entities.dart';

class MaintenancePlanModel extends MaintenancePlan {
  const MaintenancePlanModel({
    required super.id,
    required super.name,
    required super.code,
    required super.frequency,
    required super.trigger,
    required super.priority,
    required super.status,
    super.companyId,
    super.description,
    super.nextDueDate,
    super.estimatedDurationMinutes,
    super.assignedTeam,
    super.assignedTechnician,
    super.asset,
    super.meterThreshold,
    super.currentMeterReading,
    super.checklistItems,
    super.createdAt,
    super.updatedAt,
  });

  factory MaintenancePlanModel.fromJson(Map<String, dynamic> json) {
    final checklist = json['checklistItems'];
    final team = json['assignedTeam'];
    final tech = json['assignedTechnician'];
    final asset = json['asset'];

    return MaintenancePlanModel(
      id: json['id']?.toString() ?? '',
      companyId: json['companyId']?.toString(),
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      description: json['description']?.toString(),
      frequency: PmFrequency.fromApi(json['frequency']?.toString()),
      trigger: PmTrigger.fromApi(json['trigger']?.toString()),
      nextDueDate: DateTime.tryParse(json['nextDueDate']?.toString() ?? ''),
      priority: PmPriority.fromApi(json['priority']?.toString()),
      estimatedDurationMinutes:
          (json['estimatedDurationMinutes'] as num?)?.toInt() ?? 60,
      assignedTeam: team is Map<String, dynamic>
          ? PmNamedRef(
              id: team['id']?.toString() ?? '',
              name: team['name']?.toString(),
            )
          : null,
      assignedTechnician: tech is Map<String, dynamic>
          ? PmNamedRef(
              id: tech['id']?.toString() ?? '',
              name: tech['name']?.toString(),
            )
          : null,
      asset: asset is Map<String, dynamic>
          ? PmAssetRef(
              id: asset['id']?.toString() ?? '',
              name: asset['name']?.toString(),
              assetNumber: asset['assetNumber']?.toString(),
            )
          : null,
      meterThreshold: (json['meterThreshold'] as num?)?.toDouble(),
      currentMeterReading: (json['currentMeterReading'] as num?)?.toDouble(),
      status: PmPlanStatus.fromApi(json['status']?.toString()),
      checklistItems: checklist is List
          ? checklist
              .whereType<Map<String, dynamic>>()
              .map(
                (item) => PmChecklistItem(
                  id: item['id']?.toString(),
                  title: item['title']?.toString() ?? '',
                  description: item['description']?.toString(),
                  requiresPassFail: item['requiresPassFail'] != false,
                  requiresNotes: item['requiresNotes'] == true,
                  photoRequired: item['photoRequired'] == true,
                  sortOrder: (item['sortOrder'] as num?)?.toInt() ?? 0,
                ),
              )
              .toList()
          : const [],
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
    );
  }
}

class MaintenanceScheduleModel extends MaintenanceSchedule {
  const MaintenanceScheduleModel({
    required super.id,
    required super.plan,
    required super.status,
    super.companyId,
    super.scheduledDate,
    super.completedDate,
    super.cancelledDate,
    super.notes,
    super.checklistResults,
    super.workOrderId,
    super.completedBy,
    super.createdAt,
    super.updatedAt,
  });

  factory MaintenanceScheduleModel.fromJson(Map<String, dynamic> json) {
    final plan = json['plan'];
    final results = json['checklistResults'];
    final completedBy = json['completedBy'];

    return MaintenanceScheduleModel(
      id: json['id']?.toString() ?? '',
      companyId: json['companyId']?.toString(),
      plan: plan is Map<String, dynamic>
          ? PmPlanRef(
              id: plan['id']?.toString() ?? '',
              name: plan['name']?.toString(),
              code: plan['code']?.toString(),
              priority: plan['priority']?.toString(),
              assetId: plan['assetId']?.toString(),
            )
          : PmPlanRef(id: json['planId']?.toString() ?? ''),
      scheduledDate: DateTime.tryParse(json['scheduledDate']?.toString() ?? ''),
      status: PmScheduleStatus.fromApi(json['status']?.toString()),
      completedDate: DateTime.tryParse(json['completedDate']?.toString() ?? ''),
      cancelledDate: DateTime.tryParse(json['cancelledDate']?.toString() ?? ''),
      notes: json['notes']?.toString(),
      checklistResults: results is List
          ? results
              .whereType<Map<String, dynamic>>()
              .map(
                (item) => ChecklistResult(
                  checklistItemId: item['checklistItemId']?.toString() ?? '',
                  title: item['title']?.toString(),
                  result: item['result']?.toString(),
                  notes: item['notes']?.toString(),
                  photoUrl: item['photoUrl']?.toString(),
                ),
              )
              .toList()
          : const [],
      workOrderId: json['workOrderId']?.toString(),
      completedBy: completedBy is Map<String, dynamic>
          ? PmNamedRef(
              id: completedBy['id']?.toString() ?? '',
              name: completedBy['name']?.toString(),
            )
          : null,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
    );
  }
}

class PmDashboardModel extends PmDashboard {
  const PmDashboardModel({
    required super.upcoming,
    required super.overdue,
    required super.completed,
    required super.cancelled,
    super.activePlans,
    super.recentSchedules,
  });

  factory PmDashboardModel.fromJson(Map<String, dynamic> json) {
    final recent = json['recentSchedules'];
    return PmDashboardModel(
      upcoming: (json['upcoming'] as num?)?.toInt() ?? 0,
      overdue: (json['overdue'] as num?)?.toInt() ?? 0,
      completed: (json['completed'] as num?)?.toInt() ?? 0,
      cancelled: (json['cancelled'] as num?)?.toInt() ?? 0,
      activePlans: (json['activePlans'] as num?)?.toInt() ?? 0,
      recentSchedules: recent is List
          ? recent
              .whereType<Map<String, dynamic>>()
              .map(MaintenanceScheduleModel.fromJson)
              .toList()
          : const [],
    );
  }
}

class PendingPmActionModel extends PendingPmAction {
  const PendingPmActionModel({
    required super.id,
    required super.type,
    required super.createdAt,
    super.resourceId,
    super.payload,
    super.retryCount,
    super.lastError,
  });

  factory PendingPmActionModel.fromJson(Map<String, dynamic> json) {
    return PendingPmActionModel(
      id: json['id']?.toString() ?? '',
      type: PendingPmActionType.values.firstWhere(
        (v) => v.name == json['type'],
        orElse: () => PendingPmActionType.createPlan,
      ),
      resourceId: json['resourceId']?.toString(),
      payload: json['payload'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['payload'] as Map)
          : const {},
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      retryCount: (json['retryCount'] as num?)?.toInt() ?? 0,
      lastError: json['lastError']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'resourceId': resourceId,
        'payload': payload,
        'createdAt': createdAt.toIso8601String(),
        'retryCount': retryCount,
        'lastError': lastError,
      };
}
