import 'dart:convert';

import 'package:mobile/core/storage/preferences_service.dart';
import 'package:mobile/features/service_reports/data/cache/service_reports_cache_keys.dart';
import 'package:mobile/features/service_reports/data/models/service_report_models.dart';
import 'package:mobile/features/service_reports/domain/entities/service_report_entities.dart';

class ServiceReportsLocalDataSource {
  ServiceReportsLocalDataSource(this._preferences);
  final PreferencesService _preferences;

  List<PendingReportAction> readPendingQueue() {
    final raw =
        _preferences.getString(ServiceReportsCacheKeys.pendingQueue);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(PendingReportActionModel.fromJson)
          .toList();
    } on Object {
      return const [];
    }
  }

  Future<void> savePendingQueue(List<PendingReportAction> actions) {
    final models = actions
        .map(
          (action) => action is PendingReportActionModel
              ? action
              : PendingReportActionModel(
                  id: action.id,
                  type: action.type,
                  resourceId: action.resourceId,
                  payload: action.payload,
                  createdAt: action.createdAt,
                  retryCount: action.retryCount,
                  lastError: action.lastError,
                ),
        )
        .map((m) => m.toJson())
        .toList();
    return _preferences.setString(
      ServiceReportsCacheKeys.pendingQueue,
      jsonEncode(models),
    );
  }

  Future<void> clearPendingQueue() =>
      _preferences.remove(ServiceReportsCacheKeys.pendingQueue);
}
