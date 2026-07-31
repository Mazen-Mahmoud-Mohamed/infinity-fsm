import 'dart:convert';

import 'package:mobile/core/storage/preferences_service.dart';
import 'package:mobile/features/inventory/data/cache/inventory_cache_keys.dart';
import 'package:mobile/features/inventory/data/models/pending_inventory_action_model.dart';
import 'package:mobile/features/inventory/domain/entities/pending_inventory_action.dart';

class InventoryLocalDataSource {
  InventoryLocalDataSource(this._preferences);

  final PreferencesService _preferences;

  List<PendingInventoryAction> readPendingQueue() {
    final raw = _preferences.getString(InventoryCacheKeys.pendingQueue);
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
          .map(PendingInventoryActionModel.fromJson)
          .toList();
    } on Object {
      return const [];
    }
  }

  Future<void> savePendingQueue(List<PendingInventoryAction> actions) {
    final models = actions
        .map(
          (action) => action is PendingInventoryActionModel
              ? action
              : PendingInventoryActionModel(
                  id: action.id,
                  type: action.type,
                  resourceId: action.resourceId,
                  payload: action.payload,
                  createdAt: action.createdAt,
                  retryCount: action.retryCount,
                  lastError: action.lastError,
                ),
        )
        .map((model) => model.toJson())
        .toList();
    return _preferences.setString(
      InventoryCacheKeys.pendingQueue,
      jsonEncode(models),
    );
  }

  Future<void> clearPendingQueue() {
    return _preferences.remove(InventoryCacheKeys.pendingQueue);
  }
}
