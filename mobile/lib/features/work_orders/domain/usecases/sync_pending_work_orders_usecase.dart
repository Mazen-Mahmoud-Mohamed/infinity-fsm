import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/work_orders/domain/repositories/work_order_repository.dart';

class SyncPendingWorkOrdersUseCase {
  SyncPendingWorkOrdersUseCase(this._repository);

  final WorkOrderRepository _repository;

  Future<Result<int>> call() => _repository.syncPendingActions();
}
