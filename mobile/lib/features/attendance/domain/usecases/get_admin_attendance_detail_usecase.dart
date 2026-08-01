import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/attendance/domain/entities/attendance_admin_detail.dart';
import 'package:mobile/features/attendance/domain/repositories/attendance_repository.dart';

class GetAdminAttendanceDetailUseCase {
  GetAdminAttendanceDetailUseCase(this._repository);

  final AttendanceRepository _repository;

  Future<Result<AttendanceAdminDetail>> call(String id) {
    return _repository.getAdminDetail(id);
  }
}
