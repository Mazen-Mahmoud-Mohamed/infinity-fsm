import 'dart:convert';

import 'package:mobile/core/storage/preferences_service.dart';
import 'package:mobile/features/roles/data/cache/roles_cache_keys.dart';
import 'package:mobile/features/roles/data/models/role_models.dart';
import 'package:mobile/features/roles/domain/entities/role_entities.dart';

/// Offline queue interface only — no offline execution.
class RolesLocalDataSource {
  RolesLocalDataSource(this._preferences);
  final PreferencesService _preferences;

  List<PendingRolesAction> readPendingQueue() {
    final raw = _preferences.getString(RolesCacheKeys.pendingQueue);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(PendingRolesActionModel.fromJson)
          .toList();
    } on Object {
      return const [];
    }
  }

  Future<void> savePendingQueue(List<PendingRolesAction> actions) {
    final models = actions
        .map(
          (action) => action is PendingRolesActionModel
              ? action
              : PendingRolesActionModel(
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
      RolesCacheKeys.pendingQueue,
      jsonEncode(models),
    );
  }

  Future<void> clearPendingQueue() =>
      _preferences.remove(RolesCacheKeys.pendingQueue);
}
