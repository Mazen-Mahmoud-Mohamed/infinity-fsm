import 'dart:convert';

import 'package:mobile/core/storage/preferences_service.dart';

/// Local read-state for in-app notifications (presentation until a notifications API exists).
class NotificationsLocalDataSource {
  NotificationsLocalDataSource(this._preferences);

  static const _readIdsKey = 'notifications_read_ids_v1';

  final PreferencesService _preferences;

  Set<String> getReadIds() {
    final raw = _preferences.getString(_readIdsKey);
    if (raw == null || raw.isEmpty) return <String>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <String>{};
      return decoded.map((e) => e.toString()).toSet();
    } on Object {
      return <String>{};
    }
  }

  Future<void> markAsRead(String id) async {
    final next = getReadIds()..add(id);
    await _preferences.setString(_readIdsKey, jsonEncode(next.toList()));
  }

  Future<void> markAllAsRead(Iterable<String> ids) async {
    final next = getReadIds()..addAll(ids);
    await _preferences.setString(_readIdsKey, jsonEncode(next.toList()));
  }
}
