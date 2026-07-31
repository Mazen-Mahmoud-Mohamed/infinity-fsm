import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_session.dart';
import 'package:mobile/features/overtime/domain/repositories/overtime_repository.dart';

class GetOvertimeByIdUseCase {
  GetOvertimeByIdUseCase(this._repository);

  final OvertimeRepository _repository;

  Future<Result<OvertimeSession>> call(String id) {
    return _repository.getSessionById(id);
  }
}
