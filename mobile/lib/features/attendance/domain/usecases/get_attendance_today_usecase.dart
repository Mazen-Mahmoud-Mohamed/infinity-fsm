import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/attendance/domain/entities/attendance_today.dart';
import 'package:mobile/features/attendance/domain/repositories/attendance_repository.dart';

class GetAttendanceTodayUseCase {
  const GetAttendanceTodayUseCase(this._repository);

  final AttendanceRepository _repository;

  Future<Result<AttendanceToday>> call({bool forceRefresh = false}) {
    return _repository.getToday(forceRefresh: forceRefresh);
  }
}
