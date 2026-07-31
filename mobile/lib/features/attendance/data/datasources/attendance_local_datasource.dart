import 'dart:convert';

import 'package:mobile/core/storage/preferences_service.dart';
import 'package:mobile/features/attendance/data/cache/attendance_cache_keys.dart';
import 'package:mobile/features/attendance/data/models/attendance_status_snapshot_model.dart';
import 'package:mobile/features/attendance/data/models/attendance_summary_model.dart';
import 'package:mobile/features/attendance/data/models/attendance_today_model.dart';
import 'package:mobile/features/attendance/data/models/pending_attendance_action_model.dart';

class AttendanceLocalDataSource {
  AttendanceLocalDataSource(this._preferences);

  final PreferencesService _preferences;

  Future<void> saveStatus(AttendanceStatusSnapshotModel status) {
    return _preferences.setString(
      AttendanceCacheKeys.status,
      jsonEncode(status.toJson()),
    );
  }

  AttendanceStatusSnapshotModel? readStatus() {
    final raw = _preferences.getString(AttendanceCacheKeys.status);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      return null;
    }
    return AttendanceStatusSnapshotModel.fromJson(decoded);
  }

  Future<void> saveToday(AttendanceTodayModel today) {
    return _preferences.setString(
      AttendanceCacheKeys.today,
      jsonEncode(today.toJson()),
    );
  }

  AttendanceTodayModel? readToday() {
    final raw = _preferences.getString(AttendanceCacheKeys.today);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      return null;
    }
    return AttendanceTodayModel.fromJson(decoded);
  }

  Future<void> saveHistory(List<AttendanceSummaryModel> items) {
    return _preferences.setString(
      AttendanceCacheKeys.history,
      jsonEncode(items.map((item) => item.toJson()).toList()),
    );
  }

  List<AttendanceSummaryModel> readHistory() {
    final raw = _preferences.getString(AttendanceCacheKeys.history);
    if (raw == null || raw.isEmpty) {
      return const [];
    }
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return const [];
    }
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(AttendanceSummaryModel.fromJson)
        .toList();
  }

  List<PendingAttendanceActionModel> readQueue() {
    final raw = _preferences.getString(AttendanceCacheKeys.pendingQueue);
    if (raw == null || raw.isEmpty) {
      return const [];
    }
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return const [];
    }
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(PendingAttendanceActionModel.fromJson)
        .toList();
  }

  Future<void> saveQueue(List<PendingAttendanceActionModel> queue) {
    return _preferences.setString(
      AttendanceCacheKeys.pendingQueue,
      jsonEncode(queue.map((item) => item.toJson()).toList()),
    );
  }

  Future<void> enqueue(PendingAttendanceActionModel action) async {
    final queue = readQueue();
    queue.add(action);
    await saveQueue(queue);
  }

  Future<void> removeFromQueue(String clientEventId) async {
    final queue = readQueue()
        .where((item) => item.clientEventId != clientEventId)
        .toList();
    await saveQueue(queue);
  }

  Future<void> updateQueueItem(PendingAttendanceActionModel updated) async {
    final queue = readQueue();
    final index = queue.indexWhere(
      (item) => item.clientEventId == updated.clientEventId,
    );
    if (index == -1) {
      return;
    }
    queue[index] = updated;
    await saveQueue(queue);
  }
}
