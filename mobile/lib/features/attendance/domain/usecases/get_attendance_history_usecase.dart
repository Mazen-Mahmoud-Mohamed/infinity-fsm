import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/attendance/domain/entities/attendance_summary.dart';
import 'package:mobile/features/attendance/domain/repositories/attendance_repository.dart';

class GetAttendanceHistoryUseCase {
  const GetAttendanceHistoryUseCase(this._repository);

  final AttendanceRepository _repository;

  Future<Result<List<AttendanceSummaryEntity>>> call({
    int page = 1,
    int limit = 20,
    DateTime? startDate,
    DateTime? endDate,
    bool forceRefresh = false,
  }) {
    return _repository.getHistory(
      page: page,
      limit: limit,
      startDate: startDate,
      endDate: endDate,
      forceRefresh: forceRefresh,
    );
  }
}
