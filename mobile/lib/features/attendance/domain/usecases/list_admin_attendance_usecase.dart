import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/attendance/domain/entities/attendance_record_page.dart';
import 'package:mobile/features/attendance/domain/entities/attendance_status.dart';
import 'package:mobile/features/attendance/domain/repositories/attendance_repository.dart';

class ListAdminAttendanceUseCase {
  ListAdminAttendanceUseCase(this._repository);

  final AttendanceRepository _repository;

  Future<Result<AttendanceRecordPage>> call({
    int page = 1,
    int limit = 20,
    AttendanceStatus? status,
    String? search,
    DateTime? startDate,
    DateTime? endDate,
    String? userId,
    String? role,
  }) {
    return _repository.listAdmin(
      page: page,
      limit: limit,
      status: status,
      search: search,
      startDate: startDate,
      endDate: endDate,
      userId: userId,
      role: role,
    );
  }
}
