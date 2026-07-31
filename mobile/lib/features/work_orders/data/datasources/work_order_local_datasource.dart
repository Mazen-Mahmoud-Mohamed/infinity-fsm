import 'dart:convert';

import 'package:mobile/core/storage/preferences_service.dart';
import 'package:mobile/features/work_orders/data/cache/work_order_cache_keys.dart';
import 'package:mobile/features/work_orders/data/models/work_order_model.dart';
import 'package:mobile/features/work_orders/domain/entities/pending_work_order_action.dart';

class WorkOrderLocalDataSource {
  WorkOrderLocalDataSource(this._preferences);

  final PreferencesService _preferences;

  List<PendingWorkOrderAction> readPendingQueue() {
    final raw = _preferences.getString(WorkOrderCacheKeys.pendingQueue);
    if (raw == null || raw.isEmpty) {
      return const [];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const [];
      }
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(PendingWorkOrderActionModel.fromJson)
          .toList();
    } on Object {
      return const [];
    }
  }

  Future<void> savePendingQueue(List<PendingWorkOrderAction> actions) {
    final models = actions
        .map(
          (action) => action is PendingWorkOrderActionModel
              ? action
              : PendingWorkOrderActionModel(
                  id: action.id,
                  type: action.type,
                  workOrderId: action.workOrderId,
                  payload: action.payload,
                  createdAt: action.createdAt,
                  retryCount: action.retryCount,
                  lastError: action.lastError,
                ),
        )
        .map((model) => model.toJson())
        .toList();
    return _preferences.setString(
      WorkOrderCacheKeys.pendingQueue,
      jsonEncode(models),
    );
  }

  Future<void> clearPendingQueue() {
    return _preferences.remove(WorkOrderCacheKeys.pendingQueue);
  }
}
