import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_session.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_status.dart';
import 'package:mobile/features/overtime/domain/repositories/overtime_repository.dart';

class ListMyOvertimeUseCase {
  ListMyOvertimeUseCase(this._repository);

  final OvertimeRepository _repository;

  Future<Result<OvertimeSessionPage>> call({
    int page = 1,
    int limit = 20,
    OvertimeStatus? status,
  }) {
    return _repository.listMySessions(
      page: page,
      limit: limit,
      status: status,
    );
  }
}
