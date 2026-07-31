import 'package:equatable/equatable.dart';
import 'package:mobile/features/attendance/domain/entities/attendance_status_snapshot.dart';
import 'package:mobile/features/attendance/domain/entities/attendance_today.dart';

enum AttendanceLoadStatus { initial, loading, ready, actionInProgress, failure }

class AttendanceState extends Equatable {
  const AttendanceState({
    this.loadStatus = AttendanceLoadStatus.initial,
    this.status,
    this.today,
    this.isOffline = false,
    this.message,
    this.isError = false,
    this.isRefreshing = false,
  });

  final AttendanceLoadStatus loadStatus;
  final AttendanceStatusSnapshot? status;
  final AttendanceToday? today;
  final bool isOffline;
  final String? message;
  final bool isError;
  final bool isRefreshing;

  AttendanceState copyWith({
    AttendanceLoadStatus? loadStatus,
    AttendanceStatusSnapshot? status,
    AttendanceToday? today,
    bool? isOffline,
    String? message,
    bool isError = false,
    bool clearMessage = false,
    bool? isRefreshing,
  }) {
    return AttendanceState(
      loadStatus: loadStatus ?? this.loadStatus,
      status: status ?? this.status,
      today: today ?? this.today,
      isOffline: isOffline ?? this.isOffline,
      message: clearMessage ? null : message ?? this.message,
      isError: isError,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  List<Object?> get props => [
        loadStatus,
        status,
        today,
        isOffline,
        message,
        isError,
        isRefreshing,
      ];
}
