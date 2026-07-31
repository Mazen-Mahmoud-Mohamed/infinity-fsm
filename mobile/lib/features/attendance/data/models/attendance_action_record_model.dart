import 'package:mobile/features/attendance/data/mappers/attendance_json_helpers.dart';
import 'package:mobile/features/attendance/data/models/gps_snapshot_model.dart';
import 'package:mobile/features/attendance/domain/entities/attendance_action_record.dart';

class AttendanceActionRecordModel extends AttendanceActionRecord {
  const AttendanceActionRecordModel({
    required super.at,
    required super.gps,
    required super.deviceId,
    required super.source,
    super.selfieUrl,
  });

  factory AttendanceActionRecordModel.fromJson(Map<String, dynamic> json) {
    return AttendanceActionRecordModel(
      at: requireDateTime(json, 'at'),
      gps: GpsSnapshotModel.fromJson(json['gps'] as Map<String, dynamic>),
      selfieUrl: optionalString(json, 'selfieUrl'),
      deviceId: requireString(json, 'deviceId'),
      source: requireString(json, 'source'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'at': at.toIso8601String(),
      'gps': GpsSnapshotModel.fromEntity(gps).toJson(),
      'selfieUrl': selfieUrl,
      'deviceId': deviceId,
      'source': source,
    };
  }
}
