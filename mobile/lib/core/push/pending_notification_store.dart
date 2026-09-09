import 'dart:convert';

import 'package:mobile/core/constants/storage_keys.dart';
import 'package:mobile/core/push/notification_navigation.dart';
import 'package:mobile/core/storage/preferences_service.dart';

/// Single-slot pending notification deep-link, bound to a user id.
class PendingNotificationStore {
  PendingNotificationStore(this._preferences);

  final PreferencesService _preferences;

  Future<void> persist(NotificationNavigationIntent intent) {
    return _preferences.setString(
      StorageKeys.pendingNotificationNav,
      jsonEncode(intent.toJson()),
    );
  }

  NotificationNavigationIntent? read() {
    final raw = _preferences.getString(StorageKeys.pendingNotificationNav);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return NotificationNavigationIntent.fromJson(
          Map<String, dynamic>.from(decoded),
        );
      }
    } on Object catch (_) {}
    return null;
  }

  Future<void> clear() {
    return _preferences.remove(StorageKeys.pendingNotificationNav);
  }

  /// Returns the pending intent only when it belongs to [userId].
  ///
  /// Missing, legacy (no userId), or mismatched intents are discarded.
  Future<NotificationNavigationIntent?> takeForUser(String? userId) async {
    final intent = read();
    if (intent == null) return null;
    final owner = intent.userId?.trim() ?? '';
    final current = userId?.trim() ?? '';
    if (current.isEmpty || owner.isEmpty || owner != current) {
      await clear();
      return null;
    }
    await clear();
    return intent;
  }
}
