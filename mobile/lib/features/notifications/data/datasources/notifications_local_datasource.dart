import 'dart:convert';

import 'package:mobile/core/storage/preferences_service.dart';

/// Local read-state for legacy dashboard-activity inbox fallback.
///
/// Keys are namespaced by authenticated user so User B cannot inherit User A's
/// locally marked-read ids.
class NotificationsLocalDataSource {
  NotificationsLocalDataSource(this._preferences);

  static const legacyReadIdsKey = 'notifications_read_ids_v1';
  static const readIdsPrefix = 'notifications_read_ids_v1:';

  final PreferencesService _preferences;
  String? _userId;

  String? get boundUserId => _userId;

  /// Binds subsequent reads/writes to [userId]. Migrates the legacy unscoped
  /// key into this user's namespace once, then deletes the legacy key.
  Future<void> bindUser(String? userId) async {
    final next = userId == null || userId.trim().isEmpty ? null : userId.trim();
    _userId = next;
    if (next != null) {
      await _migrateLegacyIfNeeded(next);
    }
  }

  /// Unbinds the session and drops the unscoped legacy key. Per-user keys are
  /// left in place so the same user can restore fallback read state later.
  Future<void> clearSession() async {
    _userId = null;
    await _preferences.remove(legacyReadIdsKey);
  }

  Set<String> getReadIds() {
    final key = _activeKey;
    if (key == null) return <String>{};
    final raw = _preferences.getString(key);
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
    final key = _activeKey;
    if (key == null) return;
    final next = getReadIds()..add(id);
    await _preferences.setString(key, jsonEncode(next.toList()));
  }

  Future<void> markAllAsRead(Iterable<String> ids) async {
    final key = _activeKey;
    if (key == null) return;
    final next = getReadIds()..addAll(ids);
    await _preferences.setString(key, jsonEncode(next.toList()));
  }

  String? get _activeKey {
    final id = _userId;
    if (id == null) return null;
    return '$readIdsPrefix$id';
  }

  Future<void> _migrateLegacyIfNeeded(String userId) async {
    final namespaced = '$readIdsPrefix$userId';
    final existing = _preferences.getString(namespaced);
    if (existing != null && existing.isNotEmpty) {
      await _preferences.remove(legacyReadIdsKey);
      return;
    }
    final legacy = _preferences.getString(legacyReadIdsKey);
    if (legacy == null || legacy.isEmpty) return;
    await _preferences.setString(namespaced, legacy);
    await _preferences.remove(legacyReadIdsKey);
  }
}
