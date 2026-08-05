import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/attendance/domain/entities/gps_snapshot.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_session.dart';
import 'package:mobile/features/overtime/domain/repositories/overtime_repository.dart';

class EndOvertimeUseCase {
  const EndOvertimeUseCase(this._repository);

  final OvertimeRepository _repository;

  Future<Result<OvertimeSession>> call({
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
  }) {
    return _repository.endSession(
      sessionId: sessionId,
      gps: gps,
      photoBytes: photoBytes,
      voiceBytes: voiceBytes,
      voiceDurationSeconds: voiceDurationSeconds,
      deviceId: deviceId,
      address: address,
      clientRequestId: clientRequestId,
      notes: notes,
      batteryLevel: batteryLevel,
      networkStatus: networkStatus,
    );
  }
}
