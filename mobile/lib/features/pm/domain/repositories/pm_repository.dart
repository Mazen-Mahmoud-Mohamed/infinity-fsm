import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/pm/domain/entities/pm_entities.dart';

abstract class PmRepository {
  Future<Result<PmDashboard>> getDashboard();

  Future<Result<MaintenancePlanPage>> listPlans({
    int page = 1,
    int limit = 20,
    String? search,
    PmPlanStatus? status,
    PmFrequency? frequency,
    PmPriority? priority,
  });

  Future<Result<MaintenancePlan>> getPlanById(String id);

  Future<Result<MaintenancePlan>> createPlan(MaintenancePlanUpsertInput input);

  Future<Result<MaintenancePlan>> updatePlan(
    String id,
    MaintenancePlanUpsertInput input,
  );

  Future<Result<MaintenancePlan>> deletePlan(String id);

  Future<Result<MaintenancePlan>> updateChecklist({
    required String planId,
    required List<PmChecklistItem> checklistItems,
  });

  Future<Result<int>> generateSchedules(String planId, {int count = 6});

  Future<Result<MaintenanceSchedulePage>> listSchedules({
    int page = 1,
    int limit = 20,
    String? search,
    PmScheduleStatus? status,
    String? planId,
  });

  Future<Result<MaintenanceSchedule>> getScheduleById(String id);

  Future<Result<MaintenanceSchedule>> completeSchedule(
    String id, {
    String? notes,
    List<ChecklistResult>? checklistResults,
  });

  Future<Result<MaintenanceSchedule>> cancelSchedule(String id, {String? notes});

  Future<Result<MaintenanceSchedulePage>> listHistory({
    int page = 1,
    int limit = 20,
    String? search,
    String? planId,
  });

  /// Offline sync prep — returns queued actions (empty in online MVP).
  Future<List<PendingPmAction>> getPendingActions();

  /// Offline sync prep — no-op online MVP.
  Future<Result<int>> syncPendingActions();
}
