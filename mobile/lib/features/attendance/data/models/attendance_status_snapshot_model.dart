import 'package:mobile/features/attendance/data/mappers/attendance_json_helpers.dart';
import 'package:mobile/features/attendance/domain/entities/attendance_status.dart';
import 'package:mobile/features/attendance/domain/entities/attendance_status_snapshot.dart';

class AttendanceStatusSnapshotModel extends AttendanceStatusSnapshot {
  const AttendanceStatusSnapshotModel({
    required super.status,
    required super.date,
    required super.workingMinutes,
    required super.breakMinutes,
    required super.breakCount,
    required super.liveWorkingSeconds,
    required super.serverTime,
    super.clockInAt,
    super.clockOutAt,
    super.activeBreakStartAt,
  });

  factory AttendanceStatusSnapshotModel.fromJson(Map<String, dynamic> json) {
    return AttendanceStatusSnapshotModel(
      status: AttendanceStatus.fromApi(requireString(json, 'status')),
      date: requireString(json, 'date'),
      clockInAt: parseDateTime(json['clockInAt']),
      clockOutAt: parseDateTime(json['clockOutAt']),
      activeBreakStartAt: parseDateTime(json['activeBreakStartAt']),
      workingMinutes: readInt(json, 'workingMinutes'),
      breakMinutes: readInt(json, 'breakMinutes'),
      breakCount: readInt(json, 'breakCount'),
      liveWorkingSeconds: readInt(json, 'liveWorkingSeconds'),
      serverTime: parseDateTime(json['serverTime']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status.apiValue,
      'date': date,
      'clockInAt': clockInAt?.toIso8601String(),
      'clockOutAt': clockOutAt?.toIso8601String(),
      'activeBreakStartAt': activeBreakStartAt?.toIso8601String(),
      'workingMinutes': workingMinutes,
      'breakMinutes': breakMinutes,
      'breakCount': breakCount,
      'liveWorkingSeconds': liveWorkingSeconds,
      'serverTime': serverTime.toIso8601String(),
    };
  }
}
