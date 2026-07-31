import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/network/dio_client.dart';
import 'package:mobile/features/pm/data/models/pm_models.dart';
import 'package:mobile/features/pm/domain/entities/pm_entities.dart';

class PmRemoteDataSource {
  PmRemoteDataSource(this._client);
  final DioClient _client;

  Future<PmDashboard> getDashboard() async {
    final response =
        await _client.get<Map<String, dynamic>>(ApiConstants.pmDashboard);
    return PmDashboardModel.fromJson(
      response.data?['data'] as Map<String, dynamic>? ?? const {},
    );
  }

  Future<MaintenancePlanPage> listPlans({
    int page = 1,
    int limit = 20,
    String? search,
    PmPlanStatus? status,
    PmFrequency? frequency,
    PmPriority? priority,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.pmPlans,
      queryParameters: {
        'page': page,
        'limit': limit,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (status != null) 'status': status.apiValue,
        if (frequency != null) 'frequency': frequency.apiValue,
        if (priority != null) 'priority': priority.apiValue,
      },
    );
    return _mapPlanPage(response.data);
  }

  Future<MaintenancePlanModel> getPlanById(String id) async {
    final response = await _client.get<Map<String, dynamic>>(
      '${ApiConstants.pmPlans}/$id',
    );
    return MaintenancePlanModel.fromJson(
      response.data?['data'] as Map<String, dynamic>,
    );
  }

  Future<MaintenancePlanModel> createPlan(MaintenancePlanUpsertInput input) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.pmPlans,
      data: _planBody(input),
    );
    return MaintenancePlanModel.fromJson(
      response.data?['data'] as Map<String, dynamic>,
    );
  }

  Future<MaintenancePlanModel> updatePlan(
    String id,
    MaintenancePlanUpsertInput input,
  ) async {
    final response = await _client.put<Map<String, dynamic>>(
      '${ApiConstants.pmPlans}/$id',
      data: _planBody(input),
    );
    return MaintenancePlanModel.fromJson(
      response.data?['data'] as Map<String, dynamic>,
    );
  }

  Future<MaintenancePlanModel> deletePlan(String id) async {
    final response = await _client.delete<Map<String, dynamic>>(
      '${ApiConstants.pmPlans}/$id',
    );
    return MaintenancePlanModel.fromJson(
      response.data?['data'] as Map<String, dynamic>,
    );
  }

  Future<MaintenancePlanModel> updateChecklist({
    required String planId,
    required List<PmChecklistItem> checklistItems,
  }) async {
    final response = await _client.put<Map<String, dynamic>>(
      '${ApiConstants.pmPlans}/$planId/checklist',
      data: {
        'checklistItems': checklistItems.map((e) => e.toJson()).toList(),
      },
    );
    return MaintenancePlanModel.fromJson(
      response.data?['data'] as Map<String, dynamic>,
    );
  }

  Future<int> generateSchedules(String planId, {int count = 6}) async {
    final response = await _client.post<Map<String, dynamic>>(
      '${ApiConstants.pmPlans}/$planId/generate-schedules',
      data: {'count': count},
    );
    final data = response.data?['data'] as Map<String, dynamic>? ?? const {};
    return (data['generated'] as num?)?.toInt() ?? 0;
  }

  Future<MaintenanceSchedulePage> listSchedules({
    int page = 1,
    int limit = 20,
    String? search,
    PmScheduleStatus? status,
    String? planId,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.pmSchedules,
      queryParameters: {
        'page': page,
        'limit': limit,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (status != null) 'status': status.apiValue,
        if (planId != null) 'planId': planId,
      },
    );
    return _mapSchedulePage(response.data);
  }

  Future<MaintenanceScheduleModel> getScheduleById(String id) async {
    final response = await _client.get<Map<String, dynamic>>(
      '${ApiConstants.pmSchedules}/$id',
    );
    return MaintenanceScheduleModel.fromJson(
      response.data?['data'] as Map<String, dynamic>,
    );
  }

  Future<MaintenanceScheduleModel> completeSchedule(
    String id, {
    String? notes,
    List<ChecklistResult>? checklistResults,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '${ApiConstants.pmSchedules}/$id/complete',
      data: {
        if (notes != null) 'notes': notes,
        if (checklistResults != null)
          'checklistResults':
              checklistResults.map((e) => e.toJson()).toList(),
      },
    );
    return MaintenanceScheduleModel.fromJson(
      response.data?['data'] as Map<String, dynamic>,
    );
  }

  Future<MaintenanceScheduleModel> cancelSchedule(
    String id, {
    String? notes,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '${ApiConstants.pmSchedules}/$id/cancel',
      data: {if (notes != null) 'notes': notes},
    );
    return MaintenanceScheduleModel.fromJson(
      response.data?['data'] as Map<String, dynamic>,
    );
  }

  Future<MaintenanceSchedulePage> listHistory({
    int page = 1,
    int limit = 20,
    String? search,
    String? planId,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.pmHistory,
      queryParameters: {
        'page': page,
        'limit': limit,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (planId != null) 'planId': planId,
      },
    );
    return _mapSchedulePage(response.data);
  }

  Map<String, dynamic> _planBody(MaintenancePlanUpsertInput input) => {
        'name': input.name,
        'code': input.code,
        if (input.description != null) 'description': input.description,
        'frequency': input.frequency.apiValue,
        'trigger': input.trigger.apiValue,
        if (input.nextDueDate != null)
          'nextDueDate': input.nextDueDate!.toIso8601String(),
        'priority': input.priority.apiValue,
        'estimatedDurationMinutes': input.estimatedDurationMinutes,
        if (input.assignedTeamId != null)
          'assignedTeamId': input.assignedTeamId,
        if (input.assignedTechnicianId != null)
          'assignedTechnicianId': input.assignedTechnicianId,
        if (input.assetId != null) 'assetId': input.assetId,
        if (input.meterThreshold != null)
          'meterThreshold': input.meterThreshold,
        if (input.currentMeterReading != null)
          'currentMeterReading': input.currentMeterReading,
        'status': input.status.apiValue,
        'checklistItems':
            input.checklistItems.map((e) => e.toJson()).toList(),
      };

  MaintenancePlanPage _mapPlanPage(Map<String, dynamic>? body) {
    final pagination = _pagination(body);
    final data = body?['data'];
    final items = data is List
        ? data
            .whereType<Map<String, dynamic>>()
            .map(MaintenancePlanModel.fromJson)
            .toList()
        : <MaintenancePlan>[];
    return MaintenancePlanPage(
      items: items,
      page: pagination.page,
      limit: pagination.limit,
      total: pagination.total,
      totalPages: pagination.totalPages,
    );
  }

  MaintenanceSchedulePage _mapSchedulePage(Map<String, dynamic>? body) {
    final pagination = _pagination(body);
    final data = body?['data'];
    final items = data is List
        ? data
            .whereType<Map<String, dynamic>>()
            .map(MaintenanceScheduleModel.fromJson)
            .toList()
        : <MaintenanceSchedule>[];
    return MaintenanceSchedulePage(
      items: items,
      page: pagination.page,
      limit: pagination.limit,
      total: pagination.total,
      totalPages: pagination.totalPages,
    );
  }

  ({int page, int limit, int total, int totalPages}) _pagination(
    Map<String, dynamic>? body,
  ) {
    final meta = body?['meta'];
    final pagination = meta is Map<String, dynamic>
        ? meta['pagination'] as Map<String, dynamic>?
        : null;
    return (
      page: (pagination?['page'] as num?)?.toInt() ?? 1,
      limit: (pagination?['limit'] as num?)?.toInt() ?? 20,
      total: (pagination?['total'] as num?)?.toInt() ?? 0,
      totalPages: (pagination?['totalPages'] as num?)?.toInt() ?? 1,
    );
  }
}
