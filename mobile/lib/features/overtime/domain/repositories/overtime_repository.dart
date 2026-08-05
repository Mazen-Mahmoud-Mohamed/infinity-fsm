import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/attendance/domain/entities/gps_snapshot.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_checkpoint.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_session.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_status.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_type.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_export_filters.dart';
import 'package:mobile/features/overtime/domain/entities/pending_overtime_action.dart';

abstract class OvertimeRepository {
  Future<Result<OvertimeSession?>> getRunningSession();

  Future<Result<OvertimeSession>> startSession({
    required OvertimeType type,
    required GpsSnapshot gps,
    required List<int> photoBytes,
    List<int>? voiceBytes,
    double? voiceDurationSeconds,
    required String deviceId,
    required String clientRequestId,
    required String? address,
    String? notes,
    int? batteryLevel,
    String? networkStatus,
  });

  /// Mid-journey checkpoints (v2 only): arrivedAtWorkSite | finishedWork.
  Future<Result<OvertimeSession>> recordCheckpoint({
    required String sessionId,
    required OvertimeCheckpointStage stage,
    required GpsSnapshot gps,
    required List<int> photoBytes,
    List<int>? voiceBytes,
    double? voiceDurationSeconds,
    required String deviceId,
    required String? address,
    required String clientRequestId,
    String? notes,
    int? batteryLevel,
    String? networkStatus,
  });

  Future<Result<OvertimeSession>> endSession({
    required String sessionId,
    required GpsSnapshot gps,
    required List<int> photoBytes,
    List<int>? voiceBytes,
    double? voiceDurationSeconds,
    required String deviceId,
    required String? address,
    String? clientRequestId,
    String? notes,
    int? batteryLevel,
    String? networkStatus,
  });

  Future<Result<OvertimeSessionPage>> listAdminSessions({
    int page = 1,
    int limit = 20,
    OvertimeStatus? status,
    String? search,
  });

  Future<Result<OvertimeSessionPage>> listMySessions({
    int page = 1,
    int limit = 20,
    OvertimeStatus? status,
  });

  Future<Result<OvertimeSession>> getSessionById(String id);

  Future<Result<OvertimeSession>> approveSession(
    String id, {
    String? reviewNotes,
  });

  Future<Result<OvertimeSession>> rejectSession(
    String id, {
    String? rejectionReason,
    String? reviewNotes,
  });

  /// Admin/Supervisor Excel export (reporting only).
  Future<Result<OvertimeExcelExportResult>> exportExcel(
    OvertimeExportFilters filters,
  );

  Future<List<PendingOvertimeAction>> getPendingActions();

  Future<Result<int>> syncPendingActions();
}
