import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_session.dart';
import 'package:mobile/features/overtime/domain/repositories/overtime_repository.dart';

class CancelOvertimeUseCase {
  const CancelOvertimeUseCase(this._repository);

  final OvertimeRepository _repository;

  Future<Result<OvertimeSession>> call({required String sessionId}) {
    return _repository.cancelSession(sessionId: sessionId);
  }
}
