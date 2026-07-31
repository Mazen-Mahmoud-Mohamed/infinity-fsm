import 'dart:convert';

import 'package:mobile/core/storage/preferences_service.dart';
import 'package:mobile/features/overtime/data/cache/overtime_cache_keys.dart';
import 'package:mobile/features/overtime/data/models/overtime_session_model.dart';
import 'package:mobile/features/overtime/data/models/pending_overtime_action_model.dart';

class OvertimeLocalDataSource {
  OvertimeLocalDataSource(this._preferences);

  final PreferencesService _preferences;

  Future<void> saveRunningSession(OvertimeSessionModel? session) async {
    if (session == null) {
      await _preferences.remove(OvertimeCacheKeys.runningSession);
      return;
    }
    await _preferences.setString(
      OvertimeCacheKeys.runningSession,
      jsonEncode(session.toJson()),
    );
  }

  OvertimeSessionModel? readRunningSession() {
    final raw = _preferences.getString(OvertimeCacheKeys.runningSession);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      return OvertimeSessionModel.fromJson(decoded);
    } on Object {
      return null;
    }
  }

  Future<void> saveHistory(List<OvertimeSessionModel> items) {
    return _preferences.setString(
      OvertimeCacheKeys.history,
      jsonEncode(items.map((item) => item.toJson()).toList()),
    );
  }

  List<OvertimeSessionModel> readHistory() {
    final raw = _preferences.getString(OvertimeCacheKeys.history);
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
          .map(OvertimeSessionModel.fromJson)
          .toList();
    } on Object {
      return const [];
    }
  }

  List<PendingOvertimeActionModel> readQueue() {
    final raw = _preferences.getString(OvertimeCacheKeys.pendingQueue);
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
          .map(PendingOvertimeActionModel.fromJson)
          .toList();
    } on Object {
      return const [];
    }
  }

  Future<void> saveQueue(List<PendingOvertimeActionModel> queue) {
    return _preferences.setString(
      OvertimeCacheKeys.pendingQueue,
      jsonEncode(queue.map((item) => item.toJson()).toList()),
    );
  }

  Future<void> enqueue(PendingOvertimeActionModel action) async {
    final queue = [...readQueue(), action];
    await saveQueue(queue);
  }

  Future<void> removeFromQueue(String id) async {
    final queue = readQueue().where((item) => item.id != id).toList();
    await saveQueue(queue);
  }

  Future<void> updateQueueItem(PendingOvertimeActionModel action) async {
    final queue = readQueue()
        .map((item) => item.id == action.id ? action : item)
        .toList();
    await saveQueue(queue);
  }
}
