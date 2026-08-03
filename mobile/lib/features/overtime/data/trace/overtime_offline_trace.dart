import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:mobile/core/services/app_log_buffer.dart';
import 'package:mobile/core/services/logger_service.dart';
import 'package:mobile/core/storage/preferences_service.dart';
import 'package:mobile/features/overtime/data/cache/overtime_cache_keys.dart';

/// Forensic tracer for the offline overtime lifecycle.
///
/// Logs every step to [LoggerService] (Admin Logs → synchronization) and
/// [debugPrint] so device logs / `flutter test` output show the exact point
/// where local state disappears.
class OvertimeOfflineTrace {
  OvertimeOfflineTrace._();

  static LoggerService? _logger;

  static void bindLogger(LoggerService logger) {
    _logger = logger;
  }

  static void step(
    String phase, {
    required String status,
    String? objectId,
    String? localId,
    String? serverId,
    int? queueLength,
    int? pendingSessions,
    String? detail,
  }) {
    final buffer = StringBuffer('[OT-TRACE] $phase | $status');
    if (objectId != null) buffer.write(' | objectId=$objectId');
    if (localId != null) buffer.write(' | localId=$localId');
    if (serverId != null) buffer.write(' | serverId=$serverId');
    if (queueLength != null) buffer.write(' | queueLen=$queueLength');
    if (pendingSessions != null) {
      buffer.write(' | pendingSessions=$pendingSessions');
    }
    if (detail != null && detail.isNotEmpty) {
      buffer.write(' | $detail');
    }
    final line = buffer.toString();
    debugPrint(line);
    _logger?.info(line, null, null, AppLogCategory.synchronization);
  }

  /// Direct SharedPreferences dump — does not trust datasource parsers.
  static Map<String, Object?> dumpRaw(PreferencesService preferences) {
    final runningRaw =
        preferences.getString(OvertimeCacheKeys.runningSession);
    final historyRaw = preferences.getString(OvertimeCacheKeys.history);
    final queueRaw = preferences.getString(OvertimeCacheKeys.pendingQueue);
    final idMapRaw = preferences.getString(OvertimeCacheKeys.localIdMap);

    final historyIds = _idsFromList(historyRaw);
    final queueSummary = _queueSummary(queueRaw);
    final photoKeys = <String, int>{};
    // Scan known queue action ids + raw key presence via queue parse.
    for (final id in queueSummary.map((e) => e['id']?.toString() ?? '')) {
      if (id.isEmpty) continue;
      final photo = preferences.getString(OvertimeCacheKeys.pendingPhotoKey(id));
      photoKeys[id] = photo?.length ?? 0;
    }

    final dump = <String, Object?>{
      'runningRawLen': runningRaw?.length ?? 0,
      'runningId': _idFromObject(runningRaw),
      'historyRawLen': historyRaw?.length ?? 0,
      'historyCount': historyIds.length,
      'historyIds': historyIds,
      'queueRawLen': queueRaw?.length ?? 0,
      'queueCount': queueSummary.length,
      'queue': queueSummary,
      'photoKeys': photoKeys,
      'idMapRawLen': idMapRaw?.length ?? 0,
      'idMap': _decodeMap(idMapRaw),
    };

    step(
      'STORAGE_DUMP',
      status: 'snapshot',
      queueLength: queueSummary.length,
      pendingSessions: historyIds.where((id) => id.startsWith('local-')).length,
      detail: jsonEncode(dump),
    );
    return dump;
  }

  static String? _idFromObject(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map && decoded['id'] != null) {
        return decoded['id'].toString();
      }
    } on Object {
      return 'PARSE_ERROR(len=${raw.length})';
    }
    return null;
  }

  static List<String> _idsFromList(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const ['PARSE_ERROR_NOT_LIST'];
      return decoded
          .whereType<Map>()
          .map((e) => e['id']?.toString() ?? '?')
          .toList();
    } on Object {
      return ['PARSE_ERROR(len=${raw.length})'];
    }
  }

  static List<Map<String, Object?>> _queueSummary(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return [
          {'error': 'NOT_LIST'},
        ];
      }
      return decoded.whereType<Map>().map((e) {
        final photoB64 = e['photoBase64']?.toString() ?? '';
        return <String, Object?>{
          'id': e['id']?.toString(),
          'type': e['type']?.toString(),
          'sessionId': e['sessionId']?.toString(),
          'photoBase64Len': photoB64.length,
          'clientRequestId': e['clientRequestId']?.toString(),
        };
      }).toList();
    } on Object catch (error) {
      return [
        {'error': 'PARSE_ERROR', 'message': error.toString(), 'rawLen': raw.length},
      ];
    }
  }

  static Map<String, String> _decodeMap(String? raw) {
    if (raw == null || raw.isEmpty) return const {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const {};
      return decoded.map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      );
    } on Object {
      return const {'PARSE_ERROR': '1'};
    }
  }
}
