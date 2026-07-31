import 'package:mobile/features/attendance/data/mappers/attendance_json_helpers.dart';
import 'package:mobile/features/attendance/data/models/attendance_action_record_model.dart';
import 'package:mobile/features/attendance/domain/entities/attendance_record.dart';
import 'package:mobile/features/attendance/domain/entities/attendance_status.dart';

class AttendanceRecordModel extends AttendanceRecord {
  const AttendanceRecordModel({
    required super.id,
    required super.date,
    required super.status,
    required super.breakCount,
    required super.breakMinutes,
    required super.workingMinutes,
    super.clockIn,
    super.clockOut,
  });

  factory AttendanceRecordModel.fromJson(Map<String, dynamic> json) {
    return AttendanceRecordModel(
      id: requireString(json, 'id'),
      date: requireString(json, 'date'),
      status: AttendanceStatus.fromApi(requireString(json, 'status')),
      clockIn: json['clockIn'] is Map<String, dynamic>
          ? AttendanceActionRecordModel.fromJson(
              json['clockIn'] as Map<String, dynamic>,
            )
          : null,
      clockOut: json['clockOut'] is Map<String, dynamic>
          ? AttendanceActionRecordModel.fromJson(
              json['clockOut'] as Map<String, dynamic>,
            )
          : null,
      breakCount: readInt(json, 'breakCount'),
      breakMinutes: readInt(json, 'breakMinutes'),
      workingMinutes: readInt(json, 'workingMinutes'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'status': status.apiValue,
      'clockIn': clockIn is AttendanceActionRecordModel
          ? (clockIn! as AttendanceActionRecordModel).toJson()
          : null,
      'clockOut': clockOut is AttendanceActionRecordModel
          ? (clockOut! as AttendanceActionRecordModel).toJson()
          : null,
      'breakCount': breakCount,
      'breakMinutes': breakMinutes,
      'workingMinutes': workingMinutes,
    };
  }
}
