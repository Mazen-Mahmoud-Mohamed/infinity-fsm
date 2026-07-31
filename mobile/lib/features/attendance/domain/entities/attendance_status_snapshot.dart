import 'package:equatable/equatable.dart';
import 'package:mobile/features/attendance/domain/entities/attendance_status.dart';

class AttendanceStatusSnapshot extends Equatable {
  const AttendanceStatusSnapshot({
    required this.status,
    required this.date,
    required this.workingMinutes,
    required this.breakMinutes,
    required this.breakCount,
    required this.liveWorkingSeconds,
    required this.serverTime,
    this.clockInAt,
    this.clockOutAt,
    this.activeBreakStartAt,
  });

  factory AttendanceStatusSnapshot.empty() {
    final now = DateTime.now();
    return AttendanceStatusSnapshot(
      status: AttendanceStatus.notStarted,
      date: now.toIso8601String().substring(0, 10),
      workingMinutes: 0,
      breakMinutes: 0,
      breakCount: 0,
      liveWorkingSeconds: 0,
      serverTime: now,
    );
  }

  final AttendanceStatus status;
  final String date;
  final DateTime? clockInAt;
  final DateTime? clockOutAt;
  final DateTime? activeBreakStartAt;
  final int workingMinutes;
  final int breakMinutes;
  final int breakCount;
  final int liveWorkingSeconds;
  final DateTime serverTime;

  AttendanceStatusSnapshot copyWith({int? liveWorkingSeconds}) {
    return AttendanceStatusSnapshot(
      status: status,
      date: date,
      workingMinutes: workingMinutes,
      breakMinutes: breakMinutes,
      breakCount: breakCount,
      liveWorkingSeconds: liveWorkingSeconds ?? this.liveWorkingSeconds,
      serverTime: serverTime,
      clockInAt: clockInAt,
      clockOutAt: clockOutAt,
      activeBreakStartAt: activeBreakStartAt,
    );
  }

  @override
  List<Object?> get props => [
        status,
        date,
        clockInAt,
        clockOutAt,
        activeBreakStartAt,
        workingMinutes,
        breakMinutes,
        breakCount,
        liveWorkingSeconds,
        serverTime,
      ];
}
