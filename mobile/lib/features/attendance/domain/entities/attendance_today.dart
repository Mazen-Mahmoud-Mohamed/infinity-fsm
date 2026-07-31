import 'package:equatable/equatable.dart';
import 'package:mobile/features/attendance/domain/entities/attendance_event.dart';
import 'package:mobile/features/attendance/domain/entities/attendance_record.dart';
import 'package:mobile/features/attendance/domain/entities/break_session.dart';

class AttendanceToday extends Equatable {
  const AttendanceToday({
    this.attendance,
    this.events = const [],
    this.breakSessions = const [],
  });

  final AttendanceRecord? attendance;
  final List<AttendanceEventEntity> events;
  final List<BreakSessionEntity> breakSessions;

  @override
  List<Object?> get props => [attendance, events, breakSessions];
}
