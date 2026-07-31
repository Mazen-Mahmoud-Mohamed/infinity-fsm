import 'package:equatable/equatable.dart';
import 'package:mobile/features/attendance/domain/entities/attendance_action_record.dart';
import 'package:mobile/features/attendance/domain/entities/attendance_status.dart';

class AttendanceRecord extends Equatable {
  const AttendanceRecord({
    required this.id,
    required this.date,
    required this.status,
    required this.breakCount,
    required this.breakMinutes,
    required this.workingMinutes,
    this.clockIn,
    this.clockOut,
  });

  final String id;
  final String date;
  final AttendanceStatus status;
  final AttendanceActionRecord? clockIn;
  final AttendanceActionRecord? clockOut;
  final int breakCount;
  final int breakMinutes;
  final int workingMinutes;

  @override
  List<Object?> get props => [
        id,
        date,
        status,
        clockIn,
        clockOut,
        breakCount,
        breakMinutes,
        workingMinutes,
      ];
}
