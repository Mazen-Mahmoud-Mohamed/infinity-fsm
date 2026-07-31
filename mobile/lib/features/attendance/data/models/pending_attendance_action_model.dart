import 'dart:convert';
import 'dart:typed_data';

import 'package:mobile/features/attendance/data/mappers/attendance_json_helpers.dart';
import 'package:mobile/features/attendance/data/models/attendance_event_model.dart';
import 'package:mobile/features/attendance/data/models/gps_snapshot_model.dart';
import 'package:mobile/features/attendance/domain/entities/attendance_event.dart';
import 'package:mobile/features/attendance/domain/entities/pending_attendance_action.dart';

class PendingAttendanceActionModel extends PendingAttendanceAction {
  const PendingAttendanceActionModel({
    required super.clientEventId,
    required super.type,
    required super.gps,
    required super.deviceId,
    required super.clientRecordedAt,
    required super.createdAt,
    super.selfieBytes,
    super.retryCount,
    super.lastError,
  });

  factory PendingAttendanceActionModel.fromEntity(
    PendingAttendanceAction entity,
  ) {
    return PendingAttendanceActionModel(
      clientEventId: entity.clientEventId,
      type: entity.type,
      gps: entity.gps,
      selfieBytes: entity.selfieBytes,
      deviceId: entity.deviceId,
      clientRecordedAt: entity.clientRecordedAt,
      createdAt: entity.createdAt,
      retryCount: entity.retryCount,
      lastError: entity.lastError,
    );
  }

  factory PendingAttendanceActionModel.fromJson(Map<String, dynamic> json) {
    final selfieBase64 = optionalString(json, 'selfieBase64');

    return PendingAttendanceActionModel(
      clientEventId: requireString(json, 'clientEventId'),
      type: _typeFromApi(requireString(json, 'type')),
      gps: GpsSnapshotModel.fromJson(json['gps'] as Map<String, dynamic>),
      selfieBytes: selfieBase64 != null
          ? Uint8List.fromList(base64Decode(selfieBase64))
          : null,
      deviceId: requireString(json, 'deviceId'),
      clientRecordedAt: requireDateTime(json, 'clientRecordedAt'),
      createdAt: requireDateTime(json, 'createdAt'),
      retryCount: readInt(json, 'retryCount'),
      lastError: optionalString(json, 'lastError'),
    );
  }

  static AttendanceEventType _typeFromApi(String value) {
    switch (value) {
      case 'CLOCK_IN':
        return AttendanceEventType.clockIn;
      case 'CLOCK_OUT':
        return AttendanceEventType.clockOut;
      case 'BREAK_START':
        return AttendanceEventType.breakStart;
      case 'BREAK_END':
        return AttendanceEventType.breakEnd;
      default:
        throw FormatException('Unknown pending action type: $value');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'clientEventId': clientEventId,
      'type': attendanceEventTypeToApi(type),
      'gps': GpsSnapshotModel.fromEntity(gps).toJson(),
      'selfieBase64': selfieBytes != null ? base64Encode(selfieBytes!) : null,
      'deviceId': deviceId,
      'clientRecordedAt': clientRecordedAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'retryCount': retryCount,
      'lastError': lastError,
    };
  }
}
