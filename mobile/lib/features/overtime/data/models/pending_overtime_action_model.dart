import 'dart:convert';

import 'package:mobile/features/attendance/data/mappers/attendance_json_helpers.dart';
import 'package:mobile/features/attendance/data/models/gps_snapshot_model.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_type.dart';
import 'package:mobile/features/overtime/domain/entities/pending_overtime_action.dart';

class PendingOvertimeActionModel extends PendingOvertimeAction {
  const PendingOvertimeActionModel({
    required super.id,
    required super.type,
    required super.gps,
    required super.photoBytes,
    super.voiceBytes = const [],
    super.voiceDurationSeconds,
    required super.deviceId,
    required super.clientRequestId,
    required super.createdAt,
    super.overtimeType,
    super.isOvernight,
    super.sessionId,
    super.address,
    super.startedAt,
    super.endedAt,
    super.durationSeconds,
    super.checkpointAt,
    super.notes,
    super.batteryLevel,
    super.networkStatus,
    super.retryCount,
    super.lastError,
  });

  factory PendingOvertimeActionModel.fromEntity(PendingOvertimeAction entity) {
    return PendingOvertimeActionModel(
      id: entity.id,
      type: entity.type,
      overtimeType: entity.overtimeType,
      isOvernight: entity.isOvernight,
      sessionId: entity.sessionId,
      gps: entity.gps,
      photoBytes: entity.photoBytes,
      voiceBytes: entity.voiceBytes,
      voiceDurationSeconds: entity.voiceDurationSeconds,
      deviceId: entity.deviceId,
      clientRequestId: entity.clientRequestId,
      address: entity.address,
      startedAt: entity.startedAt,
      endedAt: entity.endedAt,
      durationSeconds: entity.durationSeconds,
      checkpointAt: entity.checkpointAt,
      notes: entity.notes,
      batteryLevel: entity.batteryLevel,
      networkStatus: entity.networkStatus,
      createdAt: entity.createdAt,
      retryCount: entity.retryCount,
      lastError: entity.lastError,
    );
  }

  static PendingOvertimeActionType _typeFromApi(String raw) {
    switch (raw.trim().toUpperCase()) {
      case 'END':
        return PendingOvertimeActionType.end;
      case 'ARRIVED_AT_WORK_SITE':
      case 'ARRIVEDATWORKSITE':
        return PendingOvertimeActionType.arrivedAtWorkSite;
      case 'FINISHED_WORK':
      case 'FINISHEDWORK':
        return PendingOvertimeActionType.finishedWork;
      default:
        return PendingOvertimeActionType.start;
    }
  }

  static String _typeToApi(PendingOvertimeActionType type) {
    switch (type) {
      case PendingOvertimeActionType.start:
        return 'START';
      case PendingOvertimeActionType.arrivedAtWorkSite:
        return 'ARRIVED_AT_WORK_SITE';
      case PendingOvertimeActionType.finishedWork:
        return 'FINISHED_WORK';
      case PendingOvertimeActionType.end:
        return 'END';
    }
  }

  factory PendingOvertimeActionModel.fromJson(Map<String, dynamic> json) {
    final photoBase64 = requireString(json, 'photoBase64');
    final voiceBase64 = optionalString(json, 'voiceBase64');
    final overtimeTypeRaw = optionalString(json, 'overtimeType');

    return PendingOvertimeActionModel(
      id: requireString(json, 'id'),
      type: _typeFromApi(requireString(json, 'type')),
      overtimeType: overtimeTypeRaw == null
          ? null
          : OvertimeType.fromApi(overtimeTypeRaw),
      isOvernight: json['isOvernight'] == true,
      sessionId: optionalString(json, 'sessionId'),
      gps: GpsSnapshotModel.fromJson(json['gps'] as Map<String, dynamic>),
      photoBytes: base64Decode(photoBase64),
      voiceBytes: voiceBase64 != null && voiceBase64.isNotEmpty
          ? base64Decode(voiceBase64)
          : const [],
      voiceDurationSeconds: readOptionalDouble(json, 'voiceDurationSeconds'),
      deviceId: requireString(json, 'deviceId'),
      clientRequestId: requireString(json, 'clientRequestId'),
      address: optionalString(json, 'address'),
      startedAt: parseDateTime(json['startedAt']),
      endedAt: parseDateTime(json['endedAt']),
      durationSeconds: _readNullableInt(json['durationSeconds']),
      checkpointAt: parseDateTime(json['checkpointAt']),
      notes: optionalString(json, 'notes'),
      batteryLevel: _readNullableInt(json['batteryLevel']),
      networkStatus: optionalString(json, 'networkStatus'),
      createdAt: requireDateTime(json, 'createdAt'),
      retryCount: readInt(json, 'retryCount'),
      lastError: optionalString(json, 'lastError'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': _typeToApi(type),
      'overtimeType': overtimeType?.apiValue,
      'isOvernight': isOvernight,
      'sessionId': sessionId,
      'gps': GpsSnapshotModel.fromEntity(gps).toJson(),
      'photoBase64': base64Encode(photoBytes),
      if (voiceBytes.isNotEmpty) 'voiceBase64': base64Encode(voiceBytes),
      if (voiceDurationSeconds != null)
        'voiceDurationSeconds': voiceDurationSeconds,
      'deviceId': deviceId,
      'clientRequestId': clientRequestId,
      'address': address,
      'startedAt': startedAt?.toIso8601String(),
      'endedAt': endedAt?.toIso8601String(),
      'durationSeconds': durationSeconds,
      'checkpointAt': checkpointAt?.toIso8601String(),
      'notes': notes,
      'batteryLevel': batteryLevel,
      'networkStatus': networkStatus,
      'createdAt': createdAt.toIso8601String(),
      'retryCount': retryCount,
      'lastError': lastError,
    };
  }

  static int? _readNullableInt(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value.toString());
  }
}
