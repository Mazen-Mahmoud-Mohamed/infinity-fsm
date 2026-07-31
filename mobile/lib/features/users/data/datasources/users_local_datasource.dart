import 'dart:convert';

import 'package:mobile/core/storage/preferences_service.dart';
import 'package:mobile/features/users/data/cache/users_cache_keys.dart';
import 'package:mobile/features/users/data/models/user_management_models.dart';
import 'package:mobile/features/users/domain/entities/user_management_entities.dart';

class UsersLocalDataSource {
  UsersLocalDataSource(this._preferences);
  final PreferencesService _preferences;

  List<PendingUsersAction> readPendingQueue() {
    final raw = _preferences.getString(UsersCacheKeys.pendingQueue);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(PendingUsersActionModel.fromJson)
          .toList();
    } on Object {
      return const [];
    }
  }

  Future<void> savePendingQueue(List<PendingUsersAction> actions) {
    final models = actions
        .map(
          (action) => action is PendingUsersActionModel
              ? action
              : PendingUsersActionModel(
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
      UsersCacheKeys.pendingQueue,
      jsonEncode(models),
    );
  }

  Future<void> clearPendingQueue() =>
      _preferences.remove(UsersCacheKeys.pendingQueue);
}
