import 'dart:convert';

import 'package:mobile/core/storage/preferences_service.dart';
import 'package:mobile/features/assets/data/cache/assets_cache_keys.dart';
import 'package:mobile/features/assets/data/models/asset_history_model.dart';
import 'package:mobile/features/assets/domain/entities/pending_asset_action.dart';

class AssetsLocalDataSource {
  AssetsLocalDataSource(this._preferences);

  final PreferencesService _preferences;

  List<PendingAssetAction> readPendingQueue() {
    final raw = _preferences.getString(AssetsCacheKeys.pendingQueue);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(PendingAssetActionModel.fromJson)
          .toList();
    } on Object {
      return const [];
    }
  }

  Future<void> savePendingQueue(List<PendingAssetAction> actions) {
    final models = actions
        .map(
          (action) => action is PendingAssetActionModel
              ? action
              : PendingAssetActionModel(
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
      AssetsCacheKeys.pendingQueue,
      jsonEncode(models),
    );
  }

  Future<void> clearPendingQueue() {
    return _preferences.remove(AssetsCacheKeys.pendingQueue);
  }
}
