import 'package:mobile/features/attendance/data/mappers/attendance_json_helpers.dart';
import 'package:mobile/features/attendance/data/models/attendance_action_record_model.dart';
import 'package:mobile/features/attendance/domain/entities/attendance_employee.dart';
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
    super.userId,
    super.employee,
    super.createdAt,
    super.updatedAt,
  });

  factory AttendanceRecordModel.fromJson(Map<String, dynamic> json) {
    final employeeJson = json['employee'] as Map<String, dynamic>?;
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
      userId: optionalString(json, 'userId'),
      employee: employeeJson == null ? null : _mapEmployee(employeeJson),
      createdAt: parseDateTime(json['createdAt']),
      updatedAt: parseDateTime(json['updatedAt']),
    );
  }

  static AttendanceEmployee _mapEmployee(Map<String, dynamic> json) {
    final rolesRaw = json['roles'];
    return AttendanceEmployee(
      id: requireString(json, 'id'),
      firstName: optionalString(json, 'firstName'),
      lastName: optionalString(json, 'lastName'),
      fullName: optionalString(json, 'fullName'),
      email: optionalString(json, 'email'),
      roles: rolesRaw is List
          ? rolesRaw.map((item) => item.toString()).toList()
          : const [],
      avatarUrl: optionalString(json, 'avatarUrl'),
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
      'userId': userId,
      'employee': employee == null
          ? null
          : {
              'id': employee!.id,
              'firstName': employee!.firstName,
              'lastName': employee!.lastName,
              'fullName': employee!.fullName,
              'email': employee!.email,
              'roles': employee!.roles,
              'avatarUrl': employee!.avatarUrl,
            },
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
