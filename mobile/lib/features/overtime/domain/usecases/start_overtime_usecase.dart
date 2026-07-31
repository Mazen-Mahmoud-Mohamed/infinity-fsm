import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/attendance/domain/entities/gps_snapshot.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_session.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_type.dart';
import 'package:mobile/features/overtime/domain/repositories/overtime_repository.dart';

class StartOvertimeUseCase {
  const StartOvertimeUseCase(this._repository);

  final OvertimeRepository _repository;

  Future<Result<OvertimeSession>> call({
    required OvertimeType type,
    required GpsSnapshot gps,
    required List<int> photoBytes,
    required String deviceId,
    required String clientRequestId,
    required String? address,
  }) {
    return _repository.startSession(
      type: type,
      gps: gps,
      photoBytes: photoBytes,
      deviceId: deviceId,
      clientRequestId: clientRequestId,
      address: address,
    );
  }
}
