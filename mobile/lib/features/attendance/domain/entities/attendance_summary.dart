import 'package:equatable/equatable.dart';
import 'package:mobile/features/attendance/domain/entities/attendance_status.dart';

class AttendanceSummaryEntity extends Equatable {
  const AttendanceSummaryEntity({
    required this.id,
    required this.date,
    required this.status,
    required this.workingMinutes,
    required this.breakMinutes,
    required this.breakCount,
    this.clockInAt,
    this.clockOutAt,
  });

  final String id;
  final String date;
  final AttendanceStatus status;
  final DateTime? clockInAt;
  final DateTime? clockOutAt;
  final int workingMinutes;
  final int breakMinutes;
  final int breakCount;

  @override
  List<Object?> get props => [
        id,
        date,
        status,
        clockInAt,
        clockOutAt,
        workingMinutes,
        breakMinutes,
        breakCount,
      ];
}
