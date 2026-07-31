import 'package:mobile/features/attendance/data/mappers/attendance_json_helpers.dart';
import 'package:mobile/features/attendance/data/models/gps_snapshot_model.dart';
import 'package:mobile/features/attendance/domain/entities/attendance_event.dart';

AttendanceEventType _typeFromApi(String value) {
  switch (value.toUpperCase()) {
    case 'CLOCK_IN':
      return AttendanceEventType.clockIn;
    case 'CLOCK_OUT':
      return AttendanceEventType.clockOut;
    case 'BREAK_START':
      return AttendanceEventType.breakStart;
    case 'BREAK_END':
      return AttendanceEventType.breakEnd;
    default:
      throw FormatException('Unknown attendance event type: $value');
  }
}

String attendanceEventTypeToApi(AttendanceEventType type) {
  switch (type) {
    case AttendanceEventType.clockIn:
      return 'CLOCK_IN';
    case AttendanceEventType.clockOut:
      return 'CLOCK_OUT';
    case AttendanceEventType.breakStart:
      return 'BREAK_START';
    case AttendanceEventType.breakEnd:
      return 'BREAK_END';
  }
}

class AttendanceEventModel extends AttendanceEventEntity {
  const AttendanceEventModel({
    required super.id,
    required super.type,
    required super.at,
    required super.gps,
    required super.deviceId,
    required super.source,
    super.selfieUrl,
  });

  factory AttendanceEventModel.fromJson(Map<String, dynamic> json) {
    return AttendanceEventModel(
      id: requireString(json, 'id'),
      type: _typeFromApi(requireString(json, 'type')),
      at: requireDateTime(json, 'at'),
      gps: GpsSnapshotModel.fromJson(json['gps'] as Map<String, dynamic>),
      selfieUrl: optionalString(json, 'selfieUrl'),
      deviceId: requireString(json, 'deviceId'),
      source: requireString(json, 'source'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': attendanceEventTypeToApi(type),
      'at': at.toIso8601String(),
      'gps': GpsSnapshotModel.fromEntity(gps).toJson(),
      'selfieUrl': selfieUrl,
      'deviceId': deviceId,
      'source': source,
    };
  }
}
