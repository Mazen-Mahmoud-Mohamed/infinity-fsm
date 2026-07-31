import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/attendance/domain/entities/gps_snapshot.dart';
import 'package:mobile/features/attendance/domain/repositories/attendance_repository.dart';

class ClockInUseCase {
  const ClockInUseCase(this._repository);

  final AttendanceRepository _repository;

  Future<Result<AttendanceActionOutcome>> call({
    required GpsSnapshot gps,
    required List<int> selfieBytes,
    required String deviceId,
  }) {
    return _repository.clockIn(
      gps: gps,
      selfieBytes: selfieBytes,
      deviceId: deviceId,
    );
  }
}
