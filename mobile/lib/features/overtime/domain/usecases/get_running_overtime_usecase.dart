import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_session.dart';
import 'package:mobile/features/overtime/domain/repositories/overtime_repository.dart';

class GetRunningOvertimeUseCase {
  const GetRunningOvertimeUseCase(this._repository);

  final OvertimeRepository _repository;

  Future<Result<OvertimeSession?>> call() => _repository.getRunningSession();
}
