import 'package:mobile/features/attendance/data/models/attendance_event_model.dart';
import 'package:mobile/features/attendance/data/models/attendance_record_model.dart';
import 'package:mobile/features/attendance/data/models/break_session_model.dart';
import 'package:mobile/features/attendance/domain/entities/attendance_today.dart';

class AttendanceTodayModel extends AttendanceToday {
  const AttendanceTodayModel({
    super.attendance,
    super.events,
    super.breakSessions,
  });

  factory AttendanceTodayModel.fromJson(Map<String, dynamic> json) {
    final eventsJson = json['events'] as List<dynamic>? ?? [];
    final breaksJson = json['breakSessions'] as List<dynamic>? ?? [];

    return AttendanceTodayModel(
      attendance: json['attendance'] is Map<String, dynamic>
          ? AttendanceRecordModel.fromJson(
              json['attendance'] as Map<String, dynamic>,
            )
          : null,
      events: eventsJson
          .whereType<Map<String, dynamic>>()
          .map(AttendanceEventModel.fromJson)
          .toList(),
      breakSessions: breaksJson
          .whereType<Map<String, dynamic>>()
          .map(BreakSessionModel.fromJson)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'attendance': attendance is AttendanceRecordModel
          ? (attendance! as AttendanceRecordModel).toJson()
          : null,
      'events': events
          .whereType<AttendanceEventModel>()
          .map((event) => event.toJson())
          .toList(),
      'breakSessions': breakSessions
          .whereType<BreakSessionModel>()
          .map((session) => session.toJson())
          .toList(),
    };
  }
}
