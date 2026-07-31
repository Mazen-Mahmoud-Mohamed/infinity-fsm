import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/overtime/domain/repositories/overtime_repository.dart';

class SyncPendingOvertimeUseCase {
  SyncPendingOvertimeUseCase(this._repository);

  final OvertimeRepository _repository;

  Future<Result<int>> call() => _repository.syncPendingActions();
}
