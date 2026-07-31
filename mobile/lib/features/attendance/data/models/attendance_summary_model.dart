import 'package:mobile/features/attendance/data/mappers/attendance_json_helpers.dart';
import 'package:mobile/features/attendance/domain/entities/attendance_status.dart';
import 'package:mobile/features/attendance/domain/entities/attendance_summary.dart';

class AttendanceSummaryModel extends AttendanceSummaryEntity {
  const AttendanceSummaryModel({
    required super.id,
    required super.date,
    required super.status,
    required super.workingMinutes,
    required super.breakMinutes,
    required super.breakCount,
    super.clockInAt,
    super.clockOutAt,
  });

  factory AttendanceSummaryModel.fromJson(Map<String, dynamic> json) {
    return AttendanceSummaryModel(
      id: requireString(json, 'id'),
      date: requireString(json, 'date'),
      status: AttendanceStatus.fromApi(requireString(json, 'status')),
      clockInAt: parseDateTime(json['clockInAt']),
      clockOutAt: parseDateTime(json['clockOutAt']),
      workingMinutes: readInt(json, 'workingMinutes'),
      breakMinutes: readInt(json, 'breakMinutes'),
      breakCount: readInt(json, 'breakCount'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'status': status.apiValue,
      'clockInAt': clockInAt?.toIso8601String(),
      'clockOutAt': clockOutAt?.toIso8601String(),
      'workingMinutes': workingMinutes,
      'breakMinutes': breakMinutes,
      'breakCount': breakCount,
    };
  }
}
