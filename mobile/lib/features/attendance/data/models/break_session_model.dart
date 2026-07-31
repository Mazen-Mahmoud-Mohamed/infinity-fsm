import 'package:mobile/features/attendance/data/mappers/attendance_json_helpers.dart';
import 'package:mobile/features/attendance/domain/entities/break_session.dart';

class BreakSessionModel extends BreakSessionEntity {
  const BreakSessionModel({
    required super.id,
    required super.status,
    required super.startAt,
    required super.durationMinutes,
    super.endAt,
  });

  factory BreakSessionModel.fromJson(Map<String, dynamic> json) {
    return BreakSessionModel(
      id: requireString(json, 'id'),
      status: requireString(json, 'status').toUpperCase() == 'ACTIVE'
          ? BreakSessionStatus.active
          : BreakSessionStatus.completed,
      startAt: requireDateTime(json, 'startAt'),
      endAt: parseDateTime(json['endAt']),
      durationMinutes: readInt(json, 'durationMinutes'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status == BreakSessionStatus.active ? 'ACTIVE' : 'COMPLETED',
      'startAt': startAt.toIso8601String(),
      'endAt': endAt?.toIso8601String(),
      'durationMinutes': durationMinutes,
    };
  }
}
