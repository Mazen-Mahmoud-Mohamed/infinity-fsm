import 'package:mobile/core/network/network_error_mapper.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/pm/data/datasources/pm_local_datasource.dart';
import 'package:mobile/features/pm/data/datasources/pm_remote_datasource.dart';
import 'package:mobile/features/pm/domain/entities/pm_entities.dart';
import 'package:mobile/features/pm/domain/repositories/pm_repository.dart';

class PmRepositoryImpl implements PmRepository {
  PmRepositoryImpl({
    required PmRemoteDataSource remote,
    required PmLocalDataSource local,
  })  : _remote = remote,
        _local = local;

  final PmRemoteDataSource _remote;
  final PmLocalDataSource _local;

  @override
  Future<Result<PmDashboard>> getDashboard() async {
    try {
      return Success(await _remote.getDashboard());
    } on Object catch (e) {
      return NetworkErrorMapper.map(e);
    }
  }

  @override
  Future<Result<MaintenancePlanPage>> listPlans({
    int page = 1,
    int limit = 20,
    String? search,
    PmPlanStatus? status,
    PmFrequency? frequency,
    PmPriority? priority,
  }) async {
    try {
      return Success(
        await _remote.listPlans(
          page: page,
          limit: limit,
          search: search,
          status: status,
          frequency: frequency,
          priority: priority,
        ),
      );
    } on Object catch (e) {
      return NetworkErrorMapper.map(e);
    }
  }

  @override
  Future<Result<MaintenancePlan>> getPlanById(String id) async {
    try {
      return Success(await _remote.getPlanById(id));
    } on Object catch (e) {
      return NetworkErrorMapper.map(e);
    }
  }

  @override
  Future<Result<MaintenancePlan>> createPlan(
    MaintenancePlanUpsertInput input,
  ) async {
    try {
      return Success(await _remote.createPlan(input));
    } on Object catch (e) {
      return NetworkErrorMapper.map(e);
    }
  }

  @override
  Future<Result<MaintenancePlan>> updatePlan(
    String id,
    MaintenancePlanUpsertInput input,
  ) async {
    try {
      return Success(await _remote.updatePlan(id, input));
    } on Object catch (e) {
      return NetworkErrorMapper.map(e);
    }
  }

  @override
  Future<Result<MaintenancePlan>> deletePlan(String id) async {
    try {
      return Success(await _remote.deletePlan(id));
    } on Object catch (e) {
      return NetworkErrorMapper.map(e);
    }
  }

  @override
  Future<Result<MaintenancePlan>> updateChecklist({
    required String planId,
    required List<PmChecklistItem> checklistItems,
  }) async {
    try {
      return Success(
        await _remote.updateChecklist(
          planId: planId,
          checklistItems: checklistItems,
        ),
      );
    } on Object catch (e) {
      return NetworkErrorMapper.map(e);
    }
  }

  @override
  Future<Result<int>> generateSchedules(String planId, {int count = 6}) async {
    try {
      return Success(await _remote.generateSchedules(planId, count: count));
    } on Object catch (e) {
      return NetworkErrorMapper.map(e);
    }
  }

  @override
  Future<Result<MaintenanceSchedulePage>> listSchedules({
    int page = 1,
    int limit = 20,
    String? search,
    PmScheduleStatus? status,
    String? planId,
  }) async {
    try {
      return Success(
        await _remote.listSchedules(
          page: page,
          limit: limit,
          search: search,
          status: status,
          planId: planId,
        ),
      );
    } on Object catch (e) {
      return NetworkErrorMapper.map(e);
    }
  }

  @override
  Future<Result<MaintenanceSchedule>> getScheduleById(String id) async {
    try {
      return Success(await _remote.getScheduleById(id));
    } on Object catch (e) {
      return NetworkErrorMapper.map(e);
    }
  }

  @override
  Future<Result<MaintenanceSchedule>> completeSchedule(
    String id, {
    String? notes,
    List<ChecklistResult>? checklistResults,
  }) async {
    try {
      return Success(
        await _remote.completeSchedule(
          id,
          notes: notes,
          checklistResults: checklistResults,
        ),
      );
    } on Object catch (e) {
      return NetworkErrorMapper.map(e);
    }
  }

  @override
  Future<Result<MaintenanceSchedule>> cancelSchedule(
    String id, {
    String? notes,
  }) async {
    try {
      return Success(await _remote.cancelSchedule(id, notes: notes));
    } on Object catch (e) {
      return NetworkErrorMapper.map(e);
    }
  }

  @override
  Future<Result<MaintenanceSchedulePage>> listHistory({
    int page = 1,
    int limit = 20,
    String? search,
    String? planId,
  }) async {
    try {
      return Success(
        await _remote.listHistory(
          page: page,
          limit: limit,
          search: search,
          planId: planId,
        ),
      );
    } on Object catch (e) {
      return NetworkErrorMapper.map(e);
    }
  }

  @override
  Future<List<PendingPmAction>> getPendingActions() async =>
      _local.readPendingQueue();

  @override
  Future<Result<int>> syncPendingActions() async => const Success(0);
}
