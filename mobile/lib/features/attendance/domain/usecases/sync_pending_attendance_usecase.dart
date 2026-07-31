import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/attendance/domain/repositories/attendance_repository.dart';

class SyncPendingAttendanceUseCase {
  const SyncPendingAttendanceUseCase(this._repository);

  final AttendanceRepository _repository;

  Future<Result<void>> call() {
    return _repository.syncPendingActions();
  }
}
