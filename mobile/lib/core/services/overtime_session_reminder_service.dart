import 'dart:async';

import 'package:mobile/core/storage/preferences_service.dart';

/// Periodically reminds the technician about a long-running overtime
/// session without spamming — at most once per [_reminderInterval].
class OvertimeSessionReminderService {
  OvertimeSessionReminderService(this._preferences);

  static const String _lastReminderAtKey = 'overtime:lastReminderAt';
  static const Duration _reminderInterval = Duration(hours: 2);
  static const Duration _checkInterval = Duration(minutes: 15);

  final PreferencesService _preferences;

  Timer? _timer;
  DateTime? _sessionStartAt;
  void Function()? _onRemind;

  /// Starts polling while a session identified by [sessionStartAt] is
  /// running. Safe to call repeatedly — restarts monitoring for the given
  /// start time without duplicating timers.
  void startMonitoring(DateTime sessionStartAt, {required void Function() onRemind}) {
    stopMonitoring();
    _sessionStartAt = sessionStartAt;
    _onRemind = onRemind;
    _timer = Timer.periodic(_checkInterval, (_) => _check());
    // Also check immediately in case the app was restarted well after the
    // interval already elapsed.
    _check();
  }

  void stopMonitoring() {
    _timer?.cancel();
    _timer = null;
    _sessionStartAt = null;
    _onRemind = null;
  }

  void _check() {
    final startAt = _sessionStartAt;
    final onRemind = _onRemind;
    if (startAt == null || onRemind == null) {
      return;
    }

    final now = DateTime.now().toUtc();
    final elapsed = now.difference(startAt.toUtc());
    if (elapsed < _reminderInterval) {
      return;
    }

    final lastReminderAt = _readLastReminderAt();
    if (lastReminderAt != null &&
        now.difference(lastReminderAt) < _reminderInterval) {
      return;
    }

    unawaited(_writeLastReminderAt(now));
    onRemind();
  }

  DateTime? _readLastReminderAt() {
    final raw = _preferences.getString(_lastReminderAtKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return DateTime.tryParse(raw);
  }

  Future<void> _writeLastReminderAt(DateTime at) {
    return _preferences.setString(_lastReminderAtKey, at.toIso8601String());
  }
}
