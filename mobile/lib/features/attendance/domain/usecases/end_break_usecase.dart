import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/attendance/domain/entities/gps_snapshot.dart';
import 'package:mobile/features/attendance/domain/repositories/attendance_repository.dart';

class EndBreakUseCase {
  const EndBreakUseCase(this._repository);

  final AttendanceRepository _repository;

  Future<Result<AttendanceActionOutcome>> call({
    required GpsSnapshot gps,
    required String deviceId,
  }) {
    return _repository.breakEnd(gps: gps, deviceId: deviceId);
  }
}
