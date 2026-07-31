import 'dart:convert';

import 'package:mobile/core/storage/preferences_service.dart';
import 'package:mobile/features/pm/data/cache/pm_cache_keys.dart';
import 'package:mobile/features/pm/data/models/pm_models.dart';
import 'package:mobile/features/pm/domain/entities/pm_entities.dart';

class PmLocalDataSource {
  PmLocalDataSource(this._preferences);
  final PreferencesService _preferences;

  List<PendingPmAction> readPendingQueue() {
    final raw = _preferences.getString(PmCacheKeys.pendingQueue);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(PendingPmActionModel.fromJson)
          .toList();
    } on Object {
      return const [];
    }
  }

  Future<void> savePendingQueue(List<PendingPmAction> actions) {
    final models = actions
        .map(
          (action) => action is PendingPmActionModel
              ? action
              : PendingPmActionModel(
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
      PmCacheKeys.pendingQueue,
      jsonEncode(models),
    );
  }

  Future<void> clearPendingQueue() =>
      _preferences.remove(PmCacheKeys.pendingQueue);
}
