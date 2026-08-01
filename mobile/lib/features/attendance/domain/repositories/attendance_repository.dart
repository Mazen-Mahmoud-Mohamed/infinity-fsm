import 'package:equatable/equatable.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/attendance/domain/entities/attendance_admin_detail.dart';
import 'package:mobile/features/attendance/domain/entities/attendance_record_page.dart';
import 'package:mobile/features/attendance/domain/entities/attendance_status.dart';
import 'package:mobile/features/attendance/domain/entities/attendance_status_snapshot.dart';
import 'package:mobile/features/attendance/domain/entities/attendance_summary.dart';
import 'package:mobile/features/attendance/domain/entities/attendance_today.dart';
import 'package:mobile/features/attendance/domain/entities/gps_snapshot.dart';
import 'package:mobile/features/attendance/domain/entities/pending_attendance_action.dart';

class AttendanceActionOutcome extends Equatable {
  const AttendanceActionOutcome({
    required this.status,
    required this.queuedOffline,
  });

  final AttendanceStatusSnapshot status;
  final bool queuedOffline;

  @override
  List<Object?> get props => [status, queuedOffline];
}

abstract class AttendanceRepository {
  Future<Result<AttendanceStatusSnapshot>> getStatus({bool forceRefresh = false});

  Future<Result<AttendanceToday>> getToday({bool forceRefresh = false});

  Future<Result<List<AttendanceSummaryEntity>>> getHistory({
    int page = 1,
    int limit = 20,
    DateTime? startDate,
    DateTime? endDate,
    bool forceRefresh = false,
  });

  Future<Result<AttendanceRecordPage>> listAdmin({
    int page = 1,
    int limit = 20,
    AttendanceStatus? status,
    String? search,
    DateTime? startDate,
    DateTime? endDate,
    String? userId,
    String? role,
  });

  Future<Result<AttendanceAdminDetail>> getAdminDetail(String id);

  Future<Result<AttendanceActionOutcome>> clockIn({
    required GpsSnapshot gps,
    required List<int> selfieBytes,
    required String deviceId,
  });

  Future<Result<AttendanceActionOutcome>> clockOut({
    required GpsSnapshot gps,
    required List<int> selfieBytes,
    required String deviceId,
  });

  Future<Result<AttendanceActionOutcome>> breakStart({
    required GpsSnapshot gps,
    required String deviceId,
  });

  Future<Result<AttendanceActionOutcome>> breakEnd({
    required GpsSnapshot gps,
    required String deviceId,
  });

  Future<List<PendingAttendanceAction>> getPendingActions();

  Future<Result<void>> syncPendingActions();
}
