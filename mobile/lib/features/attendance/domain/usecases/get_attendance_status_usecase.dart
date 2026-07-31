import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/attendance/domain/entities/attendance_status_snapshot.dart';
import 'package:mobile/features/attendance/domain/repositories/attendance_repository.dart';

class GetAttendanceStatusUseCase {
  const GetAttendanceStatusUseCase(this._repository);

  final AttendanceRepository _repository;

  Future<Result<AttendanceStatusSnapshot>> call({bool forceRefresh = false}) {
    return _repository.getStatus(forceRefresh: forceRefresh);
  }
}
