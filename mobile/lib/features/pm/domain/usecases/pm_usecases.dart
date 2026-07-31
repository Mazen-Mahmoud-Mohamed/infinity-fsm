import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/pm/domain/entities/pm_entities.dart';
import 'package:mobile/features/pm/domain/repositories/pm_repository.dart';

class GetPmDashboardUseCase {
  GetPmDashboardUseCase(this._repository);
  final PmRepository _repository;
  Future<Result<PmDashboard>> call() => _repository.getDashboard();
}

class ListPmPlansUseCase {
  ListPmPlansUseCase(this._repository);
  final PmRepository _repository;
  Future<Result<MaintenancePlanPage>> call({
    int page = 1,
    int limit = 20,
    String? search,
    PmPlanStatus? status,
    PmFrequency? frequency,
    PmPriority? priority,
  }) =>
      _repository.listPlans(
        page: page,
        limit: limit,
        search: search,
        status: status,
        frequency: frequency,
        priority: priority,
      );
}

class GetPmPlanByIdUseCase {
  GetPmPlanByIdUseCase(this._repository);
  final PmRepository _repository;
  Future<Result<MaintenancePlan>> call(String id) => _repository.getPlanById(id);
}

class CreatePmPlanUseCase {
  CreatePmPlanUseCase(this._repository);
  final PmRepository _repository;
  Future<Result<MaintenancePlan>> call(MaintenancePlanUpsertInput input) =>
      _repository.createPlan(input);
}

class UpdatePmPlanUseCase {
  UpdatePmPlanUseCase(this._repository);
  final PmRepository _repository;
  Future<Result<MaintenancePlan>> call(
    String id,
    MaintenancePlanUpsertInput input,
  ) =>
      _repository.updatePlan(id, input);
}

class DeletePmPlanUseCase {
  DeletePmPlanUseCase(this._repository);
  final PmRepository _repository;
  Future<Result<MaintenancePlan>> call(String id) => _repository.deletePlan(id);
}

class UpdatePmChecklistUseCase {
  UpdatePmChecklistUseCase(this._repository);
  final PmRepository _repository;
  Future<Result<MaintenancePlan>> call({
    required String planId,
    required List<PmChecklistItem> checklistItems,
  }) =>
      _repository.updateChecklist(
        planId: planId,
        checklistItems: checklistItems,
      );
}

class GeneratePmSchedulesUseCase {
  GeneratePmSchedulesUseCase(this._repository);
  final PmRepository _repository;
  Future<Result<int>> call(String planId, {int count = 6}) =>
      _repository.generateSchedules(planId, count: count);
}

class ListPmSchedulesUseCase {
  ListPmSchedulesUseCase(this._repository);
  final PmRepository _repository;
  Future<Result<MaintenanceSchedulePage>> call({
    int page = 1,
    int limit = 20,
    String? search,
    PmScheduleStatus? status,
    String? planId,
  }) =>
      _repository.listSchedules(
        page: page,
        limit: limit,
        search: search,
        status: status,
        planId: planId,
      );
}

class GetPmScheduleByIdUseCase {
  GetPmScheduleByIdUseCase(this._repository);
  final PmRepository _repository;
  Future<Result<MaintenanceSchedule>> call(String id) =>
      _repository.getScheduleById(id);
}

class CompletePmScheduleUseCase {
  CompletePmScheduleUseCase(this._repository);
  final PmRepository _repository;
  Future<Result<MaintenanceSchedule>> call(
    String id, {
    String? notes,
    List<ChecklistResult>? checklistResults,
  }) =>
      _repository.completeSchedule(
        id,
        notes: notes,
        checklistResults: checklistResults,
      );
}

class CancelPmScheduleUseCase {
  CancelPmScheduleUseCase(this._repository);
  final PmRepository _repository;
  Future<Result<MaintenanceSchedule>> call(String id, {String? notes}) =>
      _repository.cancelSchedule(id, notes: notes);
}

class ListPmHistoryUseCase {
  ListPmHistoryUseCase(this._repository);
  final PmRepository _repository;
  Future<Result<MaintenanceSchedulePage>> call({
    int page = 1,
    int limit = 20,
    String? search,
    String? planId,
  }) =>
      _repository.listHistory(
        page: page,
        limit: limit,
        search: search,
        planId: planId,
      );
}

class SyncPendingPmUseCase {
  SyncPendingPmUseCase(this._repository);
  final PmRepository _repository;
  Future<Result<int>> call() => _repository.syncPendingActions();
}
