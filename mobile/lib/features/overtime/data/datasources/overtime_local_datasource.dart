import 'dart:convert';

import 'package:mobile/core/storage/preferences_service.dart';
import 'package:mobile/features/overtime/data/cache/overtime_cache_keys.dart';
import 'package:mobile/features/overtime/data/models/overtime_session_model.dart';
import 'package:mobile/features/overtime/data/models/pending_overtime_action_model.dart';
import 'package:mobile/features/overtime/data/trace/overtime_offline_trace.dart';
import 'package:mobile/features/overtime/domain/entities/pending_overtime_action.dart';

class OvertimeLocalDataSource {
  OvertimeLocalDataSource(this._preferences);

  final PreferencesService _preferences;

  PreferencesService get preferences => _preferences;

  Future<void> saveRunningSession(OvertimeSessionModel? session) async {
    OvertimeOfflineTrace.step(
      'WRITE_RUNNING',
      status: 'entered',
      objectId: session?.id,
      localId: session?.id.startsWith('local-') == true ? session?.id : null,
      serverId: session != null && !session.id.startsWith('local-')
          ? session.id
          : null,
    );
    if (session == null) {
      await _preferences.remove(OvertimeCacheKeys.runningSession);
      OvertimeOfflineTrace.step(
        'WRITE_RUNNING',
        status: 'success',
        detail: 'cleared',
      );
      return;
    }
    final payload = jsonEncode(session.toJson());
    final ok = await _preferences.setString(
      OvertimeCacheKeys.runningSession,
      payload,
    );
    if (!ok) {
      OvertimeOfflineTrace.step(
        'WRITE_RUNNING',
        status: 'failure',
        objectId: session.id,
        detail: 'setString returned false len=${payload.length}',
      );
      throw StateError('Failed to persist running overtime session');
    }
    final readBack = _preferences.getString(OvertimeCacheKeys.runningSession);
    OvertimeOfflineTrace.step(
      'WRITE_RUNNING',
      status: readBack == payload ? 'success' : 'failure',
      objectId: session.id,
      detail:
          'payloadLen=${payload.length} readBackLen=${readBack?.length ?? 0}',
    );
    if (readBack != payload) {
      throw StateError('Running session read-back mismatch after write');
    }
  }

  OvertimeSessionModel? readRunningSession() {
    final raw = _preferences.getString(OvertimeCacheKeys.runningSession);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        OvertimeOfflineTrace.step(
          'READ_RUNNING',
          status: 'failure',
          detail: 'not a map rawLen=${raw.length}',
        );
        return null;
      }
      return OvertimeSessionModel.fromJson(Map<String, dynamic>.from(decoded));
    } on Object catch (error) {
      OvertimeOfflineTrace.step(
        'READ_RUNNING',
        status: 'failure',
        detail: 'parse error: $error rawLen=${raw.length}',
      );
      return null;
    }
  }

  Future<void> saveHistory(List<OvertimeSessionModel> items) async {
    final ids = items.map((e) => e.id).join(',');
    OvertimeOfflineTrace.step(
      'WRITE_HISTORY',
      status: 'entered',
      pendingSessions: items.where((e) => e.id.startsWith('local-')).length,
      detail: 'count=${items.length} ids=$ids',
    );
    final payload = jsonEncode(items.map((item) => item.toJson()).toList());
    final ok = await _preferences.setString(OvertimeCacheKeys.history, payload);
    if (!ok) {
      OvertimeOfflineTrace.step(
        'WRITE_HISTORY',
        status: 'failure',
        detail: 'setString returned false len=${payload.length}',
      );
      throw StateError('Failed to persist overtime history');
    }
    final readBack = _preferences.getString(OvertimeCacheKeys.history);
    final parsed = readHistory();
    OvertimeOfflineTrace.step(
      'WRITE_HISTORY',
      status: parsed.length == items.length ? 'success' : 'failure',
      pendingSessions: parsed.where((e) => e.id.startsWith('local-')).length,
      detail:
          'payloadLen=${payload.length} readBackLen=${readBack?.length ?? 0} parsed=${parsed.length}',
    );
    if (parsed.length != items.length) {
      throw StateError(
        'History read-back mismatch: wrote ${items.length}, parsed ${parsed.length}',
      );
    }
  }

  List<OvertimeSessionModel> readHistory() {
    final raw = _preferences.getString(OvertimeCacheKeys.history);
    if (raw == null || raw.isEmpty) {
      return const [];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        OvertimeOfflineTrace.step(
          'READ_HISTORY',
          status: 'failure',
          detail: 'not a list rawLen=${raw.length}',
        );
        return const [];
      }
      final items = <OvertimeSessionModel>[];
      for (var i = 0; i < decoded.length; i++) {
        final entry = decoded[i];
        if (entry is! Map) {
          OvertimeOfflineTrace.step(
            'READ_HISTORY',
            status: 'failure',
            detail: 'entry[$i] not a map — skipped',
          );
          continue;
        }
        try {
          items.add(
            OvertimeSessionModel.fromJson(Map<String, dynamic>.from(entry)),
          );
        } on Object catch (error) {
          OvertimeOfflineTrace.step(
            'READ_HISTORY',
            status: 'failure',
            detail: 'entry[$i] parse error: $error',
          );
        }
      }
      return items;
    } on Object catch (error) {
      OvertimeOfflineTrace.step(
        'READ_HISTORY',
        status: 'failure',
        detail: 'parse error: $error rawLen=${raw.length}',
      );
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
        OvertimeOfflineTrace.step(
          'READ_QUEUE',
          status: 'failure',
          detail: 'not a list rawLen=${raw.length}',
        );
        return const [];
      }
      final items = <PendingOvertimeActionModel>[];
      for (var i = 0; i < decoded.length; i++) {
        final entry = decoded[i];
        if (entry is! Map) {
          OvertimeOfflineTrace.step(
            'READ_QUEUE',
            status: 'failure',
            detail: 'entry[$i] not a map — skipped',
          );
          continue;
        }
        try {
          items.add(_hydrateAction(Map<String, dynamic>.from(entry)));
        } on Object catch (error) {
          OvertimeOfflineTrace.step(
            'READ_QUEUE',
            status: 'failure',
            detail: 'entry[$i] parse/hydrate error: $error',
          );
        }
      }
      OvertimeOfflineTrace.step(
        'READ_QUEUE',
        status: 'success',
        queueLength: items.length,
        detail: 'rawLen=${raw.length}',
      );
      return items;
    } on Object catch (error) {
      OvertimeOfflineTrace.step(
        'READ_QUEUE',
        status: 'failure',
        detail: 'parse error: $error rawLen=${raw.length}',
      );
      return const [];
    }
  }

  Future<void> saveQueue(List<PendingOvertimeActionModel> queue) async {
    OvertimeOfflineTrace.step(
      'WRITE_QUEUE',
      status: 'entered',
      queueLength: queue.length,
    );
    for (final action in queue) {
      await _persistPhoto(action);
      await _persistVoice(action);
    }
    final slim = queue.map(_slimForQueueJson).toList();
    final payload = jsonEncode(slim.map((item) => item.toJson()).toList());
    final ok = await _preferences.setString(
      OvertimeCacheKeys.pendingQueue,
      payload,
    );
    if (!ok) {
      OvertimeOfflineTrace.step(
        'WRITE_QUEUE',
        status: 'failure',
        queueLength: queue.length,
        detail: 'setString returned false len=${payload.length}',
      );
      throw StateError('Failed to persist overtime pending queue');
    }
    final parsed = readQueue();
    OvertimeOfflineTrace.step(
      'WRITE_QUEUE',
      status: parsed.length == queue.length ? 'success' : 'failure',
      queueLength: parsed.length,
      detail: 'wrote=${queue.length} payloadLen=${payload.length}',
    );
    if (parsed.length != queue.length) {
      throw StateError(
        'Queue read-back mismatch: wrote ${queue.length}, parsed ${parsed.length}',
      );
    }
  }

  Future<void> enqueue(PendingOvertimeActionModel action) async {
    OvertimeOfflineTrace.step(
      'ENQUEUE',
      status: 'entered',
      objectId: action.id,
      localId: action.sessionId,
      detail: 'type=${action.type.name} photoBytes=${action.photoBytes.length}',
    );
    await _persistPhoto(action);
    await _persistVoice(action);
    final existing = readQueue();
    final queue = [
      ...existing.map(_slimForQueueJson),
      _slimForQueueJson(action),
    ];
    final payload = jsonEncode(queue.map((item) => item.toJson()).toList());
    final ok = await _preferences.setString(
      OvertimeCacheKeys.pendingQueue,
      payload,
    );
    if (!ok) {
      OvertimeOfflineTrace.step(
        'ENQUEUE',
        status: 'failure',
        objectId: action.id,
        queueLength: existing.length,
        detail: 'setString returned false len=${payload.length}',
      );
      throw StateError('Failed to enqueue overtime pending action');
    }
    final parsed = readQueue();
    final found = parsed.any((item) => item.id == action.id);
    final photoLen =
        _preferences
            .getString(OvertimeCacheKeys.pendingPhotoKey(action.id))
            ?.length ??
        0;
    OvertimeOfflineTrace.step(
      'ENQUEUE',
      status: found ? 'success' : 'failure',
      objectId: action.id,
      localId: action.sessionId,
      queueLength: parsed.length,
      detail:
          'photoKeyLen=$photoLen hydratedPhoto=${parsed.firstWhere((e) => e.id == action.id, orElse: () => action).photoBytes.length}',
    );
    if (!found) {
      throw StateError('Enqueue read-back missing action ${action.id}');
    }
  }

  Future<void> removeFromQueue(String id) async {
    OvertimeOfflineTrace.step(
      'QUEUE_REMOVE',
      status: 'entered',
      objectId: id,
      queueLength: readQueue().length,
    );
    final queue = readQueue().where((item) => item.id != id).toList();
    await _preferences.remove(OvertimeCacheKeys.pendingPhotoKey(id));
    await _preferences.remove(OvertimeCacheKeys.pendingVoiceKey(id));
    await saveQueue(queue);
    OvertimeOfflineTrace.step(
      'QUEUE_REMOVE',
      status: 'success',
      objectId: id,
      queueLength: queue.length,
    );
  }

  Future<void> updateQueueItem(PendingOvertimeActionModel action) async {
    final queue = readQueue()
        .map((item) => item.id == action.id ? action : item)
        .toList();
    await saveQueue(queue);
  }

  Future<void> rememberLocalIdMapping(String localId, String serverId) async {
    if (!localId.startsWith('local-') || serverId.isEmpty) {
      return;
    }
    final map = readLocalIdMap();
    map[localId] = serverId;
    final ok = await _preferences.setString(
      OvertimeCacheKeys.localIdMap,
      jsonEncode(map),
    );
    OvertimeOfflineTrace.step(
      'ID_MAP',
      status: ok ? 'success' : 'failure',
      localId: localId,
      serverId: serverId,
      detail: 'mapSize=${map.length}',
    );
    if (!ok) {
      throw StateError('Failed to persist overtime local id map');
    }
  }

  Map<String, String> readLocalIdMap() {
    final raw = _preferences.getString(OvertimeCacheKeys.localIdMap);
    if (raw == null || raw.isEmpty) {
      return <String, String>{};
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return <String, String>{};
      }
      return decoded.map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      );
    } on Object {
      return <String, String>{};
    }
  }

  Future<void> clearLocalIdMapping(String localId) async {
    final map = readLocalIdMap()..remove(localId);
    if (map.isEmpty) {
      await _preferences.remove(OvertimeCacheKeys.localIdMap);
      return;
    }
    await _preferences.setString(OvertimeCacheKeys.localIdMap, jsonEncode(map));
  }

  Future<void> remapQueueSessionIds(
    String fromLocalId,
    String toServerId,
  ) async {
    final queue = readQueue();
    var changed = false;
    final next = queue.map((item) {
      if (item.sessionId != fromLocalId) {
        return item;
      }
      changed = true;
      return PendingOvertimeActionModel.fromEntity(
        item.copyWith(sessionId: toServerId),
      );
    }).toList();
    OvertimeOfflineTrace.step(
      'REMAP_QUEUE_SESSION',
      status: changed ? 'success' : 'success',
      localId: fromLocalId,
      serverId: toServerId,
      queueLength: next.length,
      detail: changed ? 'remapped' : 'no matching sessionIds',
    );
    if (changed) {
      await saveQueue(next);
    }
  }

  bool hasPendingActionsForSession(String sessionId) {
    final mapped = readLocalIdMap();
    for (final action in readQueue()) {
      final actionSessionId = action.sessionId;
      if (actionSessionId == sessionId) {
        return true;
      }
      if (action.type == PendingOvertimeActionType.start &&
          'local-${action.clientRequestId}' == sessionId) {
        return true;
      }
      if (actionSessionId != null && mapped[actionSessionId] == sessionId) {
        return true;
      }
      if (mapped[sessionId] != null && mapped[sessionId] == actionSessionId) {
        return true;
      }
    }
    return false;
  }

  Map<String, Object?> dumpStorage() =>
      OvertimeOfflineTrace.dumpRaw(_preferences);

  PendingOvertimeActionModel _hydrateAction(Map<String, dynamic> json) {
    final model = PendingOvertimeActionModel.fromJson(json);

    var photoBytes = model.photoBytes;
    if (photoBytes.isEmpty) {
      final externalPhoto = _preferences.getString(
        OvertimeCacheKeys.pendingPhotoKey(model.id),
      );
      if (externalPhoto == null || externalPhoto.isEmpty) {
        OvertimeOfflineTrace.step(
          'HYDRATE_PHOTO',
          status: 'failure',
          objectId: model.id,
          detail: 'missing photo key and empty photoBase64',
        );
      } else {
        try {
          photoBytes = base64Decode(externalPhoto);
        } on Object catch (error) {
          OvertimeOfflineTrace.step(
            'HYDRATE_PHOTO',
            status: 'failure',
            objectId: model.id,
            detail: 'decode error: $error',
          );
        }
      }
    }

    var voiceBytes = model.voiceBytes;
    if (voiceBytes.isEmpty) {
      final externalVoice = _preferences.getString(
        OvertimeCacheKeys.pendingVoiceKey(model.id),
      );
      if (externalVoice != null && externalVoice.isNotEmpty) {
        try {
          voiceBytes = base64Decode(externalVoice);
        } on Object catch (error) {
          OvertimeOfflineTrace.step(
            'HYDRATE_VOICE',
            status: 'failure',
            objectId: model.id,
            detail: 'decode error: $error',
          );
        }
      }
    }

    if (photoBytes == model.photoBytes && voiceBytes == model.voiceBytes) {
      return model;
    }

    return PendingOvertimeActionModel(
      id: model.id,
      type: model.type,
      overtimeType: model.overtimeType,
      isOvernight: model.isOvernight,
      sessionId: model.sessionId,
      gps: model.gps,
      photoBytes: photoBytes,
      voiceBytes: voiceBytes,
      voiceDurationSeconds: model.voiceDurationSeconds,
      deviceId: model.deviceId,
      clientRequestId: model.clientRequestId,
      address: model.address,
      startedAt: model.startedAt,
      endedAt: model.endedAt,
      durationSeconds: model.durationSeconds,
      checkpointAt: model.checkpointAt,
      notes: model.notes,
      batteryLevel: model.batteryLevel,
      networkStatus: model.networkStatus,
      createdAt: model.createdAt,
      retryCount: model.retryCount,
      lastError: model.lastError,
    );
  }

  Future<void> _persistPhoto(PendingOvertimeActionModel action) async {
    if (action.photoBytes.isEmpty) {
      return;
    }
    final encoded = base64Encode(action.photoBytes);
    final ok = await _preferences.setString(
      OvertimeCacheKeys.pendingPhotoKey(action.id),
      encoded,
    );
    OvertimeOfflineTrace.step(
      'WRITE_PHOTO',
      status: ok ? 'success' : 'failure',
      objectId: action.id,
      detail: 'bytes=${action.photoBytes.length} b64Len=${encoded.length}',
    );
    if (!ok) {
      throw StateError('Failed to persist overtime pending photo');
    }
  }

  Future<void> _persistVoice(PendingOvertimeActionModel action) async {
    if (action.voiceBytes.isEmpty) {
      await _preferences.remove(OvertimeCacheKeys.pendingVoiceKey(action.id));
      return;
    }
    final encoded = base64Encode(action.voiceBytes);
    final ok = await _preferences.setString(
      OvertimeCacheKeys.pendingVoiceKey(action.id),
      encoded,
    );
    OvertimeOfflineTrace.step(
      'WRITE_VOICE',
      status: ok ? 'success' : 'failure',
      objectId: action.id,
      detail: 'bytes=${action.voiceBytes.length} b64Len=${encoded.length}',
    );
    if (!ok) {
      throw StateError('Failed to persist overtime pending voice');
    }
  }

  PendingOvertimeActionModel _slimForQueueJson(
    PendingOvertimeActionModel action,
  ) {
    return PendingOvertimeActionModel(
      id: action.id,
      type: action.type,
      overtimeType: action.overtimeType,
      isOvernight: action.isOvernight,
      sessionId: action.sessionId,
      gps: action.gps,
      photoBytes: const [],
      voiceBytes: const [],
      voiceDurationSeconds: action.voiceDurationSeconds,
      deviceId: action.deviceId,
      clientRequestId: action.clientRequestId,
      address: action.address,
      startedAt: action.startedAt,
      endedAt: action.endedAt,
      durationSeconds: action.durationSeconds,
      checkpointAt: action.checkpointAt,
      notes: action.notes,
      batteryLevel: action.batteryLevel,
      networkStatus: action.networkStatus,
      createdAt: action.createdAt,
      retryCount: action.retryCount,
      lastError: action.lastError,
    );
  }
}
