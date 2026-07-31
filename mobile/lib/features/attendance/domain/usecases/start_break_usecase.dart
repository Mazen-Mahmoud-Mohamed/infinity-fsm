import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/attendance/domain/entities/gps_snapshot.dart';
import 'package:mobile/features/attendance/domain/repositories/attendance_repository.dart';

class StartBreakUseCase {
  const StartBreakUseCase(this._repository);

  final AttendanceRepository _repository;

  Future<Result<AttendanceActionOutcome>> call({
    required GpsSnapshot gps,
    required String deviceId,
  }) {
    return _repository.breakStart(gps: gps, deviceId: deviceId);
  }
}
